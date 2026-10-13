-- =====================================================================
--  Vinny's Award
--
--  Tracks who went out to Vinny's after a match night. One row per
--  member per night, so a season tally is just a count, and a night can
--  be corrected by clearing it and re-saving.
--
--  Attendance is not limited to people who played: anyone on the member
--  list can be marked, since a member who sat out can still turn up.
--
--  Run once in the Supabase SQL editor. Safe to run more than once.
-- =====================================================================

CREATE TABLE IF NOT EXISTS vinnys (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  played_on  date NOT NULL,
  member_id  uuid NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (played_on, member_id)
);

-- Tallies either filter by night or group by member.
CREATE INDEX IF NOT EXISTS vinnys_played_on_idx ON vinnys (played_on);
CREATE INDEX IF NOT EXISTS vinnys_member_id_idx ON vinnys (member_id);

ALTER TABLE vinnys ENABLE ROW LEVEL SECURITY;

-- Public read: the award shows on the standings and home pages, which
-- are readable signed out, same as results.
DROP POLICY IF EXISTS "Public can read vinnys" ON vinnys;
CREATE POLICY "Public can read vinnys"
  ON vinnys FOR SELECT USING (true);

-- Only an admin records attendance.
DROP POLICY IF EXISTS "Admins manage vinnys" ON vinnys;
CREATE POLICY "Admins manage vinnys"
  ON vinnys FOR ALL
  USING (public.auth_is_admin()) WITH CHECK (public.auth_is_admin());

-- Verify: expect the table, both policies, and an empty count.
SELECT count(*) AS vinnys_rows FROM vinnys;
SELECT policyname FROM pg_policies WHERE tablename = 'vinnys' ORDER BY policyname;
