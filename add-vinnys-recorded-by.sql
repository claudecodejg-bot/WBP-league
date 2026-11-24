-- =====================================================================
--  vinnys.recorded_by — who ticked the night off
--
--  The form can already say a night is logged, how many are on it and
--  when it was saved. It could not say who, because nothing recorded it:
--  member_id is the person who WENT OUT, not the person who entered it.
--
--  SET NULL rather than CASCADE. member_id already cascades, so a
--  departing member's own rows go with them; this column is about
--  somebody else's row, and losing a member should not quietly delete
--  the record of what they logged for everyone else.
--
--  No new grant needed: allow-members-record-vinnys.sql grants
--  select/insert/delete on the TABLE, which covers columns added later.
--
--  Run in the Supabase SQL editor. Safe to re-run.
-- =====================================================================

alter table public.vinnys
  add column if not exists recorded_by uuid
    references public.members(id) on delete set null;

comment on column public.vinnys.recorded_by is
  'The member who saved this night. member_id is who went out; this is who wrote it down. Null for rows entered before this column existed.';

-- Verify: expect id, played_on, member_id, created_at, recorded_by.
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'vinnys'
order by ordinal_position;
