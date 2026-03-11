-- =============================================
-- historical-members.sql
-- Run FIRST in Supabase SQL editor.
-- Adds guest players who appeared in matches but are not season members.
-- =============================================

INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Moyers', 'moyers@historical.local', true, false) ON CONFLICT DO NOTHING;
INSERT INTO members (full_name, email, is_guest, is_admin) VALUES ('Murat', 'murat@historical.local', true, false) ON CONFLICT DO NOTHING;

-- 2 guest(s) added: Moyers, Murat