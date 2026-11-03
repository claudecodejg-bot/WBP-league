-- =====================================================================
--  Historical score corrections
--
--  Every match in 19 seasons that did not read as a finished result was
--  put to Grills, who said what should have been recorded. This applies
--  those answers: 18 matches corrected, 7 removed.
--
--  All 18 corrections were checked against the entry rules now enforced
--  on the site before this file was written.
--
--  Run as admin in the Supabase SQL editor. Safe to re-run -- every
--  statement is keyed on the match id.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
--  CORRECTIONS (18)
-- ---------------------------------------------------------------------

-- 2009-02-23  Richards & Eglin vs Laird & Cortellesi
--   0-6 7-5 4-1  ->  0-6 7-5 6-1
UPDATE matches SET
  team1_set1 = 0, team2_set1 = 6,
  team1_set2 = 7, team2_set2 = 5,
  team1_set3 = 6, team2_set3 = 1
WHERE id = '4f2c7c6a-f5e9-4067-bb0f-18fe2d97b011';

-- 2009-03-09  Baird & Krantz vs Johnson & Simpson
--   1-6 9-7 4-6  ->  1-6 7-5 4-6
UPDATE matches SET
  team1_set1 = 1, team2_set1 = 6,
  team1_set2 = 7, team2_set2 = 5,
  team1_set3 = 4, team2_set3 = 6
WHERE id = '5e1b62a1-baca-4807-a6bf-477c527f710b';

-- 2010-03-01  Grills & Schwarz vs Jonson & Richards
--   6-4 4-6 9-11  ->  6-4 4-6 6-7
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 4, team2_set2 = 6,
  team1_set3 = 6, team2_set3 = 7
WHERE id = '5b42084a-f8b0-4c50-a4a0-586e8e1af9f3';

-- 2011-01-31  Simpson & Cortellesi vs Grills & Krantz
--   0-6 7-6 2-5  ->  6-4 4-6 6-2
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 4, team2_set2 = 6,
  team1_set3 = 6, team2_set3 = 2
WHERE id = 'ffe202b8-6a0e-47a5-9a5d-b5812e4d644a';

-- 2017-12-12  Brown & Ridder vs McGurren & Adams
--   ?-5 ?-0  ->  7-5 6-0
UPDATE matches SET
  team1_set1 = 7, team2_set1 = 5,
  team1_set2 = 6, team2_set2 = 0,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = 'd7e913ad-415c-45b3-8d4a-f9e164f4da08';

-- 2019-02-05  Dolan & Dolcetti vs McGurren & Baum
--   6-? 6-?  ->  7-5 6-2
UPDATE matches SET
  team1_set1 = 7, team2_set1 = 5,
  team1_set2 = 6, team2_set2 = 2,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = 'a2dcdc68-cb84-4943-bb09-6625e8dfa0b7';

-- 2020-02-18  Dolan & Napolitano vs Ridder & Jonson
--   7-6 5-4  ->  7-6 6-4
UPDATE matches SET
  team1_set1 = 7, team2_set1 = 6,
  team1_set2 = 6, team2_set2 = 4,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = 'b3e90d47-3a1a-4b1c-aea8-292e69191026';

-- 2020-03-18  Ridder & Napolitano vs Rockman & McGurren
--   7-6 6-7 10-6  ->  7-6 6-7 7-6
UPDATE matches SET
  team1_set1 = 7, team2_set1 = 6,
  team1_set2 = 6, team2_set2 = 7,
  team1_set3 = 7, team2_set3 = 6
WHERE id = '4e1ab57e-9761-4e20-aa1a-db82b25e08b3';

-- 2020-03-25  Grills & Nix vs Jonson & Walsh
--   6-4 3-6 11-9  ->  6-4 3-6 7-6
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 3, team2_set2 = 6,
  team1_set3 = 7, team2_set3 = 6
WHERE id = '2ab6b01a-6927-4e07-a459-b95b903a6756';

-- 2020-10-21  Dolan & Rockman vs D'Acunto & Napolitano
--   3-? 6-? 7-?  ->  3-6 6-3 7-5
UPDATE matches SET
  team1_set1 = 3, team2_set1 = 6,
  team1_set2 = 6, team2_set2 = 3,
  team1_set3 = 7, team2_set3 = 5
WHERE id = '716d39e9-7abd-4d7a-b6b2-c831b30e2d4b';

-- 2020-12-16  D'Acunto & McGurren vs Grills & Dolcetti
--   ?-2 ?-4  ->  6-2 6-4
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 2,
  team1_set2 = 6, team2_set2 = 4,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = '886f3ca2-b89c-48cd-bd30-6a857918789f';

-- 2020-12-16  Rockman & Jonson vs Dolan & Ridder
--   7-? 6-?  ->  7-5 6-4
UPDATE matches SET
  team1_set1 = 7, team2_set1 = 5,
  team1_set2 = 6, team2_set2 = 4,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = 'dec7f8bf-0bf0-48bc-aef6-43d45634da72';

-- 2021-03-09  Rockman & McGurren vs Adams & Smith
--   6-4 6-6  ->  6-4 7-6
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 7, team2_set2 = 6,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = 'b989f551-57be-4633-8582-9b384633711b';

