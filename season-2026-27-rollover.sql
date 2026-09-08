-- =====================================================================
--  2026-27 season rollover
--  Run this in the Supabase SQL editor (Dashboard → SQL Editor → New query).
--
--  Everyone from 2025-26 returns, plus Rockman, who sat out last season
--  with an injury. That makes 16 members for 2026-27.
--
--  Safe to run more than once: it skips anyone already recorded for the
--  season, so a second run inserts nothing.
-- =====================================================================

INSERT INTO member_seasons (member_id, season)
SELECT m.id, '2026-27'
FROM members m
WHERE
  -- last season's roster
  (
    m.id IN (SELECT member_id FROM member_seasons WHERE season = '2025-26')
    -- ...plus Rockman, returning after a year out
    OR m.full_name = 'Rockman'
  )
  AND m.is_guest = false
  -- don't duplicate anyone already recorded for 2026-27
  AND NOT EXISTS (
    SELECT 1 FROM member_seasons ms
    WHERE ms.member_id = m.id AND ms.season = '2026-27'
  );

-- ── Verify: expect 16 rows, including Rockman ───────────────────────
SELECT m.full_name
FROM member_seasons ms
JOIN members m ON m.id = ms.member_id
WHERE ms.season = '2026-27'
ORDER BY m.full_name;

SELECT COUNT(*) AS members_2026_27
FROM member_seasons
WHERE season = '2026-27';
