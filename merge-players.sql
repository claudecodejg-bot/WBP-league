-- =============================================
-- merge-players.sql
-- Run in Supabase SQL editor AFTER:
--   1. historical-members-all.sql
--   2. historical-data-all.sql
-- =============================================

-- Reusable helper: merges (drop_name) into (keep_name), renames keeper to (final_name)
CREATE OR REPLACE FUNCTION _merge_player(keep_name text, drop_name text, final_name text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  keep_id uuid;
  drop_id uuid;
BEGIN
  SELECT id INTO keep_id FROM members WHERE LOWER(full_name) = LOWER(keep_name) LIMIT 1;
  SELECT id INTO drop_id FROM members WHERE LOWER(full_name) = LOWER(drop_name) LIMIT 1;

  IF keep_id IS NULL THEN
    RAISE NOTICE 'SKIP: keep player "%" not found.', keep_name;
    RETURN;
  END IF;

  IF drop_id IS NOT NULL THEN
    UPDATE matches SET team1_player1 = keep_id WHERE team1_player1 = drop_id;
    UPDATE matches SET team1_player2 = keep_id WHERE team1_player2 = drop_id;
    UPDATE matches SET team2_player1 = keep_id WHERE team2_player1 = drop_id;
    UPDATE matches SET team2_player2 = keep_id WHERE team2_player2 = drop_id;
    DELETE FROM members WHERE id = drop_id;
    RAISE NOTICE 'Merged "%" → "%" (renamed to "%")', drop_name, keep_name, final_name;
  ELSE
    RAISE NOTICE 'No duplicate "%" found — renaming "%" → "%" only.', drop_name, keep_name, final_name;
  END IF;

  UPDATE members SET full_name = final_name WHERE id = keep_id;
END $$;

-- ── Merges ────────────────────────────────────────────────────────────────────

-- 1. Jonson + R. Jonson  →  Jonson, R.
--    (keeps existing Jonson record which holds 2011-12+ data;
--     absorbs R. Jonson's early-season matches into it)
SELECT _merge_player('Jonson', 'R. Jonson', 'Jonson, R.');

-- 2. Johnson + S. Johnson  →  Johnson, S.
--    (keeps S. Johnson; absorbs early "Johnson" matches)
SELECT _merge_player('S. Johnson', 'Johnson', 'Johnson, S.');

-- 3. Zejda + M Zejda  →  Zejda, M.
--    (keeps M Zejda; absorbs plain "Zejda" matches)
SELECT _merge_player('M Zejda', 'Zejda', 'Zejda, M.');

-- 4. D Zejda + Zedja Jr  →  Zejda, D.
--    (keeps D Zejda; absorbs Zedja Jr matches)
SELECT _merge_player('D Zejda', 'Zedja Jr', 'Zejda, D.');

-- ── Cleanup ───────────────────────────────────────────────────────────────────
DROP FUNCTION _merge_player(text, text, text);
