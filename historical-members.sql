-- =============================================
-- historical-members.sql
-- Run FIRST in Supabase SQL editor.
-- Adds any historical players not in current roster.
-- =============================================

INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Murat', 'murat@historical.local', true, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Romano', 'romano@historical.local', true, false) ON CONFLICT DO NOTHING;

-- 2 new historical member(s) added as guests.