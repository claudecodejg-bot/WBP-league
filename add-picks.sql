-- =====================================================================
--  The picks book — weekly settle-up, with odds
--
--  REPLACES add-wagers.sql, which is deleted. If you ran that file, this
--  one drops what it made (nothing had been used: zero rows in all three
--  tables) and builds the simpler thing in its place.
--
--  WHAT CHANGED, AND WHY
--
--  The first version gave everyone a bankroll and escrowed money the
--  moment it was committed. That bought one thing — you couldn't offer the
--  same $20 on four courts at once — and cost a lot: a ledger, a balance
--  check on every write, a refund path for unmatched remainders, and a
--  stored number that could drift from the rows explaining it.
--
--  Nobody carries a season-long tab with their paddle partners. They
--  square up after the night. So there is no pool and no escrow: a pick is
--  a promise between two people, and after each Monday the site works out
--  who owes whom. Nothing is held, so nothing can get stuck.
--
--  That removes the only reason settlement had to be a write at all. The
--  result is already in `matches`; a court's winner is now DERIVED from it
--  (see v_court_results), so there is no settle button, nothing to forget
--  to press, and no second copy of the outcome to keep in step.
--
--  ODDS
--
--  An offer names two numbers: what the poster risks, and what the poster
--  wins. "I'll risk $5 to win $10" is 2-1. The taker's position is the
--  exact mirror — risks $10 to win $5 — so there is no third number and no
--  ratio to parse, and the two ends can never disagree about the price.
--
--  Money is in INTEGER CENTS. At 2-1 on $5 a half fill is $2.50, and
--  anything that can produce a half dollar should not be stored in whole
--  ones.
--
--  WHY EVERY WRITE IS STILL A FUNCTION
--
--  "Only if the offer has enough left, and it is before the court closes,
--  and you are not betting against your own team" needs a row lock and two
--  tables in one transaction, which no RLS policy can express. So the
--  tables take no writes from the browser at all — insert/update/delete
--  are revoked from anon AND authenticated (Supabase grants functions to
--  anon by default, so `revoke ... from public` alone misses it) — and
--  these SECURITY DEFINER functions are the only way in.
--
--  Play money. Nothing here settles in cash.
--
--  Depends on add-scheduled-courts.sql. Run in the Supabase SQL editor.
--  Safe to re-run.
-- =====================================================================

-- ---------------------------------------------------------------------
--  0. Clear out the bankroll version
-- ---------------------------------------------------------------------
--  Inside the transaction with everything it replaces, so a failure
--  anywhere below leaves the old version standing rather than nothing.

begin;

drop view     if exists public.v_wager_balances;
drop function if exists public.settle_court(uuid, smallint);
drop function if exists public.grant_season_bankroll(text, int);
drop function if exists public.wager_balance(uuid, text);
drop function if exists public.post_offer(uuid, smallint, int);
drop function if exists public.take_offer(uuid, int);
drop function if exists public.cancel_offer(uuid);
drop table    if exists public.wager_fills;
drop table    if exists public.wager_offers;
drop table    if exists public.wager_ledger;

-- ---------------------------------------------------------------------
--  1. A voided court has to keep its slot
-- ---------------------------------------------------------------------
--  Regenerating a night used to delete its courts. Now a court somebody
--  has bet on is voided instead of deleted, so the picks keep pointing at
--  the pairing they were actually made on. Voided rows stay, which means
--  (played_on, court_no) can repeat — once, legitimately, per regeneration.
--  So the uniqueness only applies to courts that still count.

alter table public.scheduled_courts
  drop constraint if exists scheduled_courts_played_on_court_no_key;

drop index if exists public.scheduled_courts_live_court_idx;
create unique index scheduled_courts_live_court_idx
  on public.scheduled_courts (played_on, court_no)
  where status <> 'void';

-- ---------------------------------------------------------------------
--  2. The book
-- ---------------------------------------------------------------------

