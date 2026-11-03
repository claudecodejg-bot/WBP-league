-- =====================================================================
--  Historical Paddle Homie and Vinny's totals
--
--  The live awards are worked out from the availability and vinnys
--  tables, which only start in the 2026-27 season. For earlier years all
--  that survives is a season total per member, from Grills's own records.
--
--  Those totals cannot be stored as per-night rows: there are no nights
--  to attach them to, and some Vinny's figures are halves (Ridder 4.5,
--  Rayhill 2.5), which a count of rows can never produce. So they are
--  kept as totals, and the awards read from here when a season has them.
--
--  Seasons with neither recorded totals nor live data now show no award
--  at all, instead of the attendance count that was standing in for one.
--
--  Safe to re-run: totals are replaced, never doubled.
-- =====================================================================

begin;

create table if not exists public.season_awards (
  id            uuid primary key default gen_random_uuid(),
  season        text not null,
  member_id     uuid not null references public.members(id) on delete cascade,
  homie_weeks   numeric(5,1),
  vinnys_nights numeric(5,1),
  unique (season, member_id)
);

comment on table public.season_awards is
  'Season totals for years predating the availability and vinnys tables. One row per member per season; a NULL column means that award was not recorded that year.';

alter table public.season_awards enable row level security;

drop policy if exists "Public can read season awards" on public.season_awards;
create policy "Public can read season awards"
  on public.season_awards for select using (true);

drop policy if exists "Admins manage season awards" on public.season_awards;
create policy "Admins manage season awards"
  on public.season_awards for all to authenticated
  using (public.auth_is_admin()) with check (public.auth_is_admin());

grant select on public.season_awards to anon, authenticated;


-- ---------------------------------------------------------------------
--  PADDLE HOMIE totals
-- ---------------------------------------------------------------------
insert into public.season_awards (season, member_id, homie_weeks)
select v.season, m.id, v.weeks
  from (values
          ('2023-24', 'Adams', 18),
          ('2023-24', 'Baum', 12),
          ('2023-24', 'Brown', 14),
          ('2023-24', 'D''Acunto', 13),
          ('2023-24', 'Dolan', 14),
          ('2023-24', 'Dolcetti', 14),
          ('2023-24', 'Grills', 17),
          ('2023-24', 'Jonson', 18),
          ('2023-24', 'Luecke', 14),
          ('2023-24', 'McGurren', 22),
          ('2023-24', 'Rayhill', 16),
          ('2023-24', 'Ridder', 22),
          ('2023-24', 'Rockman', 9),
          ('2023-24', 'Smith', 13),
          ('2023-24', 'Walsh', 9),
          ('2024-25', 'Adams', 19),
          ('2024-25', 'Baum', 11),
          ('2024-25', 'Brown', 13),
          ('2024-25', 'D''Acunto', 7),
          ('2024-25', 'Dolan', 11),
          ('2024-25', 'Dolcetti', 3),
          ('2024-25', 'Grills', 13),
          ('2024-25', 'Jonson', 13),
          ('2024-25', 'Luecke', 16),
          ('2024-25', 'McGurren', 18),
          ('2024-25', 'Napolitano', 18),
          ('2024-25', 'Rayhill', 18),
          ('2024-25', 'Romano', 4),
          ('2024-25', 'Ridder', 20),
          ('2024-25', 'Rockman', 13),
          ('2024-25', 'Smith', 10),
          ('2024-25', 'Walsh', 7),
          ('2025-26', 'Ridder', 18),
          ('2025-26', 'McGurren', 18),
          ('2025-26', 'Grills', 15),
          ('2025-26', 'Adams', 16),
          ('2025-26', 'Walsh', 14),
          ('2025-26', 'Rayhill', 13),
          ('2025-26', 'Brown', 10),
          ('2025-26', 'D''Acunto', 9),
          ('2025-26', 'Luecke', 10),
          ('2025-26', 'Smith', 8),
          ('2025-26', 'Jonson', 12),
          ('2025-26', 'Dolan', 7),
          ('2025-26', 'Dolcetti', 8),
          ('2025-26', 'Napolitano', 5),
          ('2025-26', 'Rockman', 0),
          ('2025-26', 'Baum', 3)
       ) as v(season, name, weeks)
  join public.members m on m.full_name = v.name
on conflict (season, member_id)
  do update set homie_weeks = excluded.homie_weeks;


-- ---------------------------------------------------------------------
--  VINNY'S totals
-- ---------------------------------------------------------------------
insert into public.season_awards (season, member_id, vinnys_nights)
select v.season, m.id, v.nights
  from (values
          ('2025-26', 'Walsh', 9),
          ('2025-26', 'McGurren', 8),
          ('2025-26', 'Grills', 7),
          ('2025-26', 'Dolan', 6),
          ('2025-26', 'Ridder', 4.5),
          ('2025-26', 'Jonson', 4),
          ('2025-26', 'Rayhill', 2.5),
          ('2025-26', 'Luecke', 2),
          ('2025-26', 'Rockman', 3),
          ('2025-26', 'Napolitano', 2),
          ('2025-26', 'Smith', 2),
          ('2025-26', 'Brown', 1),
          ('2025-26', 'Adams', 1),
          ('2025-26', 'Dolcetti', 1),
          ('2025-26', 'D''Acunto', 1)
       ) as v(season, name, nights)
  join public.members m on m.full_name = v.name
on conflict (season, member_id)
  do update set vinnys_nights = excluded.vinnys_nights;


-- ---------------------------------------------------------------------
--  Did every name match a member?
--
--  Both inserts join on members.full_name, so a mistyped name would be
--  silently dropped rather than reported. These are the counts handed in;
--  if the database disagrees, the whole transaction is rolled back.
-- ---------------------------------------------------------------------
do $$
declare
  expected constant jsonb := '{"2023-24": 15, "2024-25": 17, "2025-26": 16}';
  s   text;
  got int;
begin
  for s in select jsonb_object_keys(expected) loop
    select count(*) into got
      from public.season_awards where season = s and homie_weeks is not null;
    if got <> (expected ->> s)::int then
      raise exception 'Paddle Homie %: expected % members, stored %. A name did not match the roster.',
        s, (expected ->> s)::int, got;
    end if;
  end loop;

  select count(*) into got
    from public.season_awards where season = '2025-26' and vinnys_nights is not null;
  if got <> 15 then
    raise exception 'Vinny''s 2025-26: expected 15 members, stored %.', got;
  end if;
end $$;

commit;

-- ---------------------------------------------------------------------
--  VERIFY -- run after the COMMIT
-- ---------------------------------------------------------------------
select season,
       count(*) filter (where homie_weeks   is not null) as homie,
       count(*) filter (where vinnys_nights is not null) as vinnys
  from public.season_awards
 group by season order by season;
-- Expect:
--   2023-24   15    0
--   2024-25   17    0
--   2025-26   16   15

-- The 2025-26 Vinny's table as it will appear on the site.
select m.full_name, a.vinnys_nights
  from public.season_awards a
  join public.members m on m.id = a.member_id
 where a.season = '2025-26' and a.vinnys_nights is not null
 order by a.vinnys_nights desc, m.full_name;
-- Walsh should lead on 9, with Ridder on 4.5 and Rayhill on 2.5.
