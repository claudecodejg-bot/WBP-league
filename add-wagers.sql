-- =====================================================================
--  Phase 1 — the picks book
--
--  A peer-to-peer book, not a house. Someone offers a side for an amount;
--  anyone else takes the other side for part or all of it. Even money.
--  Play money only — nothing here settles in cash.
--
--  HOW THE MONEY MOVES
--
--  wager_ledger is the only record of a balance. A balance is
--  sum(delta) — never a stored number that can drift away from the rows
--  that explain it. With 16 members and a handful of picks a week the sum
--  costs nothing, and if settlement ever goes wrong you can see every
--  movement and reverse it instead of guessing what the number should be.
--
--  Money is escrowed the moment it is committed:
--
--    post an offer of 20   ->  -20  (the whole offer, not just the matched
--                                    part, so the same 20 cannot be offered
--                                    on four courts at once)
--    take 12 of it         ->  -12  (the taker)
--    court settles         ->  +2x the stake to whoever won each matched
--                                 pair, + the unmatched 8 back to the offerer
--
--  So "what can I bet" is just sum(delta). No exposure arithmetic.
--
--  WHY EVERY WRITE IS A FUNCTION
--
--  None of the rules that make this safe can be written as an RLS policy.
--  "Only if the offer has enough left, and you have the balance, and it is
--  before the court closes" needs a row lock and writes to three tables in
--  one transaction. So the tables take no writes at all from the browser —
--  insert/update/delete are revoked from anon and authenticated, and these
--  SECURITY DEFINER functions are the only way in.
--
--  Depends on add-scheduled-courts.sql. Run in the Supabase SQL editor.
--  Safe to re-run.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
--  Tables
-- ---------------------------------------------------------------------

create table if not exists public.wager_ledger (
  id         bigserial   primary key,
  member_id  uuid        not null references public.members(id) on delete cascade,
  season     text        not null,
  delta      int         not null,
  reason     text        not null,
  ref_id     uuid,                       -- the offer or fill this came from
  created_at timestamptz not null default now()
);

create index if not exists wager_ledger_member_idx
  on public.wager_ledger (member_id, season);

comment on table public.wager_ledger is
  'Every movement of play money. A balance is sum(delta) — there is no stored balance anywhere.';

create table if not exists public.wager_offers (
  id             uuid        primary key default gen_random_uuid(),
  court_id       uuid        not null references public.scheduled_courts(id) on delete cascade,
  season         text        not null,
  offered_by     uuid        not null references public.members(id),
  side           smallint    not null check (side in (1, 2)),

  -- Reserved. Even money for now; this is here so "giving 3 games" is a UI
  -- change later rather than a migration against live picks.
  handicap_games smallint    not null default 0,

  amount         int         not null check (amount > 0),
  remaining      int         not null check (remaining >= 0),
  status         text        not null default 'open'
                   check (status in ('open', 'filled', 'cancelled', 'settled', 'void')),
  created_at     timestamptz not null default now(),

  constraint wager_offers_remaining_sane check (remaining <= amount)
);

create index if not exists wager_offers_court_idx on public.wager_offers (court_id);