create table public.wager_offers (
  id          uuid        primary key default gen_random_uuid(),
  court_id    uuid        not null references public.scheduled_courts(id) on delete cascade,
  season      text        not null,
  offered_by  uuid        not null references public.members(id),
  side        smallint    not null check (side in (1, 2)),

  -- The price, from the poster's end. Even money is risk = win.
  risk_cents  int         not null check (risk_cents between 100 and 10000),
  win_cents   int         not null check (win_cents  between 100 and 50000),

  -- What is still unmatched, on both ends. Two counters rather than one
  -- plus a ratio: a partial fill at 2-1 has to come off both sides at
  -- once, and recomputing the second from the first reintroduces the
  -- rounding error on every read.
  risk_open_cents int     not null check (risk_open_cents >= 0),
  win_open_cents  int     not null check (win_open_cents  >= 0),

  status      text        not null default 'open'
                check (status in ('open', 'filled', 'cancelled', 'void')),
  created_at  timestamptz not null default now(),

  constraint wager_offers_open_sane check (
    risk_open_cents <= risk_cents and win_open_cents <= win_cents
  ),
  -- 10-1 either way is already a silly price for a paddle match, and the
  -- cap keeps a partial fill's rounding above a cent (see take_offer).
  constraint wager_offers_odds_sane check (
    win_cents <= risk_cents * 10 and risk_cents <= win_cents * 10
  )
);

create index wager_offers_court_idx  on public.wager_offers (court_id);
create index wager_offers_season_idx on public.wager_offers (season, offered_by);

comment on table public.wager_offers is
  'A side put up at a price. risk_cents/win_cents is the poster''s end; the taker''s is the mirror. *_open_cents is what nobody has taken yet.';

create table public.wager_fills (
  id       uuid primary key default gen_random_uuid(),
  offer_id uuid not null references public.wager_offers(id) on delete cascade,
  taker    uuid not null references public.members(id),

  -- One matched bet, both ends written down. Stored rather than derived so
  -- a settled pick can never be re-priced by a later edit to the offer,
  -- and so settlement needs no arithmetic at all.
  poster_risk_cents int not null check (poster_risk_cents > 0),
  taker_risk_cents  int not null check (taker_risk_cents  > 0),

  created_at timestamptz not null default now()
);

create index wager_fills_offer_idx on public.wager_fills (offer_id);
create index wager_fills_taker_idx on public.wager_fills (taker);

comment on table public.wager_fills is
  'A matched bet. The taker is on the side opposite the offer. No outcome column: the winner is derived from matches via v_court_results.';

-- ---------------------------------------------------------------------
--  3. Readable by all, writable by none
-- ---------------------------------------------------------------------
--  The site is public to read by design and the book is part of the fun.
--  Writes are another matter.

alter table public.wager_offers enable row level security;
alter table public.wager_fills  enable row level security;

create policy "Public can read offers" on public.wager_offers for select using (true);
create policy "Public can read fills"  on public.wager_fills  for select using (true);

commit;

revoke insert, update, delete on public.wager_offers from anon, authenticated;
revoke insert, update, delete on public.wager_fills  from anon, authenticated;
grant  select on public.wager_offers to anon, authenticated;
grant  select on public.wager_fills  to anon, authenticated;

-- ---------------------------------------------------------------------
--  4. Who won a court — derived, never stored
-- ---------------------------------------------------------------------
--  A scheduled court and a recorded match are linked by their players, not
--  by court number or by which team the scheduler happened to call team1.
--  Court 2 is just an index into an array; a regenerated night renumbers
--  it silently. The four people who played are the one thing both rows
--  agree on.
--
--  A court with a substitution therefore matches nothing and stays
--  unresolved rather than being settled against a pairing nobody bet on.
--  The settle-up page lists those so they can be voided by hand — the one
--  case that genuinely needs a human to look at it.

create or replace function public.pair_key(a uuid, b uuid)
returns uuid[]
language sql
immutable
as $$
  select case when a < b then array[a, b] else array[b, a] end;
$$;

comment on function public.pair_key(uuid, uuid) is
  'An unordered pair as a comparable value, so a court side and a match team can be matched regardless of which player was written first.';

