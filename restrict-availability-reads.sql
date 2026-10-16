-- =====================================================================
--  Make availability answers private to the member and the admin
--
--  The availability page no longer shows members the league-wide tally,
--  but that is only the user interface. The database still says any
--  signed-in member may read every row:
--
--      "Logged-in users can read availability"
--        USING (auth.uid() IS NOT NULL)
--
--  So a member who opened the browser console could still read everyone
--  else's answers. This replaces that with "your own rows only", and
--  leaves the existing admin policy to grant the full view.
--
--  Checked safe before writing this:
--    - a member's own form filters by their own member_id already
--    - the admin tally and grid run under "Admins manage all availability"
--    - the scheduler is admin-only
--    - the reminder script uses the secret key, which bypasses RLS
--
--  Run in the Supabase SQL editor. Safe to re-run.
-- =====================================================================

DROP POLICY IF EXISTS "Logged-in users can read availability" ON availability;

CREATE POLICY "Members read own availability"
  ON availability FOR SELECT
  USING (
    member_id IN (SELECT id FROM members WHERE auth_id = auth.uid())
    OR public.auth_is_admin()
  );

-- Verify: expect "Members read own availability" and the admin policy,
-- and NOT "Logged-in users can read availability".
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'availability'
ORDER BY policyname;
