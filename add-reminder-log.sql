-- =====================================================================
--  reminder_log — stops the availability reminders repeating
--
--  Why this is needed now: GitHub ran the reminder workflow between two
--  and three and a half hours after its cron time, so the script's
--  exact-hour check rejected every run and nothing was ever sent.
--
--  The fix is to run the workflow hourly across a window and accept any
--  run inside it. That means several runs could each decide to send, so
--  something has to make sure only one does.
--
--  This table is that something. The primary key is the lock: the script
--  inserts (week_start, kind) BEFORE sending, and a second run gets a
--  duplicate-key error and backs off. Claiming first rather than
--  recording afterwards means two overlapping runs cannot both send.
--
--  Run in the Supabase SQL editor. Safe to re-run.
-- =====================================================================

CREATE TABLE IF NOT EXISTS reminder_log (
  week_start date        NOT NULL,
  kind       text        NOT NULL CHECK (kind IN ('thursday', 'friday')),
  sent_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (week_start, kind)
);

ALTER TABLE reminder_log ENABLE ROW LEVEL SECURITY;

-- No policies on purpose. Only the secret key touches this table, and the
-- secret key bypasses row-level security. With RLS on and nothing granted,
-- the public key cannot read or write it at all.

-- Verify: expect the table to exist and be empty.
SELECT count(*) AS rows_so_far FROM reminder_log;
