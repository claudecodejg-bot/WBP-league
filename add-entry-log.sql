-- =====================================================================
--  Record who entered each score
--
--  Until members could enter results there was only ever one person it
--  could have been. Now there isn't, so each match records who typed it
--  in alongside the created_at that was already there.
--
--  The value is stamped by the database, not sent by the browser. A
--  trigger reads auth.uid() -- the signed-in user, as Supabase itself
--  sees them -- and overwrites whatever the client supplied. Nobody can
--  put someone else's name on a result they entered, including by
--  calling the API directly.
--
--  Existing rows get NULL: we genuinely do not know who entered them,
--  and guessing would be worse than leaving it blank.
--
--  Safe to re-run.
-- =====================================================================

begin;

alter table public.matches
  add column if not exists entered_by uuid
    references public.members(id) on delete set null;

comment on column public.matches.entered_by is
  'Member who entered this result. Set by trigger from auth.uid(); never trusted from the client. NULL for rows predating the log.';

-- Looks the member up from the signed-in user. SECURITY DEFINER because
-- the members table is not readable column-by-column to every role, and
-- the lookup must work regardless of who is inserting.
create or replace function public.stamp_match_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Deliberately ignores any entered_by the client sent.
  select id into new.entered_by
    from public.members
   where auth_id = auth.uid();
  return new;
end;
$$;

drop trigger if exists matches_stamp_entry on public.matches;
create trigger matches_stamp_entry
  before insert on public.matches
  for each row execute function public.stamp_match_entry();

commit;

-- ---------------------------------------------------------------------
--  VERIFY
-- ---------------------------------------------------------------------

-- 1. Column and trigger are there.
select column_name from information_schema.columns
 where table_name = 'matches' and column_name = 'entered_by';
select tgname from pg_trigger where tgname = 'matches_stamp_entry';

-- 2. The log itself. Empty until the next result is entered; from then on
--    this is the "who do I talk to" list, newest first.
select m.played_on,
       m.week_label,
       coalesce(e.full_name, '(before the log)') as entered_by,
       m.created_at
  from matches m
  left join members e on e.id = m.entered_by
 order by m.created_at desc nulls last
 limit 20;
