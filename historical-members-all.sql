-- =============================================
-- historical-members-all.sql
-- Run FIRST in Supabase SQL editor (before historical-data-all.sql).
--
-- is_guest = false → former season member (appeared in "Current Rank" scoring tab)
-- is_guest = true  → fill-in guest (appeared in match data only, never a season member)
-- =============================================

-- ── Former season members (is_guest = false) ──────────────────────────────
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Baird',       'baird@historical.local',       false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Baurmeister', 'baurmeister@historical.local', false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Cortellesi',  'cortellesi@historical.local',  false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('D Zejda',     'd.zejda@historical.local',     false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('DeGulis',     'degulis@historical.local',     false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Eglin',       'eglin@historical.local',       false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Grills',      'grills@historical.local',      false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Johnson',     'johnson@historical.local',     false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Krantz',      'krantz@historical.local',      false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Laird',       'laird@historical.local',       false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Lindenberg',  'lindenberg@historical.local',  false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Lynch',       'lynch@historical.local',       false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('M Zejda',     'm.zejda@historical.local',     false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Nix',         'nix@historical.local',         false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('R. Jonson',   'r..jonson@historical.local',   false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Raker',       'raker@historical.local',       false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Ramsay',      'ramsay@historical.local',      false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Richards',    'richards@historical.local',    false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('S. Johnson',  's..johnson@historical.local',  false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Schwarz',     'schwarz@historical.local',     false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Simpson',     'simpson@historical.local',     false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Smith',       'smith@historical.local',       false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Stockton',    'stockton@historical.local',    false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Weibel',      'weibel@historical.local',      false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Zedja Jr',    'zedja.jr@historical.local',    false, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Zejda',       'zejda@historical.local',       false, false) ON CONFLICT DO NOTHING;

-- ── Fill-in guests — appeared in match data only, never a season member ───
-- (never appeared in any season's "Current Rank - Full Year" scoring tab)
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Paret',       'paret@historical.local',       true,  false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Schmidt',     'schmidt@historical.local',     true,  false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Simon Scott', 'simon.scott@historical.local', true,  false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Yonce',       'yonce@historical.local',       true,  false) ON CONFLICT DO NOTHING;

-- 26 former members + 4 guests = 30 players total