-- 2022-02-15  Jonson & Grills vs Ridder & D'Acunto
--   7-5 4-4 6-4  ->  7-5 4-6 6-4
UPDATE matches SET
  team1_set1 = 7, team2_set1 = 5,
  team1_set2 = 4, team2_set2 = 6,
  team1_set3 = 6, team2_set3 = 4
WHERE id = 'f274ca54-ee81-434b-8282-3fff5c741974';

-- 2022-11-08  Grills & Napolitano vs Dolan & Walsh
--   ?-6 ?-5  ->  7-6 7-5
UPDATE matches SET
  team1_set1 = 7, team2_set1 = 6,
  team1_set2 = 7, team2_set2 = 5,
  team1_set3 = NULL, team2_set3 = NULL
WHERE id = '724063a3-6ae5-4b49-a82d-c48ec3b7999f';

-- 2024-02-13  Adams & Jonson vs D'Acunto & Napolitano
--   5-? 6-? 7-?  ->  5-7 6-3 7-6
UPDATE matches SET
  team1_set1 = 5, team2_set1 = 7,
  team1_set2 = 6, team2_set2 = 3,
  team1_set3 = 7, team2_set3 = 6
WHERE id = 'e063b69e-7170-4b7a-941e-d3cb02aed9f9';

-- 2024-03-20  Dolan & Napolitano vs Dolcetti & Grills
--   6-4 66-7 ?-4  ->  6-4 6-7 6-4
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 6, team2_set2 = 7,
  team1_set3 = 6, team2_set3 = 4
WHERE id = '611490cf-f218-4697-a4eb-e4e480f4eecc';

-- 2024-10-16  Brown & Luecke vs Rayhill & Napolitano
--   7-4 6-7 6-3  ->  6-4 6-7 6-3
UPDATE matches SET
  team1_set1 = 6, team2_set1 = 4,
  team1_set2 = 6, team2_set2 = 7,
  team1_set3 = 6, team2_set3 = 3
WHERE id = '494d7568-b6e9-4a00-9d90-ac8005843be1';


-- ---------------------------------------------------------------------
--  REMOVALS (7) -- matches marked "incomplete, don't record"
--
--  Deleted outright rather than blanked. A row with no scores is not
--  neutral: the matchups page counts every row as a win or a loss, so a
--  blank one reads as a loss for all four players.
-- ---------------------------------------------------------------------

-- 2007-10-15  2007-08 Week 1  Zejda, D. & Johnson vs Richards & Smith  (6-3 4-6)
DELETE FROM matches WHERE id = '2fe1f9ef-0c93-412c-aaab-dc4bc59a2edf';

-- 2012-02-28  2011-12 Week 20  Brown & Bowman vs Krantz & Cortellesi  (5-7 6-4)
DELETE FROM matches WHERE id = 'f3f8abfc-9257-48c0-9651-dd6a86ecff95';

-- 2017-12-05  2017-18 Week 8  Jonson & Baird vs McGurren & Ridder  (6-4 3-6 4-4)
DELETE FROM matches WHERE id = 'f39c6675-161e-4560-9b87-b14393e53f78';

-- 2021-11-30  2021-22 Week 7  D'Acunto & Ridder vs Smith & Baum  (6-4 6-7)
DELETE FROM matches WHERE id = '1035bc5a-a8f0-4615-9b46-b173d0898182';

-- 2021-12-14  2021-22 Week 9  Smith & Napolitano vs Ridder & Brown  (6-2 2-2)
DELETE FROM matches WHERE id = 'ec282d77-1e4c-4afe-aef9-822a7996e40e';

-- 2024-01-09  2023-24 Week 13  Baum & Jonson vs McGurren & Smith  (6-7 7-6)
DELETE FROM matches WHERE id = '6fad02b2-ae22-4fc8-965e-be04c0215cf5';

-- 2024-03-06  2023-24 Week 21  D'Acunto & Napolitano vs Brown & Baum  (0-6 7-5 4-0)
DELETE FROM matches WHERE id = '365847f4-1edb-4b54-bcd5-11daa7c50ac1';


commit;

-- ---------------------------------------------------------------------
--  VERIFY -- run after the COMMIT
-- ---------------------------------------------------------------------

-- 1. Seven rows gone.
select count(*) as matches_remaining from matches;
-- Expect 803 (was 810).

-- 2. No score above 7 left anywhere.
select count(*) as scores_over_7 from matches
 where greatest(coalesce(team1_set1,0), coalesce(team2_set1,0),
                coalesce(team1_set2,0), coalesce(team2_set2,0),
                coalesce(team1_set3,0), coalesce(team2_set3,0)) > 7;
-- Expect 0. (The 66-7 and the four tiebreak scores are the only ones.)

-- 3. Spot-check the three that mattered most.
select played_on, week_label,
       team1_set1 || '-' || team2_set1 as set1,
       team1_set2 || '-' || team2_set2 as set2,
       coalesce(team1_set3 || '-' || team2_set3, '-') as set3
  from matches
 where id in ('611490cf-f218-4697-a4eb-e4e480f4eecc',
              '494d7568-b6e9-4a00-9d90-ac8005843be1',
              '4e1ab57e-9761-4e20-aa1a-db82b25e08b3')
 order by played_on;
-- Expect:
--   2020-03-18   7-6  6-7  7-6
--   2024-03-20   6-4  6-7  6-4
--   2024-10-16   6-4  6-7  6-3
