-- =============================================
-- member-seasons.sql
-- Run AFTER merge-players.sql.
-- Creates the member_seasons table and populates it from
-- the 'Current Rank - Full Year' scoring tab of each season,
-- counting only players who actually played (outings > 0).
-- =============================================

-- 1. Create table
CREATE TABLE IF NOT EXISTS member_seasons (
  id        UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  season    TEXT NOT NULL,
  UNIQUE(member_id, season)
);

ALTER TABLE member_seasons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read member_seasons"
  ON member_seasons FOR SELECT USING (true);

-- 2. Clear any previous data
TRUNCATE member_seasons;

-- === Season 06-07 (12 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('M. Zejda') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('Lynch') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('Laird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('DeGulis') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('Simpson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('S. Johnson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '06-07' FROM members WHERE LOWER(full_name) = LOWER('Weibel') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 07-08 (12 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('Lynch') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('M. Zejda') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('D. Zejda') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('Simpson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('S. Johnson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '07-08' FROM members WHERE LOWER(full_name) = LOWER('Laird') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 08-09 (12 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('Lynch') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('Simpson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('Laird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('S. Johnson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '08-09' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 09-10 (12 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('Lynch') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('Simpson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('Laird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('Schwarz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '09-10' FROM members WHERE LOWER(full_name) = LOWER('S. Johnson') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 10-11 (18 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Ramsay') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Simpson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Schwarz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Stockton') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Baurmeister') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Lindenberg') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('S. Johnson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '10-11' FROM members WHERE LOWER(full_name) = LOWER('Weibel') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 11-12 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Ramsay') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Lindenberg') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Schwarz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '11-12' FROM members WHERE LOWER(full_name) = LOWER('Bowman') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 12-13 (14 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Lindenberg') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Ramsay') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '12-13' FROM members WHERE LOWER(full_name) = LOWER('Bowman') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 13-14 (14 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Kelsey') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '13-14' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 14-15 (11 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '14-15' FROM members WHERE LOWER(full_name) = LOWER('Kelsey') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 15-16 (11 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '15-16' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 16-17 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '16-17' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 17-18 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '17-18' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 18-19 (14 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '18-19' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 19-20 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '19-20' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 20-21 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '20-21' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 21-22 (16 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Rayhill') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '21-22' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 22-23 (16 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Rayhill') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '22-23' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 23-24 (16 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Rayhill') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '23-24' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 24-25 (17 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Rayhill') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Romano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '24-25' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 25-26 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('R. Jonson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Rayhill') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '25-26' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- 285 member-season records across 20 seasons.
