-- =====================================================================
--  Monday 12 October 2026 — Drake subs in for Walsh
--
--  Walsh pulled out of the season opener. Drake fills the slot on
--  Court 3 alongside Dolcetti. Comparable player, straight swap, so the
--  other two courts are left exactly as they were.
--
--  Run in the Supabase SQL editor: Dashboard -> SQL Editor -> New query.
--  Safe to run more than once.
-- =====================================================================

-- 1. Drake is a fill-in, not a season member, so he goes in as a guest.
--    Guests can play and appear in results, but stay out of the
--    standings Members table and out of member_seasons.
INSERT INTO members (full_name, email, is_guest)
SELECT 'Drake', 'drake@historical.local', true
WHERE NOT EXISTS (
  SELECT 1 FROM members WHERE full_name = 'Drake'
);

-- 2. Swap the name on tonight's saved schedule. courts is jsonb holding
--    plain names, so this is a string replace. Scoped to the one date,
--    and only touches a row that still says Walsh.
UPDATE scheduled_matches
SET courts = REPLACE(courts::text, '"Walsh"', '"Drake"')::jsonb
WHERE played_on = '2026-10-12'
  AND courts::text LIKE '%"Walsh"%';

-- 3. Housekeeping: Walsh said yes for tonight, so the availability tally
--    still counts him. Flip him to unavailable so the page matches
--    reality. Only updates a row that already exists.
UPDATE availability
SET is_available = false
WHERE week_start = '2026-10-12'
  AND member_id = (SELECT id FROM members WHERE full_name = 'Walsh');

-- Verify: expect Drake on Court 3 with Dolcetti, Walsh gone,
--         and the other two courts untouched.
SELECT jsonb_pretty(courts) AS courts
FROM scheduled_matches
WHERE played_on = '2026-10-12';

SELECT full_name, is_guest FROM members
WHERE full_name IN ('Drake', 'Walsh') ORDER BY full_name;
