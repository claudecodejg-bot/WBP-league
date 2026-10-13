-- =====================================================================
--  D'Acunto — change the email on the members table
--
--  There are TWO places an address lives, and they must both be changed:
--
--    1. auth.users  — what he signs in with and where reset mail goes.
--       Change this in the DASHBOARD, not here. Editing auth.users by
--       hand leaves GoTrue unable to read the account afterwards.
--       Dashboard -> Authentication -> Users -> find him -> ... -> edit.
--
--    2. members.email — what this script updates.
--
--  Run this AFTER the dashboard change, in the Supabase SQL editor.
--  Safe to run more than once.
-- =====================================================================

-- Matched on name rather than the old address, so you don't have to look
-- the old one up. The apostrophe is doubled — that is how SQL escapes it.
UPDATE members
SET email = 'djflmatt22@gmail.com'
WHERE full_name = 'D''Acunto';

-- Verify: expect one row, the new address, and auth_id still filled in.
-- A null auth_id would mean the login link is broken.
SELECT full_name, email, (auth_id IS NOT NULL) AS has_login
FROM members
WHERE full_name = 'D''Acunto';

-- Cross-check that members and auth.users now agree. Expect one row,
-- matches = true. If it says false, the dashboard step was missed.
SELECT m.full_name, m.email AS members_email, u.email AS auth_email,
       LOWER(m.email) = LOWER(u.email) AS matches
FROM members m
JOIN auth.users u ON u.id = m.auth_id
WHERE m.full_name = 'D''Acunto';
