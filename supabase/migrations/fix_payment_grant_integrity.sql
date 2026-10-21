-- ==========================================================================
-- Closes two live vulnerabilities in the payment-grant RPCs introduced by
-- add_payment_grant_functions.sql, and hardens every SECURITY DEFINER
-- function in the schema against search_path-based privilege escalation.
--
-- 1. REPLAY BUG: `_consume_payment` set `consumed = true` (its own UPDATE)
--    before any caller had set `app.bypass_subscription_guard` — so the
--    `handle_payment_transaction_update` trigger (which reverts `consumed`
--    changes when the guard isn't set) silently undid that write on every
--    call. A single confirmed payment could therefore be replayed against
--    grant_subscription/grant_ai_subscription/grant_ai_credits indefinitely.
--    Fix: set the bypass guard as the FIRST statement inside
--    `_consume_payment` itself, before its UPDATE runs.
--
-- 2. NO PRICE VALIDATION: the three grant functions called
--    `PERFORM public._consume_payment(...)`, discarding the returned row
--    (including `amount`) entirely — nothing tied the confirmed-paid amount
--    to the tier/credits being granted. A user could pay a self-chosen low
--    amount for a real (cheap) transaction and then call e.g.
--    grant_subscription('yearly', that_ref) to get the most expensive tier.
--    Fix: capture the row from `_consume_payment` and assert its amount
--    meets the expected price for what's being granted, via a new
--    `_expected_price` helper mirroring the Dart price constants in
--    lib/services/subscription_service.dart.
--
-- 3. SEARCH_PATH: none of the 15 SECURITY DEFINER functions in this schema
--    pinned `search_path`, a known Postgres privilege-escalation vector.
--    Fix: pin `search_path = public, pg_temp` on every one — inline on the
--    functions redefined below for (1)/(2), via ALTER FUNCTION for the rest.
-- ==========================================================================

-- --------------------------------------------------------------------------
-- Fix 1 + 3: _consume_payment — bypass guard moved to the top, search_path
-- pinned. Body otherwise unchanged.
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._consume_payment(p_payment_ref TEXT)
RETURNS payment_transactions AS $$
DECLARE
  v_row payment_transactions%ROWTYPE;
BEGIN
  -- Must be set before the UPDATE below, or handle_payment_transaction_update
  -- (harden_subscription_and_payment_writes.sql) reverts the `consumed` write
  -- and this payment can be replayed indefinitely.
  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION public._consume_payment(TEXT) FROM PUBLIC;

-- --------------------------------------------------------------------------
-- Fix 2: canonical prices, mirroring lib/services/subscription_service.dart.
-- Keep both in sync if prices ever change.
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._expected_price(p_item TEXT)
RETURNS NUMERIC AS $$
BEGIN
  RETURN CASE p_item
    WHEN 'subscription_monthly' THEN 500
    WHEN 'subscription_yearly' THEN 3500
    WHEN 'ai_subscription_monthly' THEN 1000
    WHEN 'ai_subscription_yearly' THEN 3000
    ELSE NULL
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION public._expected_price(TEXT) FROM PUBLIC;

-- --------------------------------------------------------------------------
-- Fix 2 + 3: grant_subscription — validates amount, pins search_path.
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.grant_subscription(p_tier TEXT, p_payment_ref TEXT)
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_expiry TIMESTAMPTZ;
  v_row payment_transactions%ROWTYPE;
BEGIN
  IF p_tier NOT IN ('monthly', 'yearly') THEN
    RAISE EXCEPTION 'Invalid tier';
  END IF;

  v_row := public._consume_payment(p_payment_ref);

  IF v_row.amount < public._expected_price('subscription_' || p_tier) - 0.01 THEN
    RAISE EXCEPTION 'Payment amount does not match subscription tier';
  END IF;

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- --------------------------------------------------------------------------
-- Fix 2 + 3: grant_ai_subscription — validates amount, pins search_path.
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.grant_ai_subscription(p_tier TEXT, p_payment_ref TEXT)
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_expiry TIMESTAMPTZ;
  v_row payment_transactions%ROWTYPE;
BEGIN
  IF p_tier NOT IN ('monthly', 'yearly') THEN
    RAISE EXCEPTION 'Invalid tier';
  END IF;

  v_row := public._consume_payment(p_payment_ref);

  IF v_row.amount < public._expected_price('ai_subscription_' || p_tier) - 0.01 THEN
    RAISE EXCEPTION 'Payment amount does not match subscription tier';
  END IF;

  v_expiry := now() + (CASE WHEN p_tier = 'monthly' THEN INTERVAL '30 days' ELSE INTERVAL '365 days' END);

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles SET ai_subscription_expiry = v_expiry WHERE id = auth.uid();

  RETURN v_expiry;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- --------------------------------------------------------------------------
-- Fix 2 + 3: grant_ai_credits — floor-rate amount check, pins search_path.
-- Floor matches the cheapest legitimate bundle today (150 credits / 1000
-- XAF, subscription_plans_screen.dart's "Student Pack") so any bundle at or
-- above that per-credit rate passes; revisit if a cheaper bundle ships.
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.grant_ai_credits(p_amount INT, p_payment_ref TEXT)
RETURNS INT AS $$
DECLARE
  v_new_credits INT;
  v_row payment_transactions%ROWTYPE;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Invalid credit amount';
  END IF;

  v_row := public._consume_payment(p_payment_ref);

  IF v_row.amount < (p_amount * (1000.0 / 150.0)) - 0.01 THEN
    RAISE EXCEPTION 'Payment amount too low for requested credits';
  END IF;

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles SET ai_credits = ai_credits + p_amount WHERE id = auth.uid()
    RETURNING ai_credits INTO v_new_credits;

  RETURN v_new_credits;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- --------------------------------------------------------------------------
-- Fix 3 only: remaining SECURITY DEFINER functions, no behavior change —
-- ALTER FUNCTION only, bodies untouched.
-- --------------------------------------------------------------------------
ALTER FUNCTION public.claim_free_trial() SET search_path = public, pg_temp;
ALTER FUNCTION public.increment_free_download_count() SET search_path = public, pg_temp;
ALTER FUNCTION public.complete_payment_transaction(TEXT, NUMERIC) SET search_path = public, pg_temp;
ALTER FUNCTION public.deduct_ai_credit(INT) SET search_path = public, pg_temp;
ALTER FUNCTION public.handle_profile_update() SET search_path = public, pg_temp;
ALTER FUNCTION public.handle_payment_transaction_update() SET search_path = public, pg_temp;
ALTER FUNCTION public.is_admin() SET search_path = public, pg_temp;
ALTER FUNCTION public.is_contributor() SET search_path = public, pg_temp;
ALTER FUNCTION public.is_authorized() SET search_path = public, pg_temp;
ALTER FUNCTION public.news_likes_count_sync() SET search_path = public, pg_temp;
ALTER FUNCTION public.news_comments_count_sync() SET search_path = public, pg_temp;
