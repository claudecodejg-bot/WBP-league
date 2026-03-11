-- Fix 2025-26 season match dates (all were off by +1 year)
-- Before: 2026-10-27 → After: 2025-10-27
-- Before: 2027-03-03 → After: 2026-03-03
UPDATE matches
SET played_on = (played_on - INTERVAL '1 year')::date
WHERE season = '2025-26';
