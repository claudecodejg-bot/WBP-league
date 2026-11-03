-- =====================================================================
--  Who can actually sign in?
--
--  Read-only. Nothing is changed by this file.
--
--  The "Add Result" button appears for any member the site can match to
--  a login. That match is members.auth_id -> auth.users.id. If a member
--  has no auth_id, the site cannot tell who they are even when they are
--  signed in, so no button appears.
-- =====================================================================

select m.full_name,
       m.email,
       (m.auth_id is not null)                as linked,
       (au.id      is not null)                as login_exists,
       au.last_sign_in_at,
       (ms.member_id is not null)              as member_this_season
  from members m
  left join auth.users au  on au.id = m.auth_id
  left join member_seasons ms
         on ms.member_id = m.id and ms.season = '2026-27'
 where m.is_guest = false
   and ms.member_id is not null          -- this season's roster only
 order by linked, m.full_name;

-- What to look for:
--   linked = false            -> no login attached. This is the usual cause.
--   login_exists = false      -> auth_id points at a user that no longer
--                                exists (happens after deleting and
--                                recreating someone's auth user).
--   last_sign_in_at is null   -> account exists but has never been used.


-- ---------------------------------------------------------------------
--  FIX for anyone showing linked = false
--
--  Re-attaches a login to a member by matching on email. Safe to re-run;
--  it only fills in rows that are currently empty.
-- ---------------------------------------------------------------------
-- update members m
--    set auth_id = au.id
--   from auth.users au
--  where lower(au.email) = lower(m.email)
--    and m.auth_id is null;
