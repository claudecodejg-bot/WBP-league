-- =====================================================================
--  D'Acunto -> djflmatt22@gmail.com
--
--  The dashboard has no edit-email field, so the auth account is deleted
--  and remade. His history is safe: matches, availability and standings
--  all hang off members.id, not off the auth account.
--
--  Run the steps in order, in the Supabase SQL editor.
-- =====================================================================


-- ---------------------------------------------------------------------
--  STEP 1 — SAFETY CHECK. Run this BEFORE deleting anything.
--
--  Deleting the auth user is only safe if the foreign key nulls auth_id
--  rather than cascading. setup.sql says SET NULL, but the live database
--  has drifted from it before, so confirm against the live database.
--
--  Expect: delete_rule = SET NULL  ->  safe, carry on.
--  If it says CASCADE, STOP — deleting the user would delete his member
--  row and orphan his match history. Use the Admin API route instead.
-- ---------------------------------------------------------------------
SELECT tc.constraint_name, rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.referential_constraints rc
  ON rc.constraint_name = tc.constraint_name
JOIN information_schema.key_column_usage kcu
  ON kcu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'members'
  AND kcu.column_name = 'auth_id';


-- ---------------------------------------------------------------------
--  STEP 2 — in the DASHBOARD, not here:
--    Authentication -> Users -> his row -> Delete user
--    Authentication -> Users -> Add User
--      email: djflmatt22@gmail.com
--      tick "Auto Confirm User", set any password
-- ---------------------------------------------------------------------


-- ---------------------------------------------------------------------
--  STEP 3 — point the member row at the new address and the new account.
-- ---------------------------------------------------------------------
UPDATE members m
SET email   = 'djflmatt22@gmail.com',
    auth_id = (SELECT id FROM auth.users WHERE LOWER(email) = 'djflmatt22@gmail.com')
WHERE m.full_name = 'D''Acunto';


-- ---------------------------------------------------------------------
--  STEP 4 — verify. Expect one row, has_login = true, matches = true.
--  has_login = false means the Add User step did not land.
-- ---------------------------------------------------------------------
SELECT m.full_name,
       m.email,
       (m.auth_id IS NOT NULL)                AS has_login,
       LOWER(m.email) = LOWER(u.email)        AS matches
FROM members m
LEFT JOIN auth.users u ON u.id = m.auth_id
WHERE m.full_name = 'D''Acunto';

-- Sanity: his match count should be unchanged by all of this.
SELECT count(*) AS matches_on_record
FROM matches x
WHERE (SELECT id FROM members WHERE full_name = 'D''Acunto')
      IN (x.team1_player1, x.team1_player2, x.team2_player1, x.team2_player2);