create or replace view public.v_court_results
  with (security_invoker = true) as
  select c.id            as court_id,
         c.season,
         c.played_on,
         c.week_label,
         c.court_no,
         c.status,
         r.winning_side
    from public.scheduled_courts c
    left join lateral (
      select case
               -- Sides line up with the match as written.
               when public.pair_key(c.t1p1, c.t1p2)
                  = public.pair_key(m.team1_player1, m.team1_player2)
                 then case when m.t1_sets >= 2 then 1::smallint else 2::smallint end
               -- The scheduler's side 1 is the match's team2.
               else case when m.t1_sets >= 2 then 2::smallint else 1::smallint end
             end as winning_side
        from (
          select mm.*,
                 (case when mm.team1_set1 > mm.team2_set1 then 1 else 0 end +
                  case when mm.team1_set2 > mm.team2_set2 then 1 else 0 end +
                  case when coalesce(mm.team1_set3, -1) > coalesce(mm.team2_set3, -1)
                       then 1 else 0 end) as t1_sets,
                 (case when mm.team2_set1 > mm.team1_set1 then 1 else 0 end +
                  case when mm.team2_set2 > mm.team1_set2 then 1 else 0 end +
                  case when coalesce(mm.team2_set3, -1) > coalesce(mm.team1_set3, -1)
                       then 1 else 0 end) as t2_sets
            from public.matches mm
        ) m
       where m.played_on = c.played_on
         -- Same four people, same two partnerships, either way round.
         and (
           (public.pair_key(c.t1p1, c.t1p2) = public.pair_key(m.team1_player1, m.team1_player2)
            and public.pair_key(c.t2p1, c.t2p2) = public.pair_key(m.team2_player1, m.team2_player2))
           or
           (public.pair_key(c.t1p1, c.t1p2) = public.pair_key(m.team2_player1, m.team2_player2)
            and public.pair_key(c.t2p1, c.t2p2) = public.pair_key(m.team1_player1, m.team1_player2))
         )
         -- Exactly one side took two sets. A part-entered or abandoned
         -- match has no winner, so the court stays unresolved.
         and (m.t1_sets >= 2) <> (m.t2_sets >= 2)
       limit 1
    ) r on true;

comment on view public.v_court_results is
  'Each scheduled court with the winning side (1 or 2) once a matching result exists, else null. Matched on players, not court order.';

grant select on public.v_court_results to anon, authenticated;

-- ---------------------------------------------------------------------
--  5. Every matched pick, with who owes whom
-- ---------------------------------------------------------------------
--  The poster wins what they said they'd win, which is exactly the taker's
--  risk. The poster loses what they said they'd risk. One subtraction, no
--  ratio, because both numbers were written down when the bet was struck.

create or replace view public.v_pick_results
  with (security_invoker = true) as
  select f.id                as fill_id,
         o.id                as offer_id,
         cr.court_id,
         cr.season,
         cr.played_on,
         cr.week_label,
         cr.court_no,
         o.offered_by        as poster,
         f.taker,
         o.side              as poster_side,
         f.poster_risk_cents,
         f.taker_risk_cents,
         cr.winning_side,
         case when cr.winning_side is null then null
              when cr.winning_side = o.side then o.offered_by
              else f.taker end  as winner,
         case when cr.winning_side is null then null
              when cr.winning_side = o.side then f.taker
              else o.offered_by end as loser,
         case when cr.winning_side is null then null
              -- Poster's side came in: they collect their stated winnings,
              -- which is what the taker put at risk.
              when cr.winning_side = o.side then f.taker_risk_cents
              else f.poster_risk_cents end as amount_cents
    from public.wager_fills f
    join public.wager_offers o  on o.id = f.offer_id
    join public.v_court_results cr on cr.court_id = o.court_id
   where cr.status <> 'void'
     and o.status  <> 'void';

comment on view public.v_pick_results is
  'One row per matched pick. winner/loser/amount_cents are null until the court has a result; a voided court drops out entirely.';

grant select on public.v_pick_results to anon, authenticated;

-- ---------------------------------------------------------------------
--  6. The settle-up — pairwise, per night
-- ---------------------------------------------------------------------
--  Deliberately NOT the minimal set of transfers. Debt simplification
--  produces fewer payments and confusing ones: "why am I paying Dolan when
--  I bet against Ridder?" Everyone can check a pairwise number against the
--  picks they remember making, which matters more here than saving a
--  Venmo.

