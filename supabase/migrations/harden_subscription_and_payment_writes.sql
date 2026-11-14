-- Closes the RLS gap that let any authenticated user grant themselves a
-- subscription/AI credits/etc. by writing directly to their own `profiles`
-- row via the REST API, and the matching gap on `payment_transactions`
-- that let a user mark their own pending payment 'success' without Fapshi
-- ever confirming it.
--
-- Mechanism: a BEFORE UPDATE trigger on each table reverts any change to
-- the protected columns back to their OLD value, UNLESS the session-local
-- GUC `app.bypass_subscription_guard` is set to 'true'. That GUC is only
-- ever set (via `set_config(..., true)`, so it's transaction-scoped and
-- never leaks) inside the SECURITY DEFINER functions that perform
-- legitimate mutations (add_payment_grant_functions.sql,
-- add_complete_payment_transaction_function.sql, and the patched
-- deduct_ai_credit below) — a plain client UPDATE can never set it.

-- 1. Extend the existing profiles trigger (previously only protected `role`).
CREATE OR REPLACE FUNCTION public.handle_profile_update()
RETURNS TRIGGER AS $$
DECLARE
  v_bypass BOOLEAN := COALESCE(current_setting('app.bypass_subscription_guard', true), 'false')::boolean;
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role AND NOT is_admin() THEN
    NEW.role := OLD.role;
  END IF;

  IF NOT v_bypass AND NOT is_admin() THEN
    IF NEW.ai_credits IS DISTINCT FROM OLD.ai_credits THEN NEW.ai_credits := OLD.ai_credits; END IF;
    IF NEW.subscription_tier IS DISTINCT FROM OLD.subscription_tier THEN NEW.subscription_tier := OLD.subscription_tier; END IF;
    IF NEW.subscription_expiry IS DISTINCT FROM OLD.subscription_expiry THEN NEW.subscription_expiry := OLD.subscription_expiry; END IF;
    IF NEW.subscription_is_trial IS DISTINCT FROM OLD.subscription_is_trial THEN NEW.subscription_is_trial := OLD.subscription_is_trial; END IF;
    IF NEW.trial_used IS DISTINCT FROM OLD.trial_used THEN NEW.trial_used := OLD.trial_used; END IF;
    IF NEW.ai_subscription_expiry IS DISTINCT FROM OLD.ai_subscription_expiry THEN NEW.ai_subscription_expiry := OLD.ai_subscription_expiry; END IF;
    IF NEW.free_download_count IS DISTINCT FROM OLD.free_download_count THEN NEW.free_download_count := OLD.free_download_count; END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Trigger `on_profile_update` (admin_management_policies.sql) already points
-- at this function; no need to re-create it.

-- 2. Patch deduct_ai_credit so it survives the new guard above (it performs
-- a legitimate ai_credits UPDATE and must be exempted, same as every other
-- grant function below).
CREATE OR REPLACE FUNCTION public.deduct_ai_credit(p_amount INT)
RETURNS VOID AS $$
DECLARE
  v_role TEXT;
  v_ai_expiry TIMESTAMPTZ;
  v_updated INT;
BEGIN
  SELECT role, ai_subscription_expiry INTO v_role, v_ai_expiry
    FROM profiles WHERE id = auth.uid();

  IF v_role = 'admin' THEN
    RETURN;
  END IF;
  IF v_ai_expiry IS NOT NULL AND v_ai_expiry > now() THEN
    RETURN;
  END IF;

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles
     SET ai_credits = ai_credits - p_amount
   WHERE id = auth.uid() AND ai_credits >= p_amount;

  GET DIAGNOSTICS v_updated = ROW_COUNT;

  IF v_updated = 0 THEN
    RAISE EXCEPTION 'Insufficient AI credits';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. payment_transactions: keep ownership in RLS, move value/column
-- restriction into a trigger (mirrors the profiles approach above).
DROP POLICY IF EXISTS "Users can update own payments" ON payment_transactions;
CREATE POLICY "Users can update own pending payments"
ON payment_transactions FOR UPDATE
USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.handle_payment_transaction_update()
RETURNS TRIGGER AS $$
DECLARE
  v_bypass BOOLEAN := COALESCE(current_setting('app.bypass_subscription_guard', true), 'false')::boolean;
BEGIN
  IF v_bypass THEN
    RETURN NEW;
  END IF;

  -- Clients may only ever move a row from pending to failed/cancelled
  -- themselves (e.g. to record a timeout) — the success transition is only
  -- ever performed server-side, by complete_payment_transaction.
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF OLD.status <> 'pending' OR NEW.status NOT IN ('failed', 'cancelled') THEN
      NEW.status := OLD.status;
    END IF;
  END IF;

  IF NEW.consumed IS DISTINCT FROM OLD.consumed THEN NEW.consumed := OLD.consumed; END IF;
  IF NEW.amount IS DISTINCT FROM OLD.amount THEN NEW.amount := OLD.amount; END IF;
  IF NEW.user_id IS DISTINCT FROM OLD.user_id THEN NEW.user_id := OLD.user_id; END IF;
  IF NEW.payment_ref IS DISTINCT FROM OLD.payment_ref THEN NEW.payment_ref := OLD.payment_ref; END IF;

  -- fapshi_trans_id is write-once: settable only while still NULL and the
  -- row is still pending, so it can only ever be attached by the same
  -- collectPayment call that created the row.
  IF NEW.fapshi_trans_id IS DISTINCT FROM OLD.fapshi_trans_id THEN
    IF OLD.fapshi_trans_id IS NOT NULL OR OLD.status <> 'pending' THEN
      NEW.fapshi_trans_id := OLD.fapshi_trans_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_payment_transaction_update ON payment_transactions;
CREATE TRIGGER on_payment_transaction_update
  BEFORE UPDATE ON payment_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_payment_transaction_update();
