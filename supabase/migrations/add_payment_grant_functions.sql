-- Replaces the direct client `.update()` calls in DatabaseService
-- (upgradeSubscription, startFreeMonthlyTrial, purchaseAISubscription,
-- addAICredits, incrementFreeDownloadCount) with SECURITY DEFINER RPCs.
-- Each one sets `app.bypass_subscription_guard` (see
-- harden_subscription_and_payment_writes.sql) before mutating `profiles`,
-- and every paid grant first calls `_consume_payment` to require a matching
-- `payment_transactions` row that's already `status='success'` (only ever
-- set by complete_payment_transaction.sql, server-side) and not yet
-- consumed — so a given completed payment can only ever fund one grant.

CREATE OR REPLACE FUNCTION public._consume_payment(p_payment_ref TEXT)
RETURNS payment_transactions AS $$
DECLARE
  v_row payment_transactions%ROWTYPE;
BEGIN
  SELECT * INTO v_row FROM payment_transactions
    WHERE payment_ref = p_payment_ref AND user_id = auth.uid()
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment reference not found';
  END IF;
  IF v_row.status <> 'success' THEN
    RAISE EXCEPTION 'Payment not completed';
  END IF;
  IF v_row.consumed THEN
    RAISE EXCEPTION 'Payment already used';
  END IF;

  UPDATE payment_transactions SET consumed = true WHERE id = v_row.id;

  RETURN v_row;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public._consume_payment(TEXT) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.claim_free_trial()
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_expiry TIMESTAMPTZ := now() + INTERVAL '30 days';
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

CREATE OR REPLACE FUNCTION public.grant_subscription(p_tier TEXT, p_payment_ref TEXT)
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_expiry TIMESTAMPTZ;
BEGIN
  IF p_tier NOT IN ('monthly', 'yearly') THEN
    RAISE EXCEPTION 'Invalid tier';
  END IF;

  PERFORM public._consume_payment(p_payment_ref);

  v_expiry := now() + (CASE WHEN p_tier = 'monthly' THEN INTERVAL '30 days' ELSE INTERVAL '365 days' END);

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles
     SET subscription_tier = p_tier,
         subscription_expiry = v_expiry,
         subscription_is_trial = false,
         free_download_count = 0
   WHERE id = auth.uid();

  RETURN v_expiry;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.grant_ai_subscription(p_tier TEXT, p_payment_ref TEXT)
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_expiry TIMESTAMPTZ;
BEGIN
  IF p_tier NOT IN ('monthly', 'yearly') THEN
    RAISE EXCEPTION 'Invalid tier';
  END IF;

  PERFORM public._consume_payment(p_payment_ref);

  v_expiry := now() + (CASE WHEN p_tier = 'monthly' THEN INTERVAL '30 days' ELSE INTERVAL '365 days' END);

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles SET ai_subscription_expiry = v_expiry WHERE id = auth.uid();

  RETURN v_expiry;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.grant_ai_credits(p_amount INT, p_payment_ref TEXT)
RETURNS INT AS $$
DECLARE
  v_new_credits INT;
BEGIN
  PERFORM public._consume_payment(p_payment_ref);

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles SET ai_credits = ai_credits + p_amount WHERE id = auth.uid()
    RETURNING ai_credits INTO v_new_credits;

  RETURN v_new_credits;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.increment_free_download_count()
RETURNS INT AS $$
DECLARE
  v_new_count INT;
BEGIN
  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles SET free_download_count = free_download_count + 1 WHERE id = auth.uid()
    RETURNING free_download_count INTO v_new_count;

  RETURN v_new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.claim_free_trial() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.grant_subscription(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.grant_ai_subscription(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.grant_ai_credits(INT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.increment_free_download_count() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.claim_free_trial() TO authenticated;
GRANT EXECUTE ON FUNCTION public.grant_subscription(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.grant_ai_subscription(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.grant_ai_credits(INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_free_download_count() TO authenticated;
