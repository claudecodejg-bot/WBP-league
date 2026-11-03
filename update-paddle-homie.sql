-- =====================================================================
--  Paddle Homie — read recorded totals, and stop inventing them
--
--  Two changes.
--
--  1. A season with totals in season_awards returns those.
--
--  2. The attendance fallback is scoped to a season that has some
--     availability recorded. It was written for weeks 1 and 2 of the
--     current season, before anyone had used the form: a night nobody
--     answered for credits whoever took a court, which is fair over one
--     or two weeks.
--
--     Applied to a season with no availability at all, every night fell
--     through it, and the award silently became "nights played" -- the
--     opposite of what it is for, since someone available all season who
--     kept getting rested would score lowest. 2024-25 matched nights
--     played exactly, for all 16 players.
--
--     Now a season with no availability and no recorded totals returns
--     nothing, and the page shows no award for it.
--
--  Run add-season-awards.sql first. Safe to re-run.
-- =====================================================================

DROP FUNCTION IF EXISTS public.paddle_homie(text);

CREATE FUNCTION public.paddle_homie(p_season text)
RETURNS TABLE (member_id uuid, weeks_available int)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  WITH recorded AS (
    -- Years before the availability table: totals kept by hand.
    SELECT a.member_id, a.homie_weeks::int AS weeks_available
    FROM season_awards a
    WHERE a.season = p_season AND a.homie_weeks IS NOT NULL
  ),
  has_availability AS (
    -- Did anyone answer the form at all in this season?
    SELECT EXISTS (
      SELECT 1 FROM availability av
      JOIN matches mt ON mt.played_on = av.week_start AND mt.season = p_season
    ) AS yes
  ),
  weeks AS (
    SELECT DISTINCT played_on AS wk FROM matches WHERE season = p_season
  ),
  avail AS (
    SELECT a.week_start AS wk, a.member_id
    FROM availability a
    WHERE a.is_available = true
      AND a.week_start IN (SELECT wk FROM weeks)
  ),
  answered AS (
    SELECT DISTINCT wk FROM avail
  ),
  played AS (
    -- Only for a season that has availability data: a single unanswered
    -- night inside it credits whoever played that night.
    SELECT m.played_on AS wk, p.pid AS member_id
    FROM matches m
    CROSS JOIN LATERAL (VALUES (m.team1_player1), (m.team1_player2),
                               (m.team2_player1), (m.team2_player2)) AS p(pid)
    WHERE m.season = p_season
      AND p.pid IS NOT NULL
      AND m.played_on NOT IN (SELECT wk FROM answered)
      AND (SELECT yes FROM has_availability)
  ),
  credited AS (
    SELECT wk, member_id FROM avail
    UNION
    SELECT wk, member_id FROM played
  ),
  live AS (
    SELECT c.member_id, count(DISTINCT c.wk)::int AS weeks_available
    FROM credited c
    JOIN members mem ON mem.id = c.member_id AND mem.is_guest = false
    JOIN member_seasons ms ON ms.member_id = c.member_id AND ms.season = p_season
    GROUP BY c.member_id
  )
  -- Recorded totals win outright; live figures only where there are none.
  SELECT r.member_id, r.weeks_available FROM recorded r
  UNION ALL
  SELECT l.member_id, l.weeks_available FROM live l
  WHERE NOT EXISTS (SELECT 1 FROM recorded);
$$;

REVOKE ALL ON FUNCTION public.paddle_homie(text) FROM public;
GRANT EXECUTE ON FUNCTION public.paddle_homie(text) TO anon, authenticated;

-- ---------------------------------------------------------------------
--  VERIFY
-- ---------------------------------------------------------------------
-- A season with recorded totals:
SELECT m.full_name, h.weeks_available
  FROM public.paddle_homie('2024-25') h
  JOIN members m ON m.id = h.member_id
 ORDER BY h.weeks_available DESC, m.full_name;
-- Expect Ridder 20 at the top, and Romano present on 4.

-- A season with neither totals nor availability:
SELECT count(*) AS should_be_zero FROM public.paddle_homie('2022-23');

-- The live season, still computed from the form:
SELECT m.full_name, h.weeks_available
  FROM public.paddle_homie('2026-27') h
  JOIN members m ON m.id = h.member_id
 ORDER BY h.weeks_available DESC, m.full_name;
-- Ridder should still show one more week than he has played.
