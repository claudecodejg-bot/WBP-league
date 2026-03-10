-- =============================================
--  Paddle Tennis League — Supabase Database Setup
--  Run each block in the Supabase SQL Editor
--  (supabase.com → your project → SQL Editor)
-- =============================================


-- =============================================
--  STEP 1: Create Tables
-- =============================================

CREATE TABLE members (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id    uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
  full_name  text NOT NULL,
  email      text NOT NULL UNIQUE,
  is_guest   boolean NOT NULL DEFAULT false,  -- true = fill-in guest (never a season member)
  is_admin   boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Tracks which seasons each member was officially active (played ≥1 match as a season member).
-- Populated by member-seasons.sql after running merge-players.sql.
CREATE TABLE member_seasons (
  id        uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id uuid NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  season    text NOT NULL,
  UNIQUE(member_id, season)
);

CREATE TABLE matches (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  played_on       date NOT NULL,
  week_label      text NOT NULL,
  team1_player1   uuid NOT NULL REFERENCES members(id),
  team1_player2   uuid NOT NULL REFERENCES members(id),
  team2_player1   uuid NOT NULL REFERENCES members(id),
  team2_player2   uuid NOT NULL REFERENCES members(id),
  -- Set scores: games won by each team per set
  -- A win = exactly 2 set scores equal 6
  team1_set1      integer NOT NULL CHECK (team1_set1 BETWEEN 0 AND 7),
  team1_set2      integer NOT NULL CHECK (team1_set2 BETWEEN 0 AND 7),
  team1_set3      integer         CHECK (team1_set3 BETWEEN 0 AND 7),
  team2_set1      integer NOT NULL CHECK (team2_set1 BETWEEN 0 AND 7),
  team2_set2      integer NOT NULL CHECK (team2_set2 BETWEEN 0 AND 7),
  team2_set3      integer         CHECK (team2_set3 BETWEEN 0 AND 7),
  created_at      timestamptz DEFAULT now()
);

CREATE TABLE availability (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id     uuid NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  week_start    date NOT NULL,
  is_available  boolean NOT NULL DEFAULT true,
  note          text,
  created_at    timestamptz DEFAULT now(),
  UNIQUE (member_id, week_start)
);


-- =============================================
--  STEP 2: Enable Row Level Security
-- =============================================

ALTER TABLE members        ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches         ENABLE ROW LEVEL SECURITY;
ALTER TABLE availability    ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_seasons  ENABLE ROW LEVEL SECURITY;


-- =============================================
--  STEP 3: RLS Policies
-- =============================================

-- MATCHES: anyone can read (standings & results are public)
CREATE POLICY "Public can read matches"
  ON matches FOR SELECT USING (true);

-- MATCHES: only admins can insert / update / delete
CREATE POLICY "Admins manage matches"
  ON matches FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM members
      WHERE auth_id = auth.uid() AND is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM members
      WHERE auth_id = auth.uid() AND is_admin = true
    )
  );

-- MEMBERS: logged-in users can read all members (needed for player name lookups)
CREATE POLICY "Logged-in users can read members"
  ON members FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- MEMBERS: only admins can write
CREATE POLICY "Admins manage members"
  ON members FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM members
      WHERE auth_id = auth.uid() AND is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM members
      WHERE auth_id = auth.uid() AND is_admin = true
    )
  );

-- AVAILABILITY: logged-in users can read all (admin needs full overview)
CREATE POLICY "Logged-in users can read availability"
  ON availability FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- MEMBER_SEASONS: anyone can read
CREATE POLICY "Anyone can read member_seasons"
  ON member_seasons FOR SELECT USING (true);

-- AVAILABILITY: members can only write their own rows
CREATE POLICY "Members manage own availability"
  ON availability FOR ALL
  USING (
    member_id = (
      SELECT id FROM members WHERE auth_id = auth.uid()
    )
  )
  WITH CHECK (
    member_id = (
      SELECT id FROM members WHERE auth_id = auth.uid()
    )
  );


-- =============================================
--  STEP 4: Insert your 16 members
--
--  IMPORTANT: First invite each member via
--  Supabase → Authentication → Users → Invite
--  Then copy the UUID shown for each user and
--  paste it in the auth_id column below.
--
--  Replace all values with your real league members.
--  The first row is marked is_admin = true — that
--  should be YOUR account.
-- =============================================

INSERT INTO members (auth_id, full_name, email, is_admin) VALUES
  ('REPLACE-WITH-YOUR-AUTH-UUID',        'Your Name (Admin)',  'you@example.com',      true),
  ('REPLACE-WITH-MEMBER-2-AUTH-UUID',    'Member Two',         'member2@example.com',  false),
  ('REPLACE-WITH-MEMBER-3-AUTH-UUID',    'Member Three',       'member3@example.com',  false),
  ('REPLACE-WITH-MEMBER-4-AUTH-UUID',    'Member Four',        'member4@example.com',  false),
  ('REPLACE-WITH-MEMBER-5-AUTH-UUID',    'Member Five',        'member5@example.com',  false),
  ('REPLACE-WITH-MEMBER-6-AUTH-UUID',    'Member Six',         'member6@example.com',  false),
  ('REPLACE-WITH-MEMBER-7-AUTH-UUID',    'Member Seven',       'member7@example.com',  false),
  ('REPLACE-WITH-MEMBER-8-AUTH-UUID',    'Member Eight',       'member8@example.com',  false),
  ('REPLACE-WITH-MEMBER-9-AUTH-UUID',    'Member Nine',        'member9@example.com',  false),
  ('REPLACE-WITH-MEMBER-10-AUTH-UUID',   'Member Ten',         'member10@example.com', false),
  ('REPLACE-WITH-MEMBER-11-AUTH-UUID',   'Member Eleven',      'member11@example.com', false),
  ('REPLACE-WITH-MEMBER-12-AUTH-UUID',   'Member Twelve',      'member12@example.com', false),
  ('REPLACE-WITH-MEMBER-13-AUTH-UUID',   'Member Thirteen',    'member13@example.com', false),
  ('REPLACE-WITH-MEMBER-14-AUTH-UUID',   'Member Fourteen',    'member14@example.com', false),
  ('REPLACE-WITH-MEMBER-15-AUTH-UUID',   'Member Fifteen',     'member15@example.com', false),
  ('REPLACE-WITH-MEMBER-16-AUTH-UUID',   'Member Sixteen',     'member16@example.com', false);
