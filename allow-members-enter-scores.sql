-- =====================================================================
--  Let any signed-in member enter a score
--
--  Until now only the admin could add a result, so nothing could be
--  recorded on a night Grills wasn't there. Any member may now add one.
--
--  Adding is not the same as changing. A member can enter the court they
--  played; only an admin can edit or delete a result once it is in. That
--  keeps a mistyped score a five-second fix rather than something that
--  quietly rewrites the standings, and it means history cannot be erased
--  by anyone who happens to be logged in.
--
--  Unchanged by this file: reading (already public), the schedule, the
--  availability table, and members.
--
--  Safe to re-run.
-- =====================================================================

begin;

-- The old policy covered SELECT/INSERT/UPDATE/DELETE in one FOR ALL rule.
-- Split it so insert can be opened up without opening the rest.
drop policy if exists "Admins manage matches"        on public.matches;
drop policy if exists "Members add match results"    on public.matches;
drop policy if exists "Admins change match results"  on public.matches;
drop policy if exists "Admins remove match results"  on public.matches;

-- Anyone signed in may add a result.
create policy "Members add match results" on public.matches
  for insert to authenticated
  with check (true);

-- Only an admin may correct or remove one.
create policy "Admins change match results" on public.matches
  for update to authenticated
  using (public.auth_is_admin()) with check (public.auth_is_admin());

create policy "Admins remove match results" on public.matches
  for delete to authenticated
  using (public.auth_is_admin());

-- Table-level grants sit in front of RLS, so the role needs both.
grant select, insert on public.matches to authenticated;

commit;

-- ---------------------------------------------------------------------
--  VERIFY — run this after the COMMIT and check the output
-- ---------------------------------------------------------------------
select polname,
       case polcmd when 'r' then 'SELECT' when 'a' then 'INSERT'
                   when 'w' then 'UPDATE' when 'd' then 'DELETE'
                   else 'ALL' end as command
  from pg_policy
 where polrelid = 'public.matches'::regclass
 order by command, polname;

-- Expect to see, alongside whatever read policy is already there:
--   INSERT  Members add match results
--   UPDATE  Admins change match results
--   DELETE  Admins remove match results
--
-- You should NOT see "Admins manage matches" any more.
