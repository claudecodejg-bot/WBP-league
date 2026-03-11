-- =============================================
-- member-seasons.sql
-- Run AFTER add-member-seasons-table.sql and merge-players.sql.
-- Populates member_seasons from the 'Current Rank - Full Year'
-- scoring tab of each season (outings > 0 = active member).
-- Season labels match matches.season format: '2006-07', '2025-26', etc.
-- Safe to re-run: TRUNCATE clears previous data first.
-- =============================================

TRUNCATE member_seasons;

-- === Season 2006-07 (12 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Zejda, M.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Lynch') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Laird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('DeGulis') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Simpson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Johnson, S.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2006-07' FROM members WHERE LOWER(full_name) = LOWER('Weibel') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2007-08 (12 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Lynch') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Zejda, M.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Zejda, D.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Simpson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Johnson, S.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2007-08' FROM members WHERE LOWER(full_name) = LOWER('Laird') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2008-09 (12 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Lynch') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Simpson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Laird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Johnson, S.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2008-09' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2009-10 (12 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Lynch') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Simpson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Laird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Schwarz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2009-10' FROM members WHERE LOWER(full_name) = LOWER('Johnson, S.') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2010-11 (18 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Ramsay') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Simpson') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Schwarz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Stockton') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Baurmeister') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Lindenberg') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Johnson, S.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2010-11' FROM members WHERE LOWER(full_name) = LOWER('Weibel') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2011-12 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Ramsay') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Lindenberg') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Schwarz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2011-12' FROM members WHERE LOWER(full_name) = LOWER('Bowman') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2012-13 (14 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Lindenberg') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Ramsay') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2012-13' FROM members WHERE LOWER(full_name) = LOWER('Bowman') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2013-14 (14 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Kelsey') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Eglin') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2013-14' FROM members WHERE LOWER(full_name) = LOWER('Cortellesi') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2014-15 (11 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('Krantz') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2014-15' FROM members WHERE LOWER(full_name) = LOWER('Kelsey') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2015-16 (11 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('Raker') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2015-16' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2016-17 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2016-17' FROM members WHERE LOWER(full_name) = LOWER('Coomaraswamy') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2017-18 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Richards') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Baird') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2017-18' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2018-19 (14 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2018-19' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2019-20 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2019-20' FROM members WHERE LOWER(full_name) = LOWER('Nix') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2020-21 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2020-21' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2021-22 (16 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Rayhill') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2021-22' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2022-23 (16 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Rayhill') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2022-23' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2023-24 (16 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Rayhill') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2023-24' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2024-25 (17 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Rockman') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Rayhill') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Romano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2024-25' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;

-- === Season 2025-26 (15 active members) ===
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Grills') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Smith') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('D''Acunto') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Adams') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Jonson, R.') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Dolan') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Rayhill') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Brown') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Ridder') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Baum') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Napolitano') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('McGurren') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Luecke') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Dolcetti') LIMIT 1 ON CONFLICT DO NOTHING;
INSERT INTO member_seasons (member_id, season) SELECT id, '2025-26' FROM members WHERE LOWER(full_name) = LOWER('Walsh') LIMIT 1 ON CONFLICT DO NOTHING;

-- 285 member-season records across 20 seasons.
