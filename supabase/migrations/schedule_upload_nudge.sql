-- Recurring "upload your materials so others can access them" nudge to all
-- users: an in-app notification row plus an FCM push, sent every 3 days.
--
-- Same architecture as schedule_daily_study_reminder.sql: pg_cron calls the
-- send-upload-nudge Edge Function (supabase/functions/send-upload-nudge)
-- via pg_net, authenticating with the service_role key read from Vault by
-- name ('service_role_key', already created for the study reminder).
--
-- Cron has no true "every 3 days": `*/3` on day-of-month fires on days
-- 1,4,7,...,31, so the gap shrinks to 1-2 days at each month boundary
-- (e.g. 31st -> 1st). Acceptable for a soft nudge.
--
-- 17:00 UTC = 18:00 WAT. `select cron.unschedule('upload-nudge');` stops it.

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.trigger_upload_nudge()
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
    RAISE EXCEPTION 'service_role_key not found in Vault — see schedule_daily_study_reminder.sql';
  END IF;

  PERFORM net.http_post(
    url := 'https://urglmgtjxtljzsjodmbf.supabase.co/functions/v1/send-upload-nudge',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_key
    ),
    body := '{}'::jsonb
  );
END;
$$;

SELECT cron.schedule(
  'upload-nudge',
  '0 17 */3 * *',
  $$ SELECT private.trigger_upload_nudge(); $$
);
