-- =====================================================================
--  Threaded counter-offers
--
--  WHY A TABLE AND NOT JUST "POST THE OTHER SIDE"
--
--  Countering by posting the opposite side works, but it is not aimed at
--  anybody: the original poster has no idea a price was put up in answer
--  to his, and nothing links the two. This makes the answer a first-class
--  thing with one person to accept it.
--
--  WHAT A COUNTER IS
--
--  A proposal attached to an offer, from the side opposite it -- the same
--  side a taker would be on, with the same eligibility rule. It names its
--  own price from the COUNTERER's end, exactly as wager_offers does from
--  the poster's.
--
--  Accepting writes a fill at the COUNTER's terms and closes what is left
--  of the original. That is what a counter-offer is: an answer that
--  rejects the price it answers. Leaving the original open at its old
--  price after its owner has agreed a different one would put two prices
--  on one position, and wager_offers carries risk_open/win_open as a
--  matched pair at ONE price -- a fill at other odds would break that
--  invariant on every later read.
--
--  Run in the Supabase SQL editor. Safe to re-run.
-- =====================================================================

begin;

create table if not exists public.wager_counters (
  id           uuid primary key default gen_random_uuid(),
  offer_id     uuid not null references public.wager_offers(id) on delete cascade,
  countered_by uuid not null references public.members(id),

  -- The proposed price, from the COUNTERER's end. Mirrors the shape of
  -- wager_offers so the same odds helpers read both.
  risk_cents int not null check (risk_cents between 100 and 10000),
  win_cents  int not null check (win_cents  between 100 and 50000),

  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'withdrawn', 'expired')),

  created_at  timestamptz not null default now(),
  resolved_at timestamptz,

  -- Same 10-1 ceiling as an offer. A counter is still a price.
  constraint wager_counters_odds_sane check (
    win_cents <= risk_cents * 10 and risk_cents <= win_cents * 10
  )
);

create index if not exists wager_counters_offer_idx on public.wager_counters (offer_id);
create index if not exists wager_counters_by_idx    on public.wager_counters (countered_by);

-- One live counter per person per offer. Changing your mind replaces it
-- rather than stacking a second one the poster also has to answer.
create unique index if not exists wager_counters_one_pending
  on public.wager_counters (offer_id, countered_by)
  where status = 'pending';

comment on table public.wager_counters is
  'An answer to an offer at a different price, from the side opposite it. risk_cents/win_cents is the counterer''s end. Accepting fills at these terms and closes the original.';

alter table public.wager_counters enable row level security;

drop policy if exists "Public can read counters" on public.wager_counters;
create policy "Public can read counters"
  on public.wager_counters for select using (true);

commit;

-- Same treatment as wager_offers: readable by all, written only through
-- the functions below. REVOKE ALL rather than naming privileges -- ALL is
-- seven of them and TRUNCATE ignores row-level security.
revoke all    on public.wager_counters from anon, authenticated;
grant  select on public.wager_counters to   anon, authenticated;

-- ---------------------------------------------------------------------
--  counter_offer — answer a price with your own
-- ---------------------------------------------------------------------
--  Same eligibility as taking: a counter puts you on the side opposite
--  the offer, so if you are playing the court it has to be your team.

