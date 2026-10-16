-- =====================================================================
--  Narrow who can read availability answers
--
--  Replaces an earlier draft of this file. That version allowed members
--  to read only their own rows, which would have broken the "Who's In
--  This Week" summary they are meant to see. This version matches what
--  the page actually shows:
--
--    own rows             any week, always
--    everyone else's      the coming Monday only
--    admin                everything
--
--  The current policy is wide open to anyone signed in:
--      "Logged-in users can read availability"
--        USING (auth.uid() IS NOT NULL)
--  so without this, hiding the later weeks in the page is cosmetic —
--  a member could still read the whole table from the browser console.
--
--  Run in the Supabase SQL editor. Safe to re-run.
-- =====================================================================

DROP POLICY IF EXISTS "Logged-in users can read availability" ON availability;
DROP POLICY IF EXISTS "Members read own availability" ON availability;

CREATE POLICY "Members read own rows and the coming week"
  ON availability FOR SELECT
  USING (
    -- Your own answers, whichever week they are for.
    member_id IN (SELECT id FROM members WHERE auth_id = auth.uid())

    -- Everyone's answers for the coming Monday. Mondays are seven days
    -- apart, and the next one is never more than six days away, so this
    -- window captures exactly one week and no more.
    OR (week_start >= CURRENT_DATE AND week_start <= CURRENT_DATE + 6)

    OR public.auth_is_admin()
  );

-- Verify: expect "Members read own rows and the coming week" plus the
-- admin policy, and NOT "Logged-in users can read availability".
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'availability'
ORDER BY policyname;

-- Sanity: which Monday the window currently resolves to.
SELECT CURRENT_DATE AS today,
       CURRENT_DATE + 6 AS window_end,
       (SELECT min(week_start) FROM availability
        WHERE week_start >= CURRENT_DATE) AS coming_monday;
