-- Run this once in Supabase SQL Editor to add the scheduled_matches table

CREATE TABLE IF NOT EXISTS scheduled_matches (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_label  text NOT NULL,
  played_on   date NOT NULL UNIQUE,
  courts      jsonb NOT NULL,  -- [{team1: ['Name1','Name2'], team2: ['Name3','Name4']}, ...]
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE scheduled_matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read scheduled matches"
  ON scheduled_matches FOR SELECT USING (true);

CREATE POLICY "Admins manage scheduled matches"
  ON scheduled_matches FOR ALL
  USING  (EXISTS (SELECT 1 FROM members WHERE auth_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM members WHERE auth_id = auth.uid() AND is_admin = true));
