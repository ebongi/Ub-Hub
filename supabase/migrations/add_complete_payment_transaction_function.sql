-- Server-side-only: the *only* path through which a payment_transactions
-- row can ever reach status='success'. Called exclusively by the
-- fapshi-proxy edge function (via its service-role client) after it has
-- independently re-confirmed the payment with Fapshi's own API — so a
-- client can never grant itself a 'success' row by forging a REST write
-- (see harden_subscription_and_payment_writes.sql's trigger, which blocks
-- clients from setting status to anything but failed/cancelled).
--
-- Fails closed: any row not found, already resolved (idempotent no-op), or
-- with a mismatched amount leaves the row untouched / raises, so no
-- entitlement is ever granted without a verified server-side amount match.
CREATE OR REPLACE FUNCTION public.complete_payment_transaction(p_fapshi_trans_id TEXT, p_amount NUMERIC)
RETURNS VOID AS $$
DECLARE
  v_row payment_transactions%ROWTYPE;
BEGIN
  SELECT * INTO v_row FROM payment_transactions
    WHERE fapshi_trans_id = p_fapshi_trans_id
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No payment_transactions row for fapshi_trans_id %', p_fapshi_trans_id;
  END IF;

  IF v_row.status <> 'pending' THEN
    RETURN; -- already resolved; idempotent no-op so repeated polls are safe
  END IF;

  IF ABS(v_row.amount - p_amount) > 0.01 THEN
    RAISE EXCEPTION 'Amount mismatch for %: expected %, got %', v_row.payment_ref, v_row.amount, p_amount;
  END IF;

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE payment_transactions
     SET status = 'success', updated_at = now()
   WHERE id = v_row.id AND status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION public.complete_payment_transaction(TEXT, NUMERIC) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_payment_transaction(TEXT, NUMERIC) TO service_role;
