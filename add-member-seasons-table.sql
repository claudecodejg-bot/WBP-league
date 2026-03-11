-- =============================================
-- add-member-seasons-table.sql
-- Migration: adds the member_seasons table to an existing database.
-- Run this ONCE in the Supabase SQL editor, then run member-seasons.sql.
-- (Do NOT re-run setup.sql — your tables already exist.)
-- =============================================

-- 1. Create the table
CREATE TABLE IF NOT EXISTS member_seasons (
  id        uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id uuid NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  season    text NOT NULL,
  UNIQUE(member_id, season)
);

-- 2. Enable RLS
ALTER TABLE member_seasons ENABLE ROW LEVEL SECURITY;

-- 3. Allow anyone to read (same pattern as matches)
CREATE POLICY "Anyone can read member_seasons"
  ON member_seasons FOR SELECT USING (true);
