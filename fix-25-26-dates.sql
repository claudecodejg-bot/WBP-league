-- Fix 2025-26 season match dates — sets exact dates per week (idempotent)
-- Week 1 = Oct 27 2025, weekly from there. Week 17 was skipped (no matches).
UPDATE matches
SET played_on = CASE week_label
  WHEN 'Week 1'  THEN '2025-10-27'::date
  WHEN 'Week 2'  THEN '2025-11-03'::date
  WHEN 'Week 3'  THEN '2025-11-10'::date
  WHEN 'Week 4'  THEN '2025-11-17'::date
  WHEN 'Week 5'  THEN '2025-11-24'::date
  WHEN 'Week 6'  THEN '2025-12-01'::date
  WHEN 'Week 7'  THEN '2025-12-08'::date
  WHEN 'Week 8'  THEN '2025-12-15'::date
  WHEN 'Week 9'  THEN '2025-12-22'::date
  WHEN 'Week 10' THEN '2025-12-29'::date
  WHEN 'Week 11' THEN '2026-01-05'::date
  WHEN 'Week 12' THEN '2026-01-12'::date
  WHEN 'Week 13' THEN '2026-01-19'::date
  WHEN 'Week 14' THEN '2026-01-26'::date
  WHEN 'Week 15' THEN '2026-02-02'::date
  WHEN 'Week 16' THEN '2026-02-09'::date
  WHEN 'Week 18' THEN '2026-02-23'::date
  WHEN 'Week 19' THEN '2026-03-03'::date
  WHEN 'Week 20' THEN '2026-03-10'::date
END
WHERE season = '2025-26';