create or replace view public.v_settle_week
  with (security_invoker = true) as
  with pairs as (
    select played_on,
           season,
           least(winner, loser)    as a,
           greatest(winner, loser) as b,
           case when winner = least(winner, loser)
                then amount_cents else -amount_cents end as a_net
      from public.v_pick_results
     where winner is not null
  )
  select p.played_on,
         p.season,
         p.a,
         p.b,
         ma.full_name as a_name,
         mb.full_name as b_name,
         sum(p.a_net)::int as a_net_cents
    from pairs p
    join public.members ma on ma.id = p.a
    join public.members mb on mb.id = p.b
   group by p.played_on, p.season, p.a, p.b, ma.full_name, mb.full_name
  having sum(p.a_net) <> 0;

comment on view public.v_settle_week is
  'Who owes whom for one night. a_net_cents positive means b pays a; negative means a pays b. Pairs that came out level are dropped.';

grant select on public.v_settle_week to anon, authenticated;

-- Each member's result for a night, for the "you were up $14" line.
create or replace view public.v_settle_week_member
  with (security_invoker = true) as
  select played_on, season, member_id, sum(delta)::int as net_cents
    from (
      select played_on, season, winner as member_id,  amount_cents as delta
        from public.v_pick_results where winner is not null
      union all
      select played_on, season, loser  as member_id, -amount_cents as delta
        from public.v_pick_results where loser  is not null
    ) x
   group by played_on, season, member_id;

grant select on public.v_settle_week_member to anon, authenticated;

-- The week resets, but the site remembers. Same rows, summed differently.
create or replace view public.v_settle_season
  with (security_invoker = true) as
  select season,
         member_id,
         sum(net_cents)::int as net_cents,
         count(distinct played_on)::int as nights
    from public.v_settle_week_member
   group by season, member_id;

comment on view public.v_settle_season is
  'Cumulative play-money record for the season. Settling weekly squares the debt; it does not erase the scoreboard.';

grant select on public.v_settle_season to anon, authenticated;

-- ---------------------------------------------------------------------
--  7. Who is calling
-- ---------------------------------------------------------------------
--  SECURITY DEFINER because anon has no column grant on members.auth_id.

create or replace function public.wager_me()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.members where auth_id = auth.uid() limit 1;
$$;

revoke all     on function public.wager_me() from public, anon;
grant  execute on function public.wager_me() to   authenticated;

-- ---------------------------------------------------------------------
--  8. post_offer — put a side up at a price
-- ---------------------------------------------------------------------