create or replace function public.counter_offer(
  p_offer_id   uuid,
  p_risk_cents int,                -- what the COUNTERER risks
  p_win_cents  int                 -- what the COUNTERER wins
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me      uuid;
  v_offer   record;
  v_court   record;
  v_my_side smallint;
  v_id      uuid;
begin
  v_me := public.wager_me();
  if v_me is null then
    raise exception 'You need to be signed in as a league member to counter';
  end if;

  if p_risk_cents is null or p_risk_cents < 100 then
    raise exception 'Risk at least $1';
  end if;
  if p_win_cents is null or p_win_cents < 100 then
    raise exception 'Play for at least $1';
  end if;
  if p_risk_cents > 10000 then
    raise exception 'Keep it under $100';
  end if;
  if p_win_cents > 50000 then
    raise exception 'Keep what you win under $500';
  end if;
  if p_win_cents > p_risk_cents * 10 or p_risk_cents > p_win_cents * 10 then
    raise exception 'That price is beyond 10-1';
  end if;

  select * into v_offer from public.wager_offers where id = p_offer_id for update;
  if v_offer.id is null then
    raise exception 'No such offer';
  end if;
  if v_offer.status <> 'open' or v_offer.win_open_cents <= 0 then
    raise exception 'That offer is no longer open';
  end if;
  if v_offer.offered_by = v_me then
    raise exception 'That is your own offer -- pull it back and post a new price';
  end if;

  select * into v_court from public.scheduled_courts where id = v_offer.court_id;
  if v_court.status <> 'open' then
    raise exception 'That court is closed for picks';
  end if;
  if now() >= v_court.closes_at then
    raise exception 'Picks for that court closed at %', v_court.closes_at;
  end if;

  v_my_side := case
    when v_me in (v_court.t1p1, v_court.t1p2) then 1::smallint
    when v_me in (v_court.t2p1, v_court.t2p2) then 2::smallint
    else null
  end;
  if v_my_side is not null and v_my_side <> (3 - v_offer.side)::smallint then
    raise exception 'That would be a pick against your own team';
  end if;

  -- Changing your mind replaces your live counter rather than stacking a
  -- second one the poster also has to answer. The partial unique index
  -- enforces it; this is what makes replacing it legal.
  update public.wager_counters
     set status = 'withdrawn', resolved_at = now()
   where offer_id = p_offer_id
     and countered_by = v_me
     and status = 'pending';

  insert into public.wager_counters (offer_id, countered_by, risk_cents, win_cents)
  values (p_offer_id, v_me, p_risk_cents, p_win_cents)
  returning id into v_id;

  return v_id;
end;
$$;

-- ---------------------------------------------------------------------
--  accept_counter — the poster takes the answer
-- ---------------------------------------------------------------------
--  Writes ONE fill at the counter's terms and closes what is left of the
--  original. See the note at the top: an offer's risk_open/win_open are a
--  matched pair at one price, and a fill at other odds cannot be
--  subtracted from them without corrupting every later read.

create or replace function public.accept_counter(p_counter_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me      uuid;
  v_counter record;
  v_offer   record;
  v_court   record;
begin
  v_me := public.wager_me();
  if v_me is null then
    raise exception 'You need to be signed in as a league member';
  end if;

  select * into v_counter from public.wager_counters
   where id = p_counter_id for update;
  if v_counter.id is null then
    raise exception 'No such counter';
  end if;
  if v_counter.status <> 'pending' then
    raise exception 'That counter has already been %', v_counter.status;
  end if;

  select * into v_offer from public.wager_offers
   where id = v_counter.offer_id for update;
  if v_offer.offered_by <> v_me then
    raise exception 'Only the person who put the price up can accept a counter';
  end if;
  if v_offer.status <> 'open' or v_offer.win_open_cents <= 0 then
    raise exception 'That offer is no longer open';
  end if;

  select * into v_court from public.scheduled_courts where id = v_offer.court_id;
  if v_court.status <> 'open' then
    raise exception 'That court is closed for picks';
  end if;
  if now() >= v_court.closes_at then
    raise exception 'Picks for that court closed at %', v_court.closes_at;
  end if;

  -- The counterer is the taker; their end is the counter's own numbers,
  -- and the poster's is the mirror of them.
  insert into public.wager_fills (offer_id, taker, poster_risk_cents, taker_risk_cents)
  values (v_offer.id, v_counter.countered_by, v_counter.win_cents, v_counter.risk_cents);

  update public.wager_offers
     set risk_open_cents = 0,
         win_open_cents  = 0,
         status = 'filled'
   where id = v_offer.id;

  update public.wager_counters
     set status = 'accepted', resolved_at = now()
   where id = p_counter_id;

  -- Nobody else's counter can be answered now: the offer is closed.
  update public.wager_counters
     set status = 'expired', resolved_at = now()
   where offer_id = v_offer.id
     and status = 'pending';

  return jsonb_build_object('poster_risk_cents', v_counter.win_cents,
                            'taker_risk_cents',  v_counter.risk_cents);
end;
$$;

-- ---------------------------------------------------------------------
--  close_counter — decline it, or take it back
-- ---------------------------------------------------------------------
--  One function for both ends. Who is calling decides which it is, so
--  the page never has to pass an action it could get wrong.

create or replace function public.close_counter(p_counter_id uuid)
returns text                       -- 'declined' or 'withdrawn'
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me      uuid;
  v_counter record;
  v_offer   record;
  v_what    text;
begin
  v_me := public.wager_me();
  if v_me is null then
    raise exception 'You need to be signed in as a league member';
  end if;

  select * into v_counter from public.wager_counters
   where id = p_counter_id for update;
  if v_counter.id is null then
    raise exception 'No such counter';
  end if;
  if v_counter.status <> 'pending' then
    raise exception 'That counter has already been %', v_counter.status;
  end if;

  select * into v_offer from public.wager_offers where id = v_counter.offer_id;

  if v_counter.countered_by = v_me then
    v_what := 'withdrawn';
  elsif v_offer.offered_by = v_me then
    v_what := 'declined';
  else
    raise exception 'That counter is not yours to close';
  end if;

  update public.wager_counters
     set status = v_what, resolved_at = now()
   where id = p_counter_id;

  return v_what;
end;
$$;
