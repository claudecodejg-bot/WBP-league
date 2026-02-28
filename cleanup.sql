-- Step 1: Delete all matches (so we can safely remove old members)
DELETE FROM matches;

-- Step 2: Delete old members with full first+last names (@test.com emails)
DELETE FROM members WHERE email LIKE '%@test.com';
