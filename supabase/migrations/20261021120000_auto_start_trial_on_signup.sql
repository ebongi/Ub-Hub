-- Starts the App Plan's 14-day free trial automatically for every new
-- account, instead of waiting for the user to tap "Start Free Trial" in
-- Settings (which calls claim_free_trial()). Also grants the same trial to
-- existing users who never claimed one.
--
-- No client change is needed: the app already reads subscription_tier,
-- subscription_expiry, subscription_is_trial and trial_used from the
-- profile, so the trial badge shows and the Start Free Trial button hides
-- (trial_used = true) on its own. is_authorized() also accepts any non-free
-- tier with a future expiry, so the 3-day new-account grace window becomes
-- redundant for these users but is left in place.
--
-- Keep the 14 days in sync with claim_free_trial()
-- (shorten_free_trial_to_two_weeks.sql) and the Dart `_trialLength` in
-- UserProfile / UserModel.

-- 1. New accounts ----------------------------------------------------------
-- BEFORE INSERT so it works however the profile row is created (the app's
-- upsert in database.dart, or any future auth trigger). On an upsert that
-- hits an existing row the trigger still fires, but PostgREST's ON CONFLICT
-- DO UPDATE only sets the columns in the payload, so none of these fields
-- are rewritten for existing users.
CREATE OR REPLACE FUNCTION public.start_trial_on_signup()
RETURNS TRIGGER AS $$
BEGIN
  NEW.subscription_tier := 'monthly';
  NEW.subscription_expiry := now() + INTERVAL '14 days';
  NEW.subscription_is_trial := true;
  NEW.trial_used := true;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS on_profile_insert_start_trial ON profiles;
CREATE TRIGGER on_profile_insert_start_trial
  BEFORE INSERT ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.start_trial_on_signup();

-- 2. Existing users --------------------------------------------------------
-- Only users who never claimed a trial and have no active paid plan.
-- Admins/contributors already bypass the paywall, so they are skipped.
-- The 14 days start from the moment this migration runs.
-- handle_profile_update() reverts subscription columns unless this GUC is
-- set (harden_subscription_and_payment_writes.sql); it is transaction-local.
SELECT set_config('app.bypass_subscription_guard', 'true', true);

UPDATE profiles
   SET subscription_tier = 'monthly',
       subscription_expiry = now() + INTERVAL '14 days',
       subscription_is_trial = true,
       trial_used = true,
       free_download_count = 0
 WHERE trial_used = false
   AND role NOT IN ('admin', 'contributor')
   AND (subscription_tier = 'free'
        OR subscription_expiry IS NULL
        OR subscription_expiry <= now());
