-- =============================================
-- Migration: Add season column to matches table
-- Run this in the Supabase SQL editor ONCE,
-- then run historical-data.sql for prior seasons.
-- =============================================

-- 1. Add season column (defaults to current season for all existing rows)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS season TEXT NOT NULL DEFAULT '2025-26';

-- 2. Ensure all existing matches are tagged as current season
UPDATE matches SET season = '2025-26' WHERE season IS NULL OR season = '';

-- 3. Add an index for fast season-filtered queries
CREATE INDEX IF NOT EXISTS matches_season_idx ON matches (season);
