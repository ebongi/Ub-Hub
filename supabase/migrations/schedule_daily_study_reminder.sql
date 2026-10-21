-- Periodic study-reminder push notification, sent via Firebase (FCM) so it
-- reaches users even when the app is backgrounded or fully closed — unlike
-- a client-scheduled local notification, delivery doesn't depend on the
-- app's own process or an Android AlarmManager receiver being registered.
--
-- Architecture: a pg_cron job runs daily inside Postgres and calls the
-- send-study-reminder Edge Function (supabase/functions/send-study-
-- reminder/index.ts) via pg_net, which queries profiles for everyone with
-- study_reminders_enabled = true and pushes to their fcm_token. The
-- service_role key needed to authenticate that HTTP call is read from
-- Supabase Vault by name ('service_role_key') — it is never written into
-- this or any other file; it must be populated once, out of band, via:
--   select vault.create_secret('<the real key>', 'service_role_key');
-- run directly against the database (not saved anywhere in this repo).
--
-- Apply by hand in the Supabase SQL editor, same as every other migration.
-- pg_cron/pg_net must be enabled first (this migration does that), and the
-- vault secret must exist before the cron job's first run for it to
-- actually send anything (it fails loudly via RAISE EXCEPTION otherwise,
-- visible in cron.job_run_details).

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS study_reminders_enabled BOOLEAN NOT NULL DEFAULT false;

-- Internal-only schema for cron/vault-touching helpers — kept out of
-- `public` so it's never exposed via PostgREST.
CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.trigger_study_reminder()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_service_key TEXT;
BEGIN
  SELECT decrypted_secret INTO v_service_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  IF v_service_key IS NULL THEN
    RAISE EXCEPTION 'service_role_key not found in Vault — see comment at the top of schedule_daily_study_reminder.sql';
  END IF;

  PERFORM net.http_post(
    url := 'https://urglmgtjxtljzsjodmbf.supabase.co/functions/v1/send-study-reminder',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_key
    ),
    body := '{}'::jsonb
  );
END;
$$;

-- Daily at 18:00 UTC = 19:00 WAT (Cameroon time, UTC+1 year-round) — an
-- early-evening nudge. Adjust the cron expression below to change timing;
-- `select cron.unschedule('daily-study-reminder');` removes it entirely.
SELECT cron.schedule(
  'daily-study-reminder',
  '0 18 * * *',
  $$ SELECT private.trigger_study_reminder(); $$
);
