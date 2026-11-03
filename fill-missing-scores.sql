-- =====================================================================
--  The 24 unscored matches, settled
--
--  Grills went back through the spreadsheets. 15 scores were found; the
--  other 9 were rained out or never scored and are removed.
--
--  All 15 were checked against the entry rules the site now enforces
--  before this file was written, and each match id was confirmed against
--  its four players rather than its position in the list.
--
--  After this there are no unscored matches left in 19 seasons.
--
--  Run as admin in the Supabase SQL editor. Safe to re-run.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
--  SCORES RECOVERED (15)
-- ---------------------------------------------------------------------

-- 2014-03-25  Kelsey & Richards vs Nix & Cortellesi
--   4-6 6-1 7-6
UPDATE matches SET
  team1_set1 = 4, team2_set1 = 6,
  team1_set2 = 6, team2_set2 = 1,
  team1_set3 = 7, team2_set3 = 6
WHERE id = 'a04b6578-3b89-4021-8133-361720d8aefd';

-- 2019-03-19  Grills & Luecke vs McGurren & Napolitano
--   6-2 7-5
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 2,
  team1_set2 = 7, team2_set2 = 5,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = 'e08169d7-43d6-48b5-a43c-428a3ae39387';

-- 2019-03-19  Dolcetti & Richards vs Rockman & Walsh
--   3-6 7-6 6-4
UPDATE matches SET
  team1_set1 = 3, team2_set1 = 6,
  team1_set2 = 7, team2_set2 = 6,
  team1_set3 = 6, team2_set3 = 4
WHERE id = 'eb277bec-8460-492c-a609-2c12c88b1cff';

-- 2020-12-09  D'Acunto & Baum vs Brown & Jonson
--   6-1 6-3
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 1,
  team1_set2 = 6, team2_set2 = 3,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = '9f605551-1831-47e2-810f-853a4fd199ea';

-- 2020-12-09  Adams & Rockman vs Dolcetti & Ridder
--   4-6 6-4 6-3
UPDATE matches SET
  team1_set1 = 4, team2_set1 = 6,
  team1_set2 = 6, team2_set2 = 4,
  team1_set3 = 6, team2_set3 = 3
WHERE id = '6235656f-fee5-4a5c-9766-48f258936343';

-- 2020-12-09  Dolan & Smith vs Grills & Luecke
--   7-6 4-6 6-2
UPDATE matches SET
  team1_set1 = 7, team2_set1 = 6,
  team1_set2 = 4, team2_set2 = 6,
  team1_set3 = 6, team2_set3 = 2
WHERE id = 'e619e0e5-78d0-44a6-9ef7-a61ed430f552';

-- 2020-12-16  Napolitano & Luecke vs Baum & Walsh
--   6-4 6-4
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 6, team2_set2 = 4,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = 'f2ea697b-4c50-4d9c-a546-5f70ebcede71';

-- 2021-01-13  D'Acunto & Rockman vs Napolitano & Grills
--   6-4 7-5
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 7, team2_set2 = 5,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = 'f7cb6914-727b-42d8-b89a-e53ae324546d';

-- 2021-01-13  Ridder & Tommy Nap vs Jonson & Baum
--   4-6 6-3 6-2
UPDATE matches SET
  team1_set1 = 4, team2_set1 = 6,
  team1_set2 = 6, team2_set2 = 3,
  team1_set3 = 6, team2_set3 = 2
WHERE id = '675ae068-adbf-43c1-82af-8193c5ec2f79';

-- 2021-01-13  Smith & Luecke vs McGurren & Walsh
--   6-2 6-3
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 2,
  team1_set2 = 6, team2_set2 = 3,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = '7371cfe2-b50c-4139-8fd1-5572aae504a6';

-- 2022-02-01  Rayhill & Grills vs D'Acunto & Brown
--   6-4 6-1
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 6, team2_set2 = 1,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = '59a8a5d0-93a0-417e-93ac-c96f0491c9c4';

-- 2022-02-01  Dolan & Walsh vs Baum & McGurren
--   6-4 7-5
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 7, team2_set2 = 5,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = '3bbb1d89-0e7f-4f95-8037-ed5faa486c17';

