-- Admin subscription/entitlement management for the new Control Center.
--
-- Every legitimate mutation of the money columns on `profiles`
-- (subscription_tier, subscription_expiry, subscription_is_trial,
-- trial_used, ai_subscription_expiry, ai_credits, free_download_count) goes
-- through a SECURITY DEFINER RPC that sets `app.bypass_subscription_guard`
-- before writing (see add_payment_grant_functions.sql /
-- fix_payment_grant_integrity.sql / harden_subscription_and_payment_writes.sql)
-- — but every existing one of those operates on `auth.uid()` only. These are
-- the first RPCs that let an admin act on a *target* user id, so each one
-- starts with an explicit `is_admin()` check (unlike the auth.uid()-scoped
-- functions, there's no implicit ownership check to fall back on).
--
-- search_path is pinned on every function per fix_payment_grant_integrity.sql's
-- fix 3 (a known Postgres SECURITY DEFINER privilege-escalation vector).

-- --------------------------------------------------------------------------
-- Shared audit helper: records a zero-amount, pre-consumed payment_transactions
-- row for a grant so it shows up in the admin transactions list, but can
-- never be replayed through _consume_payment (consumed is already true) and
-- never inflates revenue sums (amount is 0).
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public._admin_log_grant(p_user_id UUID, p_item_type TEXT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO payment_transactions (user_id, payment_ref, amount, currency, status, item_type, consumed)
  VALUES (p_user_id, 'admin_grant_' || gen_random_uuid()::text, 0, 'XAF', 'success', p_item_type, true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION public._admin_log_grant(UUID, TEXT) FROM PUBLIC;

-- --------------------------------------------------------------------------
-- App Plan (subscription_tier/subscription_expiry) grant/extend/revoke.
-- p_tier = 'free' revokes. Otherwise grants p_days from now, or from the
-- current expiry (whichever is later) when p_extend is true.
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_set_subscription(
  p_user_id UUID,
  p_tier TEXT,
  p_days INT DEFAULT 0,
  p_is_trial BOOLEAN DEFAULT false,
  p_extend BOOLEAN DEFAULT false
)
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_expiry TIMESTAMPTZ;
  v_current_expiry TIMESTAMPTZ;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  IF p_tier NOT IN ('free', 'monthly', 'yearly') THEN
    RAISE EXCEPTION 'Invalid tier';
  END IF;

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  IF p_tier = 'free' THEN
    UPDATE profiles
       SET subscription_tier = 'free',
           subscription_expiry = NULL,
           subscription_is_trial = false
     WHERE id = p_user_id;

    RETURN NULL;
  END IF;

  IF p_days <= 0 THEN
    RAISE EXCEPTION 'p_days must be positive when granting a tier';
  END IF;

  SELECT subscription_expiry INTO v_current_expiry FROM profiles WHERE id = p_user_id;
  v_expiry := (CASE WHEN p_extend THEN GREATEST(now(), COALESCE(v_current_expiry, now())) ELSE now() END)
              + (p_days || ' days')::interval;

  UPDATE profiles
     SET subscription_tier = p_tier,
         subscription_expiry = v_expiry,
         subscription_is_trial = p_is_trial,
         free_download_count = 0
   WHERE id = p_user_id;

  PERFORM public._admin_log_grant(p_user_id, 'admin_grant_subscription');

  RETURN v_expiry;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION public.admin_set_subscription(UUID, TEXT, INT, BOOLEAN, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_subscription(UUID, TEXT, INT, BOOLEAN, BOOLEAN) TO authenticated;

-- --------------------------------------------------------------------------
-- Unlimited AI subscription grant/extend/revoke. p_days = 0 revokes.
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_set_ai_subscription(
  p_user_id UUID,
  p_days INT,
  p_extend BOOLEAN DEFAULT false
)
RETURNS TIMESTAMPTZ AS $$
DECLARE
  v_expiry TIMESTAMPTZ;
  v_current_expiry TIMESTAMPTZ;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  IF p_days <= 0 THEN
    UPDATE profiles SET ai_subscription_expiry = NULL WHERE id = p_user_id;
    RETURN NULL;
  END IF;

  SELECT ai_subscription_expiry INTO v_current_expiry FROM profiles WHERE id = p_user_id;
  v_expiry := (CASE WHEN p_extend THEN GREATEST(now(), COALESCE(v_current_expiry, now())) ELSE now() END)
              + (p_days || ' days')::interval;

  UPDATE profiles SET ai_subscription_expiry = v_expiry WHERE id = p_user_id;

  PERFORM public._admin_log_grant(p_user_id, 'admin_grant_ai_subscription');

  RETURN v_expiry;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION public.admin_set_ai_subscription(UUID, INT, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_ai_subscription(UUID, INT, BOOLEAN) TO authenticated;

-- --------------------------------------------------------------------------
-- AI credit balance adjustment (positive or negative delta). Floors at 0.
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_adjust_ai_credits(p_user_id UUID, p_delta INT)
RETURNS INT AS $$
DECLARE
  v_new_credits INT;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles SET ai_credits = GREATEST(0, ai_credits + p_delta) WHERE id = p_user_id
    RETURNING ai_credits INTO v_new_credits;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  PERFORM public._admin_log_grant(p_user_id, 'admin_adjust_ai_credits');

  RETURN v_new_credits;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION public.admin_adjust_ai_credits(UUID, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_adjust_ai_credits(UUID, INT) TO authenticated;

-- --------------------------------------------------------------------------
-- Reset a user's free-download counter back to 0.
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_reset_free_downloads(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles SET free_download_count = 0 WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION public.admin_reset_free_downloads(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_reset_free_downloads(UUID) TO authenticated;

-- --------------------------------------------------------------------------
-- Let a user reclaim their free trial (flips trial_used back to false; the
-- user still has to go through claim_free_trial() themselves to activate it).
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_reset_trial_eligibility(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles SET trial_used = false WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION public.admin_reset_trial_eligibility(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_reset_trial_eligibility(UUID) TO authenticated;

-- --------------------------------------------------------------------------
-- Revenue summary for the Subscriptions tab. Admin-only aggregate over
-- payment_transactions; amount=0 admin-grant rows contribute nothing.
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_revenue_summary()
RETURNS TABLE(total_revenue NUMERIC, month_revenue NUMERIC, successful_count INT) AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(SUM(amount) FILTER (WHERE status = 'success'), 0) AS total_revenue,
    COALESCE(SUM(amount) FILTER (WHERE status = 'success' AND created_at >= date_trunc('month', now())), 0) AS month_revenue,
    COUNT(*) FILTER (WHERE status = 'success')::INT AS successful_count
  FROM payment_transactions;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION public.admin_revenue_summary() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_revenue_summary() TO authenticated;

-- --------------------------------------------------------------------------
-- Let admins see every transaction (not just their own) for the Subscriptions
-- tab's transaction list. Postgres OR's multiple permissive SELECT policies
-- together, so the existing owner-only policy is untouched.
-- --------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins can view all transactions" ON payment_transactions;
CREATE POLICY "Admins can view all transactions"
ON payment_transactions FOR SELECT
USING (is_admin());
