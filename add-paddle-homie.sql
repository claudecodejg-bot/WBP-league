-- =====================================================================
--  Paddle Homie Award — who makes themselves available most
--
--  Counts the weeks a member said yes, whether or not they ended up on
--  a court. Someone who is available every Monday and gets rested, or
--  steps aside so others can play, should be recognised for it.
--
--  Why a function rather than a plain query: the standings page is
--  public, and the availability table is deliberately not. Members can
--  only read their own rows plus the coming week, and the publishable
--  key cannot read it at all. This runs as the definer and returns ONLY
--  totals per member — never who was available on which night — so the
--  award can be public without making anyone's answers public.
--
--  Rules:
--    * current-season members only; guests and former members excluded
--    * only weeks that have actually been played count
--    * a week with no availability responses at all falls back to
--      crediting everyone who played it, which is how weeks 1 and 2
--      are handled
--
--  Run in the Supabase SQL editor. Safe to re-run.
-- =====================================================================

DROP FUNCTION IF EXISTS public.paddle_homie(text);

CREATE FUNCTION public.paddle_homie(p_season text)
RETURNS TABLE (member_id uuid, weeks_available int)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  WITH weeks AS (
    -- Nights actually played this season.
    SELECT DISTINCT played_on AS wk FROM matches WHERE season = p_season
  ),
  avail AS (
    -- Everyone who said yes, for those nights.
    SELECT a.week_start AS wk, a.member_id
    FROM availability a
    WHERE a.is_available = true
      AND a.week_start IN (SELECT wk FROM weeks)
  ),
  answered AS (
    SELECT DISTINCT wk FROM avail
  ),
  played AS (
    -- Fallback for a night nobody answered for: whoever took a court was
    -- available by definition.
    SELECT m.played_on AS wk, p.pid AS member_id
    FROM matches m
    CROSS JOIN LATERAL (VALUES (m.team1_player1), (m.team1_player2),
                               (m.team2_player1), (m.team2_player2)) AS p(pid)
    WHERE m.season = p_season
      AND p.pid IS NOT NULL
      AND m.played_on NOT IN (SELECT wk FROM answered)
  ),
  credited AS (
    SELECT wk, member_id FROM avail
    UNION
    SELECT wk, member_id FROM played
  )
  SELECT c.member_id, count(DISTINCT c.wk)::int AS weeks_available
  FROM credited c
  JOIN members mem ON mem.id = c.member_id AND mem.is_guest = false
  JOIN member_seasons ms ON ms.member_id = c.member_id AND ms.season = p_season
  GROUP BY c.member_id;
$$;

-- Aggregates only, so this is safe to expose.
REVOKE ALL ON FUNCTION public.paddle_homie(text) FROM public;
GRANT EXECUTE ON FUNCTION public.paddle_homie(text) TO anon, authenticated;

-- Verify: expect one row per current member with a count.
SELECT m.full_name, h.weeks_available
FROM public.paddle_homie('2026-27') h
JOIN members m ON m.id = h.member_id
ORDER BY h.weeks_available DESC, m.full_name;
