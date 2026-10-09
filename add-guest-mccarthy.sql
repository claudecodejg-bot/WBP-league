-- =====================================================================
--  Add McCarthy as a guest (sub)
--  Run in the Supabase SQL editor: Dashboard → SQL Editor → New query.
--
--  Guests are fill-ins: they can play and appear in results, but they are
--  not season members, so they don't appear in the standings Members table.
--  Baird already exists as a former member and needs nothing.
--
--  Safe to run more than once — it does nothing if McCarthy already exists.
-- =====================================================================

INSERT INTO members (full_name, email, is_guest)
SELECT 'McCarthy', 'mccarthy@historical.local', true
WHERE NOT EXISTS (
  SELECT 1 FROM members WHERE full_name = 'McCarthy'
);

-- Verify: expect one row, is_guest = true
SELECT full_name, is_guest FROM members WHERE full_name IN ('McCarthy', 'Baird') ORDER BY full_name;

-- =====================================================================
--  Housekeeping: remove the empty duplicate "Smith"
--
--  There are two members named Smith. One is the real player (176 matches,
--  on the roster since 2003-04). The other has no matches, no roster rows —
--  an empty duplicate that would otherwise appear in the scheduler's subs
--  list as a confusing second "Smith".
--
--  The delete is guarded: it only removes a Smith record that is referenced
--  by nothing at all, so the real player can never be touched.
-- =====================================================================

DELETE FROM members m
WHERE m.full_name = 'Smith'
  AND NOT EXISTS (SELECT 1 FROM member_seasons ms WHERE ms.member_id = m.id)
  AND NOT EXISTS (SELECT 1 FROM availability a   WHERE a.member_id  = m.id)
  AND NOT EXISTS (
    SELECT 1 FROM matches x
    WHERE m.id IN (x.team1_player1, x.team1_player2, x.team2_player1, x.team2_player2)
  );

-- Verify: expect exactly one Smith left, and McCarthy present
SELECT full_name, is_guest FROM members
WHERE full_name IN ('Smith', 'McCarthy', 'Baird')
ORDER BY full_name;