-- 2022-02-01  Jonson & Luecke vs Dolcetti & Adams
--   6-3 6-1
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 3,
  team1_set2 = 6, team2_set2 = 1,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = '6b23e9cf-46e3-46d2-a4be-28fc0a2624b0';

-- 2023-02-28  Rockman & McGurren vs Rayhill & Luecke
--   3-6 6-2 6-4
UPDATE matches SET
  team1_set1 = 3, team2_set1 = 6,
  team1_set2 = 6, team2_set2 = 2,
  team1_set3 = 6, team2_set3 = 4
WHERE id = '35bb1f7c-e690-4377-978b-f5d80d144cdc';

-- 2023-02-28  D'Acunto & Grills vs Dolan & Brown
--   6-4 6-4
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 6, team2_set2 = 4,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = '15f9d463-b166-4e2a-8d62-23065024bcc3';


-- ---------------------------------------------------------------------
--  NEVER PLAYED (9) -- rained out, or no score was ever kept
--
--  Removed rather than left blank. A scoreless row is not neutral: the
--  matchups and player pages count every row as a win or a loss, so each
--  one was showing as a loss for all four players.
-- ---------------------------------------------------------------------

-- 2014-11-25  2014-15 Week 6  D'Acunto & Brown vs Krantz & Nix  (rained out)
DELETE FROM matches WHERE id = 'bf32092c-47cf-40e4-aa1d-ff2441ea9e4c';

-- 2014-12-09  2014-15 Week 8  Coomaraswamy & Smith vs Brown & Richards  (rained out)
DELETE FROM matches WHERE id = '8619ec6d-5b42-4f61-b56c-0b8b5fbb14b9';

-- 2019-01-15  2018-19 Week 14  Krantz & Walsh vs McGurren & Jonson  (rained out)
DELETE FROM matches WHERE id = '39dd91a4-38f4-46f9-9ea7-d1b15ac35823';

-- 2020-11-04  2020-21 Week 3  Dolan & Napolitano vs Baum & Krantz  (no score)
DELETE FROM matches WHERE id = '43c7074e-4e4f-4db0-92aa-32e3cab47474';

-- 2020-11-25  2020-21 Week 6  Jonson & Ridder vs McGurren & Levine  (no score)
DELETE FROM matches WHERE id = '9316aeea-1295-44ef-9710-1707a15926ae';

-- 2021-01-06  2020-21 Week 12  Grills & Bartolatta vs Ridder & Baird  (no score)
DELETE FROM matches WHERE id = 'b606b0ee-2f25-418e-8453-ba6f6f28281d';

-- 2021-02-10  2020-21 Week 17  Tommy Nap & McGurren vs Napolitano & Jonson  (no score)
DELETE FROM matches WHERE id = '14dcfbb3-36b7-4336-b30a-7606549d1c97';

-- 2021-10-26  2021-22 Week 2  Dolan & Walsh vs Dickson & McGurren  (no score)
DELETE FROM matches WHERE id = '44a792ad-0761-4aad-a5dc-bc7c1fe02119';

-- 2023-02-28  2022-23 Week 20  Jonson & Napolitano vs Ridder & Adams  (no score)
DELETE FROM matches WHERE id = '89248ba7-489e-4715-bf4c-1bbdab7f2291';


commit;

-- ---------------------------------------------------------------------
--  VERIFY -- run after the COMMIT
-- ---------------------------------------------------------------------

-- 1. Nine rows gone.
select count(*) as matches_remaining from matches;
-- Expect 794 (was 803).

-- 2. Nothing unscored left anywhere, in any season.
select count(*) as unscored from matches
 where team1_set1 is null and team2_set1 is null
   and team1_set2 is null and team2_set2 is null
   and team1_set3 is null and team2_set3 is null;
-- Expect 0. It was 24.

-- 3. The three nights that were missing entirely now have three courts each.
select played_on, count(*) as courts
  from matches
 where played_on in ('2020-12-09', '2021-01-13', '2022-02-01')
 group by played_on order by played_on;
-- Expect 3, 3, 3.
