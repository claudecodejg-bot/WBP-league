-- =====================================================================
--  Drop the disambiguating initials
--
--      "Johnson, S."  ->  "Johnson"
--      "Jonson, R."   ->  "Jonson"
--
--  The initials were added so the two near-identical surnames could be
--  told apart. Dropping them is deliberate: the championship and golf
--  pages already refer to plain "Jonson" in their write-ups, so this
--  makes the site consistent with itself.
--
--  Note there is also a guest called "Doug Johnson" (3 matches), who is
--  left alone.
--
--  Names are stored once on members.full_name, so every page follows —
--  standings, results, player pages, matchups and the scheduler. The one
--  exception is scheduled_matches, which stores plain names inside its
--  courts JSON, so that is updated too or a saved schedule would point
--  at a player who no longer exists under that name.
--
--  Run in the Supabase SQL editor. Safe to re-run.
-- =====================================================================

-- Guard: abort if a plain "Johnson" or "Jonson" already exists, which
-- would mean two people ending up indistinguishable.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM members WHERE full_name IN ('Johnson', 'Jonson')) THEN
    RAISE EXCEPTION 'A member named Johnson or Jonson already exists — stopping.';
  END IF;
END $$;

UPDATE members SET full_name = 'Johnson' WHERE full_name = 'Johnson, S.';
UPDATE members SET full_name = 'Jonson'  WHERE full_name = 'Jonson, R.';

-- Saved schedules hold names as text inside the courts JSON.
UPDATE scheduled_matches
SET courts = REPLACE(REPLACE(courts::text, '"Jonson, R."', '"Jonson"'),
                     '"Johnson, S."', '"Johnson"')::jsonb
WHERE courts::text LIKE '%Jonson, R.%'
   OR courts::text LIKE '%Johnson, S.%';

-- Verify: expect Johnson, Jonson and Doug Johnson, and no initials left.
SELECT full_name, is_guest
FROM members
WHERE full_name ILIKE '%johnson%' OR full_name ILIKE '%jonson%'
ORDER BY full_name;

-- Match counts should be untouched by a rename.
SELECT m.full_name, count(*) AS matches
FROM members m
JOIN matches x ON m.id IN (x.team1_player1, x.team1_player2,
                           x.team2_player1, x.team2_player2)
WHERE m.full_name IN ('Johnson', 'Jonson')
GROUP BY m.full_name ORDER BY m.full_name;