create or replace function public.post_offer(
  p_court_id   uuid,
  p_side       smallint,
  p_risk_cents int,
  p_win_cents  int
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me       uuid;
  v_court    record;
  v_my_side  smallint;
  v_offer_id uuid;
begin
  v_me := public.wager_me();
  if v_me is null then
    raise exception 'You need to be signed in as a league member to make a pick';
  end if;
  if p_side is null or p_side not in (1, 2) then
    raise exception 'Pick side 1 or side 2';
  end if;
  if p_risk_cents is null or p_risk_cents < 100 or p_risk_cents > 10000 then
    raise exception 'Risk has to be between $1 and $100';
  end if;
  if p_win_cents is null or p_win_cents < 100 or p_win_cents > 50000 then
    raise exception 'The amount to win has to be between $1 and $500';
  end if;
  if p_win_cents > p_risk_cents * 10 or p_risk_cents > p_win_cents * 10 then
    raise exception 'Keep the odds inside 10-1 either way';
  end if;

  select * into v_court from public.scheduled_courts where id = p_court_id;
  if v_court.id is null then
    raise exception 'No such court';
  end if;
  if v_court.status <> 'open' then
    raise exception 'That court is closed for picks';
  end if;
  -- Wall clock, not "has the result been entered yet". Results land hours
  -- after play — last week's three courts were stamped at 01:48am — so
  -- anyone who played would otherwise be betting on a known result.
  if now() >= v_court.closes_at then
    raise exception 'Picks for that court closed at %', v_court.closes_at;
  end if;

  v_my_side := case
    when v_me in (v_court.t1p1, v_court.t1p2) then 1::smallint
    when v_me in (v_court.t2p1, v_court.t2p2) then 2::smallint
    else null
  end;

  -- Backing yourself is the most natural pick in the league. Backing the
  -- other side of your own court is the one thing that pays you to lose.
  if v_my_side is not null and v_my_side <> p_side then
    raise exception 'You are playing this court — you can back your own team, but not against it';
  end if;

  insert into public.wager_offers (
    court_id, season, offered_by, side,
    risk_cents, win_cents, risk_open_cents, win_open_cents
  ) values (
    p_court_id, v_court.season, v_me, p_side,
    p_risk_cents, p_win_cents, p_risk_cents, p_win_cents
  )
  returning id into v_offer_id;

  return v_offer_id;
end;
$$;

-- ---------------------------------------------------------------------
--  9. take_offer — take the other side, all of it or part
-- ---------------------------------------------------------------------
--  The important line in this file is the FOR UPDATE below. Without it,
--  two people tapping "take it" in the same second both read the same
--  remaining amount, both write a fill, and the offer is matched for more
--  than it was ever worth.
--
--  The taker says what THEY want to risk, because that is the number they
--  are exposed to and the only one they care about. What that covers of the
--  poster's risk is worked out here, pro rata.
--
--  Partial fills and rounding: a fill that would leave less than a dollar
--  unmatched takes the lot instead, and a fill that empties either counter
--  empties both. So the two ends can never drift apart by more than the
--  cent of rounding on a genuinely partial fill, and an offer never sits
--  there with 3 cents open that nobody can take.

create or replace function public.take_offer(
  p_offer_id   uuid,
  p_risk_cents int                 -- what the TAKER wants to risk
)
returns jsonb                      -- {taker_risk_cents, poster_risk_cents}
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me       uuid;
  v_offer    record;
  v_court    record;
  v_my_side  smallint;
  v_take     int;
  v_cover    int;
  v_taken    int;      -- taker-side cents matched after this fill
  v_covered  int;      -- poster-side cents matched before it
begin
  v_me := public.wager_me();
  if v_me is null then
    raise exception 'You need to be signed in as a league member to make a pick';
  end if;
  if p_risk_cents is null or p_risk_cents < 100 then
    raise exception 'Take at least $1 of it';
  end if;

  select * into v_offer from public.wager_offers where id = p_offer_id for update;
  if v_offer.id is null then
    raise exception 'No such offer';
  end if;
  if v_offer.status <> 'open' or v_offer.win_open_cents <= 0 then
    raise exception 'That offer is no longer open';
  end if;
  if v_offer.offered_by = v_me then
    raise exception 'That is your own offer';
  end if;

  select * into v_court from public.scheduled_courts where id = v_offer.court_id;
  if v_court.status <> 'open' then
    raise exception 'That court is closed for picks';
  end if;
  if now() >= v_court.closes_at then
    raise exception 'Picks for that court closed at %', v_court.closes_at;
  end if;

  -- Taking an offer means taking the side it is against.
  v_my_side := case
    when v_me in (v_court.t1p1, v_court.t1p2) then 1::smallint
    when v_me in (v_court.t2p1, v_court.t2p2) then 2::smallint
    else null
  end;

  if v_my_side is not null and v_my_side <> (3 - v_offer.side)::smallint then
    raise exception 'That would be a pick against your own team';
  end if;

  v_take := least(p_risk_cents, v_offer.win_open_cents);

  -- Don't leave a sliver nobody can take.
  if v_offer.win_open_cents - v_take < 100 then
    v_take := v_offer.win_open_cents;
  end if;

  if v_take >= v_offer.win_open_cents then
    -- Taking the rest of it: both counters go to zero together.
    v_take  := v_offer.win_open_cents;
    v_cover := v_offer.risk_open_cents;
  else
    -- Price this fill off the CUMULATIVE position rather than off the fill
    -- in isolation. Rounding each fill on its own lets the error pile up,
    -- and the last taker then silently absorbs the whole pile — on a $1-to-
    -- win-$7 offer taken a dollar at a time, several cents of it. Measuring
    -- from the start instead keeps every fill within a cent of the offer's
    -- price and makes the final one land on risk_cents exactly.
    v_taken   := (v_offer.win_cents - v_offer.win_open_cents) + v_take;
    v_covered := v_offer.risk_cents - v_offer.risk_open_cents;
    v_cover   := round(v_taken::numeric * v_offer.risk_cents / v_offer.win_cents)::int
                 - v_covered;
    -- Belt and braces. With odds capped at 10-1 and a $1 minimum take this
    -- cannot bite: a dollar of taker risk moves the poster side by at least
    -- 9 cents.
    v_cover := least(greatest(v_cover, 1), v_offer.risk_open_cents);
  end if;

  if v_take <= 0 or v_cover <= 0 then
    raise exception 'Nothing left to take on that offer';
  end if;

  insert into public.wager_fills (offer_id, taker, poster_risk_cents, taker_risk_cents)
  values (p_offer_id, v_me, v_cover, v_take);

  update public.wager_offers
     set risk_open_cents = risk_open_cents - v_cover,
         win_open_cents  = win_open_cents  - v_take,
         status = case when risk_open_cents - v_cover <= 0
                         or win_open_cents - v_take <= 0
                       then 'filled' else 'open' end
   where id = p_offer_id;

  return jsonb_build_object('taker_risk_cents', v_take,
                            'poster_risk_cents', v_cover);
end;
$$;

-- ---------------------------------------------------------------------
--  10. cancel_offer — pull back what nobody has taken
-- ---------------------------------------------------------------------
--  Only the unmatched part. Anything already matched is a bet somebody
--  else is holding, and stays live.

create or replace function public.cancel_offer(p_offer_id uuid)
returns int                        -- the taker-side amount withdrawn, in cents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me    uuid;
  v_offer record;
  v_back  int;
begin
  v_me := public.wager_me();
  if v_me is null then
    raise exception 'You need to be signed in';
  end if;

  select * into v_offer from public.wager_offers where id = p_offer_id for update;
  if v_offer.id is null then
    raise exception 'No such offer';
  end if;
  if v_offer.offered_by <> v_me and not public.auth_is_admin() then
    raise exception 'That is not your offer';
  end if;
  if v_offer.status <> 'open' then
    raise exception 'Nothing to pull back on that offer';
  end if;

  v_back := v_offer.win_open_cents;

  update public.wager_offers
     set risk_open_cents = 0,
         win_open_cents  = 0,
         status = case when exists (select 1 from public.wager_fills
                                     where offer_id = p_offer_id)
                       then 'filled' else 'cancelled' end
   where id = p_offer_id;

  return v_back;
end;
$$;

-- ---------------------------------------------------------------------
--  11. void_court — strike a court off the book
-- ---------------------------------------------------------------------
--  For a court that did not happen, got reshuffled, or whose result cannot
--  be pinned to the pairing anyone bet on — a substitution, most often.
--  Nothing is held, so voiding is just a label: the picks drop out of
--  v_pick_results and nobody owes anybody.

create or replace function public.void_court(p_court_id uuid)
returns int                        -- matched picks struck off
language plpgsql
security definer
set search_path = public
as $$
declare
  v_court record;
  v_n     int;
begin
  if not public.auth_is_admin() then
    raise exception 'Only an admin can void a court';
  end if;

  select * into v_court from public.scheduled_courts where id = p_court_id for update;
  if v_court.id is null then
    raise exception 'No such court';
  end if;

  select count(*)::int into v_n
    from public.wager_fills f
    join public.wager_offers o on o.id = f.offer_id
   where o.court_id = p_court_id;

  update public.wager_offers set status = 'void' where court_id = p_court_id;
  update public.scheduled_courts set status = 'void' where id = p_court_id;

  return v_n;
end;
$$;

-- ---------------------------------------------------------------------
--  12. Regenerating a schedule has to let go of picks on the old one
-- ---------------------------------------------------------------------
--  Replaces the version in add-scheduled-courts.sql. A court nobody bet on
--  is deleted as before. A court somebody bet on is voided and left in
--  place, so the picks still point at the pairing they were made on and
--  the record of why they don't count survives.

create or replace function public.replace_scheduled_courts(
  p_season     text,
  p_played_on  date,
  p_week_label text,
  p_courts     jsonb
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_court jsonb;
  v_old   record;
  v_count int := 0;
begin
  if not public.auth_is_admin() then
    raise exception 'Only an admin can set the schedule';
  end if;

  for v_old in
    select c.id,
           exists (select 1 from public.wager_offers o where o.court_id = c.id) as has_picks
      from public.scheduled_courts c
     where c.played_on = p_played_on
       and c.status <> 'void'
  loop
    if v_old.has_picks then
      update public.wager_offers    set status = 'void' where court_id = v_old.id;
      update public.scheduled_courts set status = 'void' where id       = v_old.id;
    else
      delete from public.scheduled_courts where id = v_old.id;
    end if;
  end loop;

  for v_court in select * from jsonb_array_elements(p_courts) loop
    insert into public.scheduled_courts (
      season, played_on, week_label, court_no,
      t1p1, t1p2, t2p1, t2p2,
      location, start_time, closes_at
    ) values (
      p_season,
      p_played_on,
      p_week_label,
      (v_court->>'court_no')::smallint,
      (v_court->>'t1p1')::uuid,
      (v_court->>'t1p2')::uuid,
      (v_court->>'t2p1')::uuid,
      (v_court->>'t2p2')::uuid,
      nullif(v_court->>'location', ''),
      nullif(v_court->>'time', ''),
      public.court_closes_at(p_played_on, v_court->>'time')
    );
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

-- ---------------------------------------------------------------------
--  13. Only signed-in members can write to the book
-- ---------------------------------------------------------------------
--  Supabase ships ALTER DEFAULT PRIVILEGES granting EXECUTE on functions
--  in public to anon, so `revoke all ... from public` does NOT take anon's
--  grant away. anon has to be named.

revoke all on function public.post_offer(uuid, smallint, int, int)              from public, anon;
revoke all on function public.take_offer(uuid, int)                             from public, anon;
revoke all on function public.cancel_offer(uuid)                                from public, anon;
revoke all on function public.void_court(uuid)                                   from public, anon;
revoke all on function public.replace_scheduled_courts(text, date, text, jsonb) from public, anon;

grant execute on function public.post_offer(uuid, smallint, int, int)              to authenticated;
grant execute on function public.take_offer(uuid, int)                             to authenticated;
grant execute on function public.cancel_offer(uuid)                                to authenticated;
grant execute on function public.void_court(uuid)                                   to authenticated;
grant execute on function public.replace_scheduled_courts(text, date, text, jsonb) to authenticated;

-- pair_key is read by the views, which run as the caller.
grant execute on function public.pair_key(uuid, uuid) to anon, authenticated;

-- =====================================================================
--  VERIFY — one report, because the SQL editor shows only the last result
-- =====================================================================

with tables_now as (
  select 'table: ' || table_name || ' / ' || grantee as what,
         string_agg(privilege_type, ', ' order by privilege_type) as detail
    from information_schema.role_table_grants
   where table_schema = 'public'
     and table_name in ('wager_offers', 'wager_fills', 'scheduled_courts')
     and grantee in ('anon', 'authenticated')
   group by table_name, grantee
),
gone as (
  select 'dropped: ' || t as what,
         case when to_regclass('public.' || t) is null
              then 'yes' else 'STILL THERE' end as detail
    from unnest(array['wager_ledger']) t
),
funcs as (
  select 'function: ' || p.proname || '(' ||
         pg_get_function_identity_arguments(p.oid) || ')' as what,
         case when p.prosecdef then 'definer' else 'invoker' end ||
         ', anon execute: ' ||
         case when has_function_privilege('anon', p.oid, 'execute')
              then 'YES — FIX THIS' else 'no' end as detail
    from pg_proc p
   where p.pronamespace = 'public'::regnamespace
     and p.proname in ('post_offer', 'take_offer', 'cancel_offer', 'void_court',
                       'replace_scheduled_courts', 'wager_me', 'pair_key',
                       'court_closes_at')
),
views as (
  select 'view: ' || table_name as what,
         'present' as detail
    from information_schema.views
   where table_schema = 'public'
     and table_name in ('v_court_results', 'v_pick_results', 'v_settle_week',
                        'v_settle_week_member', 'v_settle_season')
)
select * from tables_now
union all select * from gone
union all select * from funcs
union all select * from views
order by what;
