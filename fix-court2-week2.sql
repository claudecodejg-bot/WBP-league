-- =====================================================================
--  Correct Court 2, Monday 19 October 2026
--
--  Rayhill & McGurren lost the first set 6-7; it was recorded as a 7-6
--  win for them. Only the first set is wrong — sets two and three stand.
--
--      stored:  Jonson, R. & Moyers  6, 3, 0
--               Rayhill & McGurren   7, 6, 6
--
--      correct: Jonson, R. & Moyers  7, 3, 0
--               Rayhill & McGurren   6, 6, 6
--
--  Rayhill & McGurren still win the match two sets to one, but it
--  becomes a comeback rather than a straight-sets win.
--
--  Run in the Supabase SQL editor. Matched on the match id, so it can
--  only ever touch this one row.
-- =====================================================================

UPDATE matches
SET team1_set1 = 7,    -- Jonson, R. & Moyers took the opener
    team2_set1 = 6     -- Rayhill & McGurren lost it
WHERE id = '3563c495-6b57-40f2-be14-97f88ba8abfc';

-- Verify: expect 7,3,0 against 6,6,6.
SELECT played_on, week_label,
       team1_set1 || ', ' || team1_set2 || ', ' || team1_set3 AS jonson_moyers,
       team2_set1 || ', ' || team2_set2 || ', ' || team2_set3 AS rayhill_mcgurren
FROM matches
WHERE id = '3563c495-6b57-40f2-be14-97f88ba8abfc';
