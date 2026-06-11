-- ============================================================
--  WBP League — Security & Integrity Hardening Migration
--  Run ONCE in the Supabase SQL Editor (Dashboard → SQL Editor).
--  Wrapped in a transaction: if anything fails, nothing applies.
--  Safe to re-run (idempotent).
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1) Canonical admin helper (SECURITY DEFINER)
--    Reads members WITHOUT triggering RLS, so it can't recurse
--    and is faster than an inline EXISTS subquery.
-- ------------------------------------------------------------
create or replace function public.auth_is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.members
    where auth_id = auth.uid() and is_admin = true
  );
$$;

revoke all on function public.auth_is_admin() from public;
grant execute on function public.auth_is_admin() to anon, authenticated;

-- ------------------------------------------------------------
-- 2) Hide member PII from anonymous (logged-out) visitors
--    Public pages only need id, full_name, is_guest.
--    This stops email / auth_id / is_admin / created_at from
--    being readable by anyone via the public API.
--    Logged-in users (authenticated role) keep full access,
--    so the is_admin check in the app still works.
-- ------------------------------------------------------------
revoke select on public.members from anon;
grant  select (id, full_name, is_guest) on public.members to anon;

-- ------------------------------------------------------------
-- 3) Normalize admin-write policies to use the helper
--    (matches / availability / scheduled_matches currently use
--     inline subqueries; members already uses the helper)
-- ------------------------------------------------------------
drop policy if exists "Admins manage matches" on public.matches;
create policy "Admins manage matches" on public.matches
  for all using (public.auth_is_admin()) with check (public.auth_is_admin());

drop policy if exists "Admins manage all availability" on public.availability;
create policy "Admins manage all availability" on public.availability
  for all using (public.auth_is_admin()) with check (public.auth_is_admin());

drop policy if exists "Admins manage scheduled matches" on public.scheduled_matches;
create policy "Admins manage scheduled matches" on public.scheduled_matches
  for all using (public.auth_is_admin()) with check (public.auth_is_admin());

drop policy if exists "Admins manage members" on public.members;
create policy "Admins manage members" on public.members
  for all using (public.auth_is_admin()) with check (public.auth_is_admin());

-- ------------------------------------------------------------
-- 4) Duplicate-match guard
--    First fail loudly if duplicates already exist (otherwise
--    the constraint can't be created). Then add a UNIQUE
--    constraint. NULLS NOT DISTINCT ensures 2-set matches
--    (set3 = NULL) are still de-duplicated.
-- ------------------------------------------------------------
do $$
declare dup_count int;
begin
  select count(*) into dup_count from (
    select 1 from public.matches
    group by played_on,
             team1_player1, team1_player2, team2_player1, team2_player2,
             team1_set1, team1_set2, team1_set3,
             team2_set1, team2_set2, team2_set3
    having count(*) > 1
  ) d;
  if dup_count > 0 then
    raise exception
      'Aborting: % duplicate match group(s) already exist. Remove them first, then re-run.', dup_count;
  end if;
end $$;

alter table public.matches drop constraint if exists matches_no_duplicates;
alter table public.matches
  add constraint matches_no_duplicates
  unique nulls not distinct
    (played_on,
     team1_player1, team1_player2, team2_player1, team2_player2,
     team1_set1, team1_set2, team1_set3,
     team2_set1, team2_set2, team2_set3);

commit;

-- ============================================================
--  VERIFY (optional — run separately after the COMMIT above)
-- ============================================================
-- Anonymous should now see ONLY id, full_name, is_guest:
--   select grantee, column_name from information_schema.column_privileges
--   where table_name='members' and grantee='anon' and privilege_type='SELECT';
--
-- Constraint should be present:
--   select conname from pg_constraint where conname='matches_no_duplicates';
