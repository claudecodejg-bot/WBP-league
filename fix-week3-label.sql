-- =====================================================================
--  Put the stray 26 October match back in Week 3, and clear out two
--  leftover schedule rows.
--
--  Adams & McGurren vs Baum & Dolcetti (6-0, 2-6, 6-1) was played on
--  Monday 26 October alongside two other courts, but is filed as Week 4.
--
--  Why: the Add Result form suggests a week label by taking the most
--  recently played match and adding one. The other two courts went in
--  first as Week 3; when this one was entered in a later sitting the form
--  looked at them and proposed Week 4. The site code now reuses the label
--  already on that night instead of incrementing, so this cannot recur.
--
--  Safe to re-run: both statements are scoped by value, not by position.
-- =====================================================================

-- 1. The mislabelled match -------------------------------------------------
UPDATE matches
   SET week_label = 'Week 3'
 WHERE season     = '2026-27'
   AND played_on  = '2026-10-26'
   AND week_label = 'Week 4';

-- Expect: UPDATE 1

-- 2. Leftover schedule rows ------------------------------------------------
-- The 26 October row survived because the night was finished off in a second
-- sitting (the old code only cleared the schedule when nothing was skipped
-- in that one sitting). The March row is from last season. All results for
-- both nights are in, so neither row has anything left to show.
DELETE FROM scheduled_matches
 WHERE played_on IN ('2026-10-26', '2026-03-23');

-- Expect: DELETE 2

-- 3. Check the result ------------------------------------------------------
SELECT week_label, played_on, count(*) AS matches
  FROM matches
 WHERE season = '2026-27'
 GROUP BY week_label, played_on
 ORDER BY played_on;

-- Expect exactly four rows, no stray Week 4 on 26 October:
--   Week 1  2026-10-12  3
--   Week 2  2026-10-19  2   <- see note below
--   Week 3  2026-10-26  3
--   Week 4  2026-11-02  3
--
-- Note: Week 2 holds only two matches. If three courts were played on
-- 19 October, one result was never entered. Nothing to do with this fix --
-- worth a look either way.
