-- =============================================
--  Load League Members
--  Run this BEFORE load-data.sql
--
--  auth_id and real emails can be added later:
--    UPDATE members SET auth_id = 'UUID-HERE', email = 'real@email.com'
--    WHERE full_name = 'LastName';
-- =============================================

INSERT INTO members (full_name, email) VALUES
  ('Ridder',     'ridder@pending.local'),
  ('Grills',     'grills@pending.local'),
  ('Adams',      'adams@pending.local'),
  ('Walsh',      'walsh@pending.local'),
  ('D''Acunto',  'dacunto@pending.local'),
  ('McGurren',   'mcgurren@pending.local'),
  ('Dolan',      'dolan@pending.local'),
  ('Luecke',     'luecke@pending.local'),
  ('Rayhill',    'rayhill@pending.local'),
  ('Brown',      'brown@pending.local'),
  ('Jonson',     'jonson@pending.local'),
  ('Smith',      'smith@pending.local'),
  ('Dolcetti',   'dolcetti@pending.local'),
  ('Napolitano', 'napolitano@pending.local'),
  ('Rockman',    'rockman@pending.local'),
  ('Baum',       'baum@pending.local')
ON CONFLICT (email) DO NOTHING;
