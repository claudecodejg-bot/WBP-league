-- =====================================================================
--  Let any signed-in member record a Vinny's outing
--
--  Companion to allow-members-enter-scores.sql. Whoever enters the night's
--  scores can now also tick who went out afterwards.
--
--  READ THIS BEFORE RUNNING -- it is more permissive than the match one.
--
--  A night is saved by clearing it and re-inserting the ticks, so a member
--  needs DELETE as well as INSERT. That means any signed-in member can
--  clear a night's attendance, not just add to it. There is no way around
--  that while the form works as a tick-list for the whole night.
--
--  Why that is an acceptable trade here but was not for match results:
--    - attendance is re-entered in seconds; a match score is not
--    - it feeds a bit of fun, not the standings
--    - the same 16 people are the only ones who can sign in
--
--  If you would rather keep this admin-only, simply do not run this file.
--  Everything else works without it; members just will not see the tick
--  list. Tell me and I will put the button back behind the admin check.
--
--  Safe to re-run.
-- =====================================================================

begin;

drop policy if exists "Admins manage vinnys"      on public.vinnys;
drop policy if exists "Members record vinnys"     on public.vinnys;
drop policy if exists "Members clear vinnys"      on public.vinnys;
drop policy if exists "Admins change vinnys"      on public.vinnys;

-- Add a tick.
create policy "Members record vinnys" on public.vinnys
  for insert to authenticated
  with check (true);

-- Remove one, so a night can be re-saved cleanly.
create policy "Members clear vinnys" on public.vinnys
  for delete to authenticated
  using (true);

-- Rows are only ever inserted or deleted, never edited in place, so UPDATE
-- stays with the admin.
create policy "Admins change vinnys" on public.vinnys
  for update to authenticated
  using (public.auth_is_admin()) with check (public.auth_is_admin());

grant select, insert, delete on public.vinnys to authenticated;

commit;

-- ---------------------------------------------------------------------
--  VERIFY
-- ---------------------------------------------------------------------
select polname,
       case polcmd when 'r' then 'SELECT' when 'a' then 'INSERT'
                   when 'w' then 'UPDATE' when 'd' then 'DELETE'
                   else 'ALL' end as command
  from pg_policy
 where polrelid = 'public.vinnys'::regclass
 order by command, polname;

-- Expect:
--   SELECT  Public can read vinnys
--   INSERT  Members record vinnys
--   UPDATE  Admins change vinnys
--   DELETE  Members clear vinnys
