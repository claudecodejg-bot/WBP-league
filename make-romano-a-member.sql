-- =============================================
--  Romano: guest -> member (2024-25)
--
--  Romano played a 2024-25 season and resigned mid-year with an injury.
--  He was carried in the database as a guest (is_guest = true), which put
--  him in the Guests table and the Guests group of every player dropdown.
--
--  He already has the right member_seasons row -- member-seasons.sql:312
--  gives him 2024-25 -- so the only thing miscategorising him is the flag.
--  Flipping it makes him a Member in 2024-25 and a Former Member in every
--  other season, which is what the history roster should show.
--
--  He also played one night in 2022-23 as a fill-in, before he joined.
--  That gets no member_seasons row, so 2022-23 still shows him with the
--  single match -- under Former Members rather than Guests, because the
--  three tiers key off "ever a member" and not off the year he joined.
--
--  Run in the Supabase SQL editor. Safe to re-run.
-- =============================================

begin;

update public.members
   set is_guest = false
 where lower(full_name) = lower('Romano');

-- Belt and braces: the season row should already be here, but an insert
-- makes this file stand on its own if it is ever run against a fresh load.
insert into public.member_seasons (member_id, season)
select id, '2024-25' from public.members
 where lower(full_name) = lower('Romano')
 limit 1
on conflict (member_id, season) do nothing;

commit;

-- ---------------------------------------------
--  Verify
-- ---------------------------------------------

-- Expect: Romano, is_guest = false
select full_name, is_guest
  from public.members
 where lower(full_name) = lower('Romano');

-- Expect: exactly one row, 2024-25
select m.full_name, ms.season
  from public.member_seasons ms
  join public.members m on m.id = ms.member_id
 where lower(m.full_name) = lower('Romano')
 order by ms.season;

-- Expect: 2022-23 one match, 2024-25 four matches
select season, count(*) as matches
  from public.matches
 where (select id from public.members where lower(full_name) = lower('Romano'))
       in (team1_player1, team1_player2, team2_player1, team2_player2)
 group by season
 order by season;
