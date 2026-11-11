-- =====================================================================
--  Phase 0 — give every scheduled court its own row and a stable id
--
--  WHY THIS EXISTS
--
--  scheduled_matches stores a whole night as one row with the courts in a
--  jsonb array of NAMES:
--
--    courts = [{team1: ['Ridder','Rayhill'], team2: [...], time, location}]
--
--  That is fine for printing a schedule and useless for anything that has
--  to refer to one court later:
--
--    1. Names, not ids. We already have `Jonson, R.` / `Johnson, S.` and
--       four historical merges; settling anything against free text is a
--       rename away from breaking.
--    2. No per-court identity. "Court 2" is just index 2 in an array, and
--       scheduler.html upserts on played_on — regenerate the pairings and
--       index 2 is different people, silently.
--    3. The row is deleted. results.html removes it once every court is
--       recorded, which is exactly when anything attached to it matters.
--
--  So courts get real rows, with real member FKs, that nothing deletes.
--
--  The scheduler already HAS the member ids — scheduler.html builds the
--  jsonb with idToName[a] and then throws the ids away. It now writes both:
--  the jsonb for the existing pages, and these rows for everything new.
--  Nothing that reads scheduled_matches has to change.
--
--  Run in the Supabase SQL editor. Safe to re-run.
-- =====================================================================

begin;

create table if not exists public.scheduled_courts (
  id          uuid primary key default gen_random_uuid(),
  season      text        not null,
  played_on   date        not null,
  week_label  text,
  court_no    smallint    not null,

  -- The four players, by id. Sides are 1 and 2, matching the `side` column
  -- on a wager. Which side is which is fixed for the life of the row.
  t1p1 uuid not null references public.members(id),
  t1p2 uuid not null references public.members(id),
  t2p1 uuid not null references public.members(id),
  t2p2 uuid not null references public.members(id),

  location    text,
  start_time  text,

  -- When this court stops accepting picks. Derived from played_on +
  -- start_time in Eastern time, NOT from when a result gets entered:
  -- results routinely land hours after play (last week's three courts were
  -- stamped at 01:48am), so anyone who played would otherwise be able to
  -- bet on a night they already know the result of.
  closes_at   timestamptz not null,

  status      text not null default 'open'
                check (status in ('open', 'locked', 'settled', 'void')),
  created_at  timestamptz not null default now(),

  unique (played_on, court_no),

  -- Four different people on a court.
  constraint scheduled_courts_distinct_players check (
    t1p1 <> t1p2 and t1p1 <> t2p1 and t1p1 <> t2p2 and
    t1p2 <> t2p1 and t1p2 <> t2p2 and t2p1 <> t2p2
  )
);

create index if not exists scheduled_courts_played_on_idx
  on public.scheduled_courts (played_on);

comment on table public.scheduled_courts is
  'One row per scheduled court, with member FKs and a stable id. Written by the scheduler alongside the scheduled_matches jsonb; deliberately NOT deleted when that row is.';

alter table public.scheduled_courts enable row level security;

-- Readable by everyone, like the rest of the site. Written only through
-- replace_scheduled_courts() below — see the REVOKE after the commit.
drop policy if exists "Public can read scheduled courts" on public.scheduled_courts;
create policy "Public can read scheduled courts"
  on public.scheduled_courts for select using (true);

commit;

-- ---------------------------------------------------------------------
--  Writes go through a function, never straight from the browser
-- ---------------------------------------------------------------------
-- A court row is the thing picks are settled against, so the rules about
-- who may write one (admin only) and what a valid one looks like (four
-- distinct members, a sane close time) are enforced in one place that the
-- publishable key cannot go around.

-- REVOKE ALL, not the three obvious writes: Supabase's default privileges
-- grant ALL on tables in public to anon, and naming insert/update/delete
-- leaves TRUNCATE, REFERENCES and TRIGGER in place. RLS does not apply to
-- TRUNCATE, so that one would empty the table policies and all.
revoke all    on public.scheduled_courts from anon, authenticated;
grant  select on public.scheduled_courts to   anon, authenticated;

-- Turns '7:00 PM' on a date into a real instant in league time. Falls back
-- to 7pm if the scheduler ever hands us something unparseable, rather than
-- failing the whole save.
create or replace function public.court_closes_at(p_played_on date, p_time text)
returns timestamptz
language plpgsql
stable                      -- not immutable: 'at time zone' reads the tz database
as $$
declare
  v_ts timestamp;
begin
  begin
    v_ts := (p_played_on::text || ' ' || coalesce(nullif(btrim(p_time), ''), '7:00 PM'))::timestamp;
  exception when others then
    v_ts := (p_played_on::text || ' 7:00 PM')::timestamp;
  end;
  return v_ts at time zone 'America/New_York';
