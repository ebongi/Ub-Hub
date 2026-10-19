-- Weekly "Happy new week" push + in-app notification to every user,
-- personalised with their first name and their own exams/tasks coming up in
-- the next 7 days (see supabase/functions/send-weekly-greeting).
--
-- Same architecture as schedule_upload_nudge.sql: pg_cron -> pg_net -> Edge
-- Function, authenticated with the 'service_role_key' Vault secret.
--
-- Mondays at 06:00 UTC = 07:00 WAT. `select cron.unschedule('weekly-greeting');`
-- stops it.

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.trigger_weekly_greeting()
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
    url := 'https://urglmgtjxtljzsjodmbf.supabase.co/functions/v1/send-weekly-greeting',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_key
    ),
    body := '{}'::jsonb
  );
END;
$$;

SELECT cron.schedule(
  'weekly-greeting',
  '0 6 * * 1',
  $$ SELECT private.trigger_weekly_greeting(); $$
);