create table if not exists public.wager_fills (
  id         uuid        primary key default gen_random_uuid(),
  offer_id   uuid        not null references public.wager_offers(id) on delete cascade,
  taker      uuid        not null references public.members(id),
  amount     int         not null check (amount > 0),
  outcome    text        check (outcome in ('offerer', 'taker', 'void')),
  settled_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists wager_fills_offer_idx on public.wager_fills (offer_id);

comment on table public.wager_fills is
  'A matched pair: the taker is on the opposite side to their offer. outcome names which end of the pair won.';

-- ---------------------------------------------------------------------
--  Readable by all, writable by none
-- ---------------------------------------------------------------------

alter table public.wager_ledger enable row level security;
alter table public.wager_offers enable row level security;
alter table public.wager_fills  enable row level security;

drop policy if exists "Public can read the ledger" on public.wager_ledger;
create policy "Public can read the ledger"
  on public.wager_ledger for select using (true);

drop policy if exists "Public can read offers" on public.wager_offers;
create policy "Public can read offers"
  on public.wager_offers for select using (true);

drop policy if exists "Public can read fills" on public.wager_fills;
create policy "Public can read fills"
  on public.wager_fills for select using (true);

commit;

-- Play money on a site that is public by design: balances and the book are
-- part of the fun. Writes are another matter — nothing but the functions.
revoke insert, update, delete on public.wager_ledger from anon, authenticated;
revoke insert, update, delete on public.wager_offers from anon, authenticated;
revoke insert, update, delete on public.wager_fills  from anon, authenticated;
grant  select on public.wager_ledger to anon, authenticated;
grant  select on public.wager_offers to anon, authenticated;
grant  select on public.wager_fills  to anon, authenticated;

-- ---------------------------------------------------------------------
--  Balances
-- ---------------------------------------------------------------------

create or replace view public.v_wager_balances
  with (security_invoker = true) as
  select member_id, season, sum(delta)::int as balance
    from public.wager_ledger
   group by member_id, season;

grant select on public.v_wager_balances to anon, authenticated;

-- ---------------------------------------------------------------------
--  Small helpers
-- ---------------------------------------------------------------------

-- Who is calling. SECURITY DEFINER because anon has no column grant on
-- members.auth_id.
create or replace function public.wager_me()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.members where auth_id = auth.uid() limit 1;
$$;

create or replace function public.wager_balance(p_member uuid, p_season text)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(delta), 0)::int
    from public.wager_ledger
   where member_id = p_member and season = p_season;
$$;

revoke all     on function public.wager_me()                   from public;
revoke all     on function public.wager_balance(uuid, text)    from public;
grant  execute on function public.wager_me()                   to   authenticated;
grant  execute on function public.wager_balance(uuid, text)     to   anon, authenticated;

-- ---------------------------------------------------------------------
--  post_offer — put a side up
-- ---------------------------------------------------------------------