end;
$$;

-- Replaces the courts for one night.
--
-- Phase 1 (add-wagers.sql) redefines this with the extra step of voiding
-- and refunding any picks already made on the courts being replaced. Until
-- then there are no picks, so a plain replace is correct.
create or replace function public.replace_scheduled_courts(
  p_season     text,
  p_played_on  date,
  p_week_label text,
  p_courts     jsonb          -- [{court_no, t1p1, t1p2, t2p1, t2p2, location, time}, ...]
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_court jsonb;
  v_count int := 0;
begin
  if not public.auth_is_admin() then
    raise exception 'Only an admin can set the schedule';
  end if;

  delete from public.scheduled_courts where played_on = p_played_on;

  for v_court in select * from jsonb_array_elements(p_courts) loop
    insert into public.scheduled_courts (
      season, played_on, week_label, court_no,
      t1p1, t1p2, t2p1, t2p2,
      location, start_time, closes_at
    ) values (
      p_season,
      p_played_on,
      p_week_label,
      (v_court->>'court_no')::smallint,
      (v_court->>'t1p1')::uuid,
      (v_court->>'t1p2')::uuid,
      (v_court->>'t2p1')::uuid,
      (v_court->>'t2p2')::uuid,
      nullif(v_court->>'location', ''),
      nullif(v_court->>'time', ''),
      public.court_closes_at(p_played_on, v_court->>'time')
    );
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke all     on function public.replace_scheduled_courts(text, date, text, jsonb) from public, anon;
grant  execute on function public.replace_scheduled_courts(text, date, text, jsonb) to   authenticated;

-- ---------------------------------------------------------------------
--  One-time backfill
-- ---------------------------------------------------------------------
-- Only does anything if a scheduled_matches row exists when this runs —
-- i.e. pairings were generated before the migration. Names are resolved
-- against members.full_name, which is exactly what the scheduler wrote.
-- A court with any name it cannot resolve is skipped rather than guessed
-- at, and listed by the SELECT at the bottom.

do $$
declare
  v_row   record;
  v_court jsonb;
  v_i     int;
  v_ids   uuid[];
  v_names text[];
  v_name  text;
  v_id    uuid;
begin
  for v_row in select * from public.scheduled_matches loop
    v_i := 0;
    for v_court in select * from jsonb_array_elements(v_row.courts) loop
      v_i   := v_i + 1;
      v_ids := array[]::uuid[];

      -- team1 then team2, in order, so slots line up with sides 1 and 2.
      v_names := array(select jsonb_array_elements_text(v_court->'team1'))
              || array(select jsonb_array_elements_text(v_court->'team2'));

      foreach v_name in array v_names loop
        select id into v_id from public.members where full_name = v_name limit 1;
        if v_id is null then
          v_ids := null;
          exit;
        end if;
        v_ids := v_ids || v_id;
      end loop;

      if v_ids is null or coalesce(array_length(v_ids, 1), 0) <> 4 then
        raise notice 'Skipping % court % — could not resolve all four names', v_row.played_on, v_i;
        continue;
      end if;

      insert into public.scheduled_courts (
        season, played_on, week_label, court_no,
        t1p1, t1p2, t2p1, t2p2, location, start_time, closes_at
      ) values (
        -- The season column on scheduled_matches does not exist; derive it
        -- the way the rest of the site does, from the match history for the
        -- same night, and fall back to the current season label.
        coalesce((select season from public.matches
                   where played_on = v_row.played_on limit 1), '2026-27'),
        v_row.played_on, v_row.week_label, v_i,
        v_ids[1], v_ids[2], v_ids[3], v_ids[4],
        nullif(v_court->>'location', ''),
        nullif(v_court->>'time', ''),
        public.court_closes_at(v_row.played_on, v_court->>'time')
      )
      on conflict (played_on, court_no) do nothing;
    end loop;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------
--  VERIFY
-- ---------------------------------------------------------------------

-- Expect 0 rows on a clean install (the schedule row is deleted once a
-- night is fully recorded), or one row per court of any night still
-- outstanding. Names here are joined live, proving the FKs resolve.
select c.played_on,
       c.court_no,
       a.full_name || ' & ' || b.full_name as side_1,
       d.full_name || ' & ' || e.full_name as side_2,
       c.start_time,
       c.closes_at,
       c.status
  from public.scheduled_courts c
  join public.members a on a.id = c.t1p1
  join public.members b on b.id = c.t1p2
  join public.members d on d.id = c.t2p1
  join public.members e on e.id = c.t2p2
 order by c.played_on desc, c.court_no;
