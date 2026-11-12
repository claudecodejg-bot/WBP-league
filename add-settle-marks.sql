-- =====================================================================
--  add-settle-marks.sql — the tab runs until someone says it is paid
-- =====================================================================
--  settle.html used to show one night at a time and assume everyone
--  squared up before the next Monday. It now carries a RUNNING total
--  from one night to the next, and clears only when an admin says the
--  money has actually changed hands.
--
--  A clearing is recorded as a DATE — "everything up to and including
--  this night is paid" — and not as a flag on the picks themselves.
--  That matters: the picks are the evidence. Nothing in here edits a
--  single wager row, so a clearing made by mistake can be taken back
--  and every number comes straight back exactly as it was.
--
--  One row per clearing rather than one mutable row, so the page can
--  say when the tab was last cleared and by whom.
--
--  Run this in the Supabase SQL editor. It is safe to run twice.

create table if not exists public.settle_marks (
  id              uuid primary key default gen_random_uuid(),
  season          text not null,
  settled_through date not null,
  created_at      timestamptz not null default now(),
  created_by      uuid references public.members(id) on delete set null
);

create index if not exists settle_marks_season_idx
  on public.settle_marks (season, created_at desc);

comment on table public.settle_marks is
  'One row each time the tab was cleared. The open tab is every night AFTER the latest settled_through for the season.';

alter table public.settle_marks enable row level security;

-- Readable by anyone, like the rest of the picks system: the site is
-- public to read, and "when did we last square up" is not a secret.
drop policy if exists settle_marks_read on public.settle_marks;
create policy settle_marks_read on public.settle_marks
  for select to anon, authenticated using (true);

-- No write policy at all. Writes go through the two functions below,
-- the same as every other write in the picks system.
grant select on public.settle_marks to anon, authenticated;
revoke insert, update, delete on public.settle_marks from anon, authenticated;

-- ---------------------------------------------------------------------
--  Clear the tab
-- ---------------------------------------------------------------------
--  p_through is the last night that counts as paid. The page passes the
--  most recent night that has a result, so the admin never types a date.

create or replace function public.settle_mark_paid(p_season text, p_through date)
returns date
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid;
begin
  if not public.auth_is_admin() then
    raise exception 'Only an admin can clear the tab';
  end if;
  if p_season is null or p_through is null then
    raise exception 'Nothing to clear';
  end if;

  v_me := public.wager_me();

  insert into public.settle_marks (season, settled_through, created_by)
  values (p_season, p_through, v_me);

  return p_through;
end;
$$;

-- ---------------------------------------------------------------------
--  Take back the last clearing
-- ---------------------------------------------------------------------
--  Removes the most recently CREATED row, not the one with the latest
--  date. Those differ the moment someone clears an older night by
--  mistake, and "undo" has to mean the thing that just happened.

create or replace function public.settle_unmark(p_season text)
returns date                       -- what the tab now runs from, or null
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id   uuid;
  v_left date;
begin
  if not public.auth_is_admin() then
    raise exception 'Only an admin can undo that';
  end if;

  select id into v_id
    from public.settle_marks
   where season = p_season
   order by created_at desc
   limit 1;

  if v_id is null then
    raise exception 'The tab has not been cleared this season';
  end if;

  delete from public.settle_marks where id = v_id;

  select max(settled_through) into v_left
    from public.settle_marks where season = p_season;

  return v_left;
end;
$$;

revoke all on function public.settle_mark_paid(text, date) from public, anon;
revoke all on function public.settle_unmark(text)          from public, anon;
grant execute on function public.settle_mark_paid(text, date) to authenticated;
grant execute on function public.settle_unmark(text)          to authenticated;

-- =====================================================================
--  VERIFY — one report, because the editor shows only the last result
-- =====================================================================

with t as (
  select 'table: settle_marks' as what,
         case when to_regclass('public.settle_marks') is null
              then 'MISSING' else 'present' end as detail
),
r as (
  select 'rls: settle_marks' as what,
         case when c.relrowsecurity then 'on' else 'OFF — FIX THIS' end as detail
    from pg_class c where c.oid = 'public.settle_marks'::regclass
),
g as (
  select 'grant: settle_marks / ' || grantee as what,
         string_agg(privilege_type, ', ' order by privilege_type) as detail
    from information_schema.role_table_grants
   where table_schema = 'public' and table_name = 'settle_marks'
     and grantee in ('anon', 'authenticated')
   group by grantee
),
f as (
  select 'function: ' || p.proname as what,
         case when p.prosecdef then 'definer' else 'INVOKER — FIX THIS' end ||
         ', anon execute: ' ||
         case when has_function_privilege('anon', p.oid, 'execute')
              then 'YES — FIX THIS' else 'no' end as detail
    from pg_proc p
   where p.pronamespace = 'public'::regnamespace
     and p.proname in ('settle_mark_paid', 'settle_unmark')
)
select * from t
union all select * from r
union all select * from g
union all select * from f
order by what;