create or replace function public.post_offer(
  p_court_id uuid,
  p_side     smallint,
  p_amount   int
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
  v_balance  int;
  v_offer_id uuid;
begin
  v_me := public.wager_me();
  if v_me is null then
    raise exception 'You need to be signed in as a league member to make a pick';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount has to be more than zero';
  end if;
  if p_side is null or p_side not in (1, 2) then
    raise exception 'Pick side 1 or side 2';
  end if;

  select * into v_court from public.scheduled_courts where id = p_court_id;
  if v_court.id is null then
    raise exception 'No such court';
  end if;
  if v_court.status <> 'open' then
    raise exception 'That court is closed for picks';
  end if;
  -- Wall clock, not "has the result been entered yet". Results land hours
  -- after play, so anyone who played would otherwise know the answer.
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

  v_balance := public.wager_balance(v_me, v_court.season);
  if v_balance < p_amount then
    raise exception 'Not enough in your bankroll — % left', v_balance;
  end if;

  insert into public.wager_offers (court_id, season, offered_by, side, amount, remaining)
  values (p_court_id, v_court.season, v_me, p_side, p_amount, p_amount)
  returning id into v_offer_id;

  insert into public.wager_ledger (member_id, season, delta, reason, ref_id)
  values (v_me, v_court.season, -p_amount, 'offer_escrow', v_offer_id);

  return v_offer_id;
end;
$$;

-- ---------------------------------------------------------------------
--  take_offer — take the other side, all of it or part
-- ---------------------------------------------------------------------
--  The important line in this file is the FOR UPDATE below. Without it,
--  two people tapping "take it" in the same second both read remaining=20,
--  both insert a 20 fill, and one of those two stakes is backed by nothing.

create or replace function public.take_offer(
  p_offer_id uuid,
  p_amount   int
)
returns int                      -- what was actually taken, which may be less
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me           uuid;
  v_offer        record;
  v_court        record;
  v_my_side      smallint;
  v_taking_side  smallint;
  v_fill         int;
  v_fill_id      uuid;
  v_balance      int;
begin
  v_me := public.wager_me();
  if v_me is null then
    raise exception 'You need to be signed in as a league member to make a pick';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount has to be more than zero';
  end if;

  select * into v_offer from public.wager_offers where id = p_offer_id for update;
  if v_offer.id is null then
    raise exception 'No such offer';
  end if;
  if v_offer.status <> 'open' then
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
  v_taking_side := (3 - v_offer.side)::smallint;

  v_my_side := case
    when v_me in (v_court.t1p1, v_court.t1p2) then 1::smallint
    when v_me in (v_court.t2p1, v_court.t2p2) then 2::smallint
    else null
  end;

  if v_my_side is not null and v_my_side <> v_taking_side then
    raise exception 'That would be a pick against your own team';
  end if;

  v_fill := least(p_amount, v_offer.remaining);
  if v_fill <= 0 then
    raise exception 'Nothing left to take on that offer';
  end if;

  v_balance := public.wager_balance(v_me, v_offer.season);
  if v_balance < v_fill then
    raise exception 'Not enough in your bankroll — % left', v_balance;
  end if;

  insert into public.wager_fills (offer_id, taker, amount)
  values (p_offer_id, v_me, v_fill)
  returning id into v_fill_id;

  insert into public.wager_ledger (member_id, season, delta, reason, ref_id)
  values (v_me, v_offer.season, -v_fill, 'fill_stake', v_fill_id);

  update public.wager_offers
     set remaining = remaining - v_fill,
         status    = case when remaining - v_fill = 0 then 'filled' else 'open' end
   where id = p_offer_id;

  return v_fill;
end;
$$;

-- ---------------------------------------------------------------------
--  cancel_offer — pull back what nobody has taken
-- ---------------------------------------------------------------------
--  Only the unmatched remainder comes back. Anything already matched is a
--  bet somebody else is holding, and stays live.

create or replace function public.cancel_offer(p_offer_id uuid)
returns int                      -- amount refunded
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me        uuid;
  v_offer     record;
  v_refund    int;
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

  v_refund := v_offer.remaining;

  update public.wager_offers
     set remaining = 0,
         status    = case when exists (select 1 from public.wager_fills where offer_id = p_offer_id)
                          then 'filled' else 'cancelled' end
   where id = p_offer_id;

  if v_refund > 0 then
    insert into public.wager_ledger (member_id, season, delta, reason, ref_id)
    values (v_offer.offered_by, v_offer.season, v_refund, 'offer_cancel_refund', p_offer_id);
  end if;

  return v_refund;
end;
$$;

-- ---------------------------------------------------------------------
--  settle_court — pay out
-- ---------------------------------------------------------------------
--  The winning side is stated by the admin rather than read off the match.
--  Linking a recorded match back to a scheduled court is its own job: the
--  team1/team2 slots are not stable (js/scoring.js says so outright), subs
--  happen, and a reshuffled court has to void rather than guess. That is
--  the Phase 2 upgrade; this is the honest minimum that makes the book
--  work end to end.
--
--  Even money, so the winner of each matched pair takes 2x the stake:
--  their own back, plus the other side's.

create or replace function public.settle_court(
  p_court_id     uuid,
  p_winning_side smallint
)
returns int                      -- matched pairs settled
language plpgsql
security definer
set search_path = public
as $$
declare
  v_court  record;
  v_offer  record;
  v_fill   record;
  v_winner uuid;
  v_n      int := 0;
begin
  if not public.auth_is_admin() then
    raise exception 'Only an admin can settle a court';
  end if;
  if p_winning_side is null or p_winning_side not in (1, 2) then
    raise exception 'Winning side must be 1 or 2';
  end if;

  select * into v_court from public.scheduled_courts where id = p_court_id for update;
  if v_court.id is null then
    raise exception 'No such court';
  end if;
  if v_court.status in ('settled', 'void') then
    raise exception 'That court is already %', v_court.status;
  end if;

  for v_offer in
    select * from public.wager_offers where court_id = p_court_id for update
  loop
    -- Nobody took this part: it was never a bet, so it goes straight back.
    if v_offer.remaining > 0 and v_offer.status = 'open' then
      insert into public.wager_ledger (member_id, season, delta, reason, ref_id)
      values (v_offer.offered_by, v_offer.season, v_offer.remaining,
              'offer_unfilled_refund', v_offer.id);

      update public.wager_offers set remaining = 0 where id = v_offer.id;
    end if;

    for v_fill in
      select * from public.wager_fills where offer_id = v_offer.id and outcome is null
    loop
      v_winner := case when v_offer.side = p_winning_side
                       then v_offer.offered_by
                       else v_fill.taker
                  end;

      insert into public.wager_ledger (member_id, season, delta, reason, ref_id)
      values (v_winner, v_offer.season, v_fill.amount * 2, 'settle_win', v_fill.id);

      update public.wager_fills
         set outcome    = case when v_offer.side = p_winning_side then 'offerer' else 'taker' end,
             settled_at = now()
       where id = v_fill.id;

      v_n := v_n + 1;
    end loop;

    update public.wager_offers set status = 'settled' where id = v_offer.id;
  end loop;

  update public.scheduled_courts set status = 'settled' where id = p_court_id;

  return v_n;
end;
$$;

-- ---------------------------------------------------------------------
--  void_court — give everything back
-- ---------------------------------------------------------------------
--  For a court that did not happen, got reshuffled, or whose result cannot
--  be pinned to the pairing anyone bet on. Everyone ends up level: the
--  offerer gets the unmatched remainder plus their matched stakes, each
--  taker gets their stake.

create or replace function public.void_court(p_court_id uuid)
returns int                      -- bets voided
language plpgsql
security definer
set search_path = public
as $$
declare
  v_court record;
  v_offer record;
  v_fill  record;
  v_n     int := 0;
begin
  if not public.auth_is_admin() then
    raise exception 'Only an admin can void a court';
  end if;

  select * into v_court from public.scheduled_courts where id = p_court_id for update;
  if v_court.id is null then
    raise exception 'No such court';
  end if;
  if v_court.status = 'settled' then
    raise exception 'That court is already settled — reverse it by hand if it was wrong';
  end if;

  for v_offer in
    select * from public.wager_offers where court_id = p_court_id
                                       and status <> 'void' for update
  loop
    if v_offer.remaining > 0 then
      insert into public.wager_ledger (member_id, season, delta, reason, ref_id)
      values (v_offer.offered_by, v_offer.season, v_offer.remaining,
              'offer_void_refund', v_offer.id);
      update public.wager_offers set remaining = 0 where id = v_offer.id;
    end if;

    for v_fill in
      select * from public.wager_fills where offer_id = v_offer.id and outcome is null
    loop
      -- Both ends get their own stake back.
      insert into public.wager_ledger (member_id, season, delta, reason, ref_id)
      values (v_offer.offered_by, v_offer.season, v_fill.amount, 'fill_void_refund', v_fill.id),
             (v_fill.taker,       v_offer.season, v_fill.amount, 'fill_void_refund', v_fill.id);

      update public.wager_fills
         set outcome = 'void', settled_at = now()
       where id = v_fill.id;

      v_n := v_n + 1;
    end loop;

    update public.wager_offers set status = 'void' where id = v_offer.id;
  end loop;

  update public.scheduled_courts set status = 'void' where id = p_court_id;

  return v_n;
end;
$$;

-- ---------------------------------------------------------------------
--  grant_season_bankroll — everyone starts level
-- ---------------------------------------------------------------------
--  Idempotent: a member who already has a grant for the season is skipped,
--  so re-running after someone joins tops up only the new person.

create or replace function public.grant_season_bankroll(
  p_season text,
  p_amount int
)
returns int                      -- members granted
language plpgsql
security definer
set search_path = public
as $$
declare
  v_n int;
begin
  if not public.auth_is_admin() then
    raise exception 'Only an admin can hand out bankrolls';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Bankroll has to be more than zero';
  end if;

  with granted as (
    insert into public.wager_ledger (member_id, season, delta, reason)
    select ms.member_id, p_season, p_amount, 'season_grant'
      from public.member_seasons ms
      join public.members m on m.id = ms.member_id and m.is_guest = false
     where ms.season = p_season
       and not exists (
         select 1 from public.wager_ledger l
          where l.member_id = ms.member_id
            and l.season    = p_season
            and l.reason    = 'season_grant')
    returning 1
  )
  select count(*)::int into v_n from granted;

  return v_n;
end;
$$;

-- ---------------------------------------------------------------------
--  Regenerating a schedule has to let go of picks made on the old one
-- ---------------------------------------------------------------------
--  Replaces the Phase 0 version. If the admin re-runs the scheduler for a
--  night somebody has already bet on, those picks were made on a pairing
--  that is about to stop existing, so they are voided and refunded rather
--  than silently re-pointed at different players.

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

  -- Replacing a night deletes its court rows, and the offers on them cascade
  -- with it. For a court that has already paid out that would throw away the
  -- record explaining balances people can see, so refuse rather than do it
  -- quietly. Voiding by hand first is a deliberate act; this is not.
  if exists (
    select 1 from public.scheduled_courts
     where played_on = p_played_on and status = 'settled'
  ) then
    raise exception
      'A court on % has already been settled — regenerating would delete the paid-out picks', p_played_on;
  end if;

  for v_old in
    select c.id from public.scheduled_courts c
     where c.played_on = p_played_on
       and exists (select 1 from public.wager_offers o where o.court_id = c.id)
  loop
    perform public.void_court(v_old.id);
  end loop;

  delete from public.scheduled_courts where played_on = p_played_on;

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
--  Only signed-in members can move money
-- ---------------------------------------------------------------------

revoke all on function public.post_offer(uuid, smallint, int)                 from public;
revoke all on function public.take_offer(uuid, int)                           from public;
revoke all on function public.cancel_offer(uuid)                              from public;
revoke all on function public.settle_court(uuid, smallint)                    from public;
revoke all on function public.void_court(uuid)                                from public;
revoke all on function public.grant_season_bankroll(text, int)                from public;
revoke all on function public.replace_scheduled_courts(text, date, text, jsonb) from public;

grant execute on function public.post_offer(uuid, smallint, int)                 to authenticated;
grant execute on function public.take_offer(uuid, int)                           to authenticated;
grant execute on function public.cancel_offer(uuid)                              to authenticated;
grant execute on function public.settle_court(uuid, smallint)                    to authenticated;
grant execute on function public.void_court(uuid)                                to authenticated;
grant execute on function public.grant_season_bankroll(text, int)                to authenticated;
grant execute on function public.replace_scheduled_courts(text, date, text, jsonb) to authenticated;

-- ---------------------------------------------------------------------
--  VERIFY
-- ---------------------------------------------------------------------

-- 1. Three tables, and no write grants outside the functions. Expect only
--    SELECT for anon and authenticated.
select table_name, grantee, string_agg(privilege_type, ', ' order by privilege_type) as privs
  from information_schema.role_table_grants
 where table_schema = 'public'
   and table_name in ('wager_ledger', 'wager_offers', 'wager_fills', 'scheduled_courts')
   and grantee in ('anon', 'authenticated')
 group by table_name, grantee
 order by table_name, grantee;

-- 2. The functions are all there.
select proname,
       pg_get_function_identity_arguments(oid) as args,
       prosecdef as security_definer
  from pg_proc
 where pronamespace = 'public'::regnamespace
   and proname in ('post_offer', 'take_offer', 'cancel_offer', 'settle_court',
                   'void_court', 'grant_season_bankroll', 'replace_scheduled_courts',
                   'wager_me', 'wager_balance', 'court_closes_at')
 order by proname;

-- 3. Nobody has a bankroll yet. Hand them out when you are ready to open
--    the book — do it at a week boundary, not mid-week:
--
--      select public.grant_season_bankroll('2026-27', 500);
--
--    Then this shows everyone level on 500.
select m.full_name, b.balance
  from public.v_wager_balances b
  join public.members m on m.id = b.member_id
 where b.season = '2026-27'
 order by b.balance desc, m.full_name;
