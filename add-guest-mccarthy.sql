-- =====================================================================
--  Add McCarthy as a guest (sub)
--  Run in the Supabase SQL editor: Dashboard → SQL Editor → New query.
--
--  Guests are fill-ins: they can play and appear in results, but they are
--  not season members, so they don't appear in the standings Members table.
--  Baird already exists as a former member and needs nothing.
--
--  Safe to run more than once — it does nothing if McCarthy already exists.
-- =====================================================================

INSERT INTO members (full_name, email, is_guest)
SELECT 'McCarthy', 'mccarthy@historical.local', true
WHERE NOT EXISTS (
  SELECT 1 FROM members WHERE full_name = 'McCarthy'
);

-- Verify: expect one row, is_guest = true
SELECT full_name, is_guest FROM members WHERE full_name IN ('McCarthy', 'Baird') ORDER BY full_name;
