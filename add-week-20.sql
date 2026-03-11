-- Week 20 results — March 9, 2026
-- Court 1: Grills & Ridder def. Dolan & Dolcetti 6-4, 3-6, 6-4
INSERT INTO matches (season, played_on, week_label, team1_player1, team1_player2, team2_player1, team2_player2, team1_set1, team1_set2, team1_set3, team2_set1, team2_set2, team2_set3)
VALUES (
  '2025-26',
  '2026-03-09'::date,
  'Week 20',
  (SELECT id FROM members WHERE full_name LIKE '%Grills%'   AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  (SELECT id FROM members WHERE full_name LIKE '%Ridder%'   AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  (SELECT id FROM members WHERE full_name LIKE '%Dolan%'    AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  (SELECT id FROM members WHERE full_name LIKE '%Dolcetti%' AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  6, 3, 6,
  4, 6, 4
);

-- Court 2: Baum & McGurren def. Brown & Walsh 6-3, 6-0
INSERT INTO matches (season, played_on, week_label, team1_player1, team1_player2, team2_player1, team2_player2, team1_set1, team1_set2, team1_set3, team2_set1, team2_set2, team2_set3)
VALUES (
  '2025-26',
  '2026-03-09'::date,
  'Week 20',
  (SELECT id FROM members WHERE full_name LIKE '%Baum%'     AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  (SELECT id FROM members WHERE full_name LIKE '%McGurren%' AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  (SELECT id FROM members WHERE full_name LIKE '%Brown%'    AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  (SELECT id FROM members WHERE full_name LIKE '%Walsh%'    AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  6, 6, NULL,
  3, 0, NULL
);

-- Court 3: Jonson & Rayhill def. Adams & Luecke 6-4, 6-3
INSERT INTO matches (season, played_on, week_label, team1_player1, team1_player2, team2_player1, team2_player2, team1_set1, team1_set2, team1_set3, team2_set1, team2_set2, team2_set3)
VALUES (
  '2025-26',
  '2026-03-09'::date,
  'Week 20',
  (SELECT id FROM members WHERE full_name LIKE '%Jonson%'   AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  (SELECT id FROM members WHERE full_name LIKE '%Rayhill%'  AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  (SELECT id FROM members WHERE full_name LIKE '%Adams%'    AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  (SELECT id FROM members WHERE full_name LIKE '%Luecke%'   AND (is_guest IS NULL OR is_guest = false) LIMIT 1),
  6, 6, NULL,
  4, 3, NULL
);
