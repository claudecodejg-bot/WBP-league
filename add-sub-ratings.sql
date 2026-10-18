-- =====================================================================
--  Sub ratings — so fill-ins can be paired sensibly
--
--  The scheduler balances courts on each player's season average. A sub
--  has no season average, so js/scheduler.js fell back to a hard-coded
--  5 — dead average — and paired them as if every sub were mid-table.
--
--  This adds a rating you set by hand, on the same scale as a season
--  average, used only when the player has no season average of their own.
--  A sub who later becomes a season member is scored on their real
--  results automatically; the rating just stops being consulted.
--
--  Also adds Song, who is subbing this week and was not in the system.
--  Moyers is already there as a guest.
--
--  Run in the Supabase SQL editor. Safe to re-run.
-- =====================================================================

ALTER TABLE members ADD COLUMN IF NOT EXISTS sub_rating numeric;

COMMENT ON COLUMN members.sub_rating IS
  'Admin-set strength on the season-average scale, used by the scheduler '
  'only when the player has no season average. Null means unrated.';

-- Song: a fill-in, so a guest — plays and appears in results, but stays
-- out of the standings Members table and off the season roster.
INSERT INTO members (full_name, email, is_guest)
SELECT 'Song', 'song@historical.local', true
WHERE NOT EXISTS (
  SELECT 1 FROM members WHERE full_name = 'Song'
);

-- The publishable key needs to read the new column, or the scheduler
-- cannot see ratings. It is not sensitive — it is a number, and every
-- season average is already public on the standings page.
GRANT SELECT (id, full_name, is_guest, sub_rating) ON members TO anon;

-- Verify: expect Song and Moyers, both guests, sub_rating null for now.
SELECT full_name, is_guest, sub_rating
FROM members
WHERE full_name IN ('Song', 'Moyers')
ORDER BY full_name;
