-- Class reminders as Firebase (FCM) push notifications. Replaces the
-- client-scheduled weekly local notifications, so reminders arrive even if
-- the OS kills the app or its alarms, and overlapping classes collapse into
-- a single push per student (see send-class-reminders/index.ts).
--
-- Runs every minute: the function reminds for classes starting exactly 15
-- minutes from "now" in campus time, so a missed run skips that one reminder
-- rather than double-sending. Reuses the 'service_role_key' Vault secret and
-- pg_cron/pg_net setup from schedule_daily_study_reminder.sql, which must be
-- applied first. Apply by hand in the Supabase SQL editor.

CREATE OR REPLACE FUNCTION private.trigger_class_reminders()
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
    url := 'https://urglmgtjxtljzsjodmbf.supabase.co/functions/v1/send-class-reminders',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_key
    ),
    body := '{}'::jsonb
  );
END;
$$;

-- `select cron.unschedule('class-reminders');` removes it.
SELECT cron.schedule(
  'class-reminders',
  '* * * * *',
  $$ SELECT private.trigger_class_reminders(); $$
);
