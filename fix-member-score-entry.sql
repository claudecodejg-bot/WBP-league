-- =====================================================================
--  "new row violates row-level security policy for table matches"
--
--  McGurren hit this entering Court 1 on 9 Nov; Grills entered the same
--  court straight afterwards without trouble. The site opens the Add
--  Result button to every signed-in member, but the database still has
--  to agree -- and an INSERT policy that only passes for the admin gives
--  exactly this error to everyone else.
--
--  allow-members-enter-scores.sql is what grants that permission. The
--  evidence says it never reached the database: the trigger from
--  add-entry-log.sql is clearly live (last night's three results are all
--  stamped), so the entry log ran but the policy did not.
--
--  This file re-applies it and reports what was there before, so we find
--  out rather than assume. Safe to re-run, and safe if it turns out the
--  policy was there all along -- it is dropped and recreated either way.
--
--  Run in the Supabase SQL editor. The output at the end is the answer:
--  rows marked "1 before" are what McGurren was hitting, rows marked
--  "2 after" are what is in force now.
-- =====================================================================

-- Snapshot first, because the fix overwrites the evidence.
create temp table matches_policy_before as
select pol.polname::text as policy_name,
       case pol.polcmd when 'r' then 'SELECT' when 'a' then 'INSERT'
                       when 'w' then 'UPDATE' when 'd' then 'DELETE'
                       else 'ALL' end as command,
       coalesce((select string_agg(rolname, ', ')
                   from pg_roles where oid = any(pol.polroles)), 'PUBLIC') as roles,
       pg_get_expr(pol.polwithcheck, pol.polrelid)::text as with_check_expr
  from pg_policy pol
 where pol.polrelid = 'public.matches'::regclass;

begin;

-- The admin-only "FOR ALL" rule and any half-applied split are both
-- cleared, so the end state is the same whatever we started from.
drop policy if exists "Admins manage matches"        on public.matches;
drop policy if exists "Members add match results"    on public.matches;
drop policy if exists "Admins change match results"  on public.matches;
drop policy if exists "Admins remove match results"  on public.matches;

-- Anyone signed in may add a result. This is the line McGurren needed.
create policy "Members add match results" on public.matches
  for insert to authenticated
  with check (true);

-- Correcting or deleting a result stays with the admin. Entering a score
-- is a five-second fix if it is wrong; rewriting one quietly changes the
-- standings, and deleting one erases history.
create policy "Admins change match results" on public.matches
  for update to authenticated
  using (public.auth_is_admin()) with check (public.auth_is_admin());

create policy "Admins remove match results" on public.matches
  for delete to authenticated
  using (public.auth_is_admin());

-- Grants sit in front of RLS: the role needs both, and a missing grant
-- fails with a different message than the one McGurren saw.
grant select, insert on public.matches to authenticated;

commit;

-- ---------------------------------------------------------------------
--  RESULT -- read this output
-- ---------------------------------------------------------------------
--  Under "1 before", look at whether an INSERT policy existed at all and
--  what its with_check_expr said. If it is missing, or mentions
--  auth_is_admin(), that was the bug.
--
--  Under "2 after" you should see exactly three rows:
--    INSERT  Members add match results    with_check_expr = true
--    UPDATE  Admins change match results  with_check_expr = auth_is_admin()
--    DELETE  Admins remove match results
-- ---------------------------------------------------------------------
select '1 before' as stage, policy_name, command, roles, with_check_expr
  from matches_policy_before
union all
select '2 after', pol.polname::text,
       case pol.polcmd when 'r' then 'SELECT' when 'a' then 'INSERT'
                       when 'w' then 'UPDATE' when 'd' then 'DELETE'
                       else 'ALL' end,
       coalesce((select string_agg(rolname, ', ')
                   from pg_roles where oid = any(pol.polroles)), 'PUBLIC'),
       pg_get_expr(pol.polwithcheck, pol.polrelid)::text
  from pg_policy pol
 where pol.polrelid = 'public.matches'::regclass
 order by stage, command, policy_name;
