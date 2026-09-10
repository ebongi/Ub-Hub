-- Shortens the App Plan's free trial from 30 days (one month) to 14 days
-- (two weeks). The separate new-account grace window (3 days, enforced in
-- is_authorized() from reconcile_paywall_with_trial_model.sql and mirrored
-- client-side in UserProfile.hasAccess / UserModel.hasAccess) is unaffected
-- and continues to apply before a trial is ever claimed.
CREATE OR REPLACE FUNCTION public.claim_free_trial()
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_expiry TIMESTAMPTZ := now() + INTERVAL '14 days';
  v_updated INT;
BEGIN
  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles
     SET subscription_tier = 'monthly',
         subscription_expiry = v_expiry,
         subscription_is_trial = true,
         trial_used = true,
         free_download_count = 0
   WHERE id = auth.uid() AND trial_used = false;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    RAISE EXCEPTION 'Free trial already used';
  END IF;

  RETURN v_expiry;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION public.claim_free_trial() SET search_path = public, pg_temp;
