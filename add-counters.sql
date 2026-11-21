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
