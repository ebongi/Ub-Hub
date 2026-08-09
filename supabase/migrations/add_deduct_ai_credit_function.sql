-- DatabaseService.useAICredit previously did a read-then-write from Dart
-- (SELECT ai_credits, decide in the client, then UPDATE with the computed
-- value) which is not atomic: two concurrent AI requests for the same user
-- could both read the same starting balance and both pass the check,
-- letting a user with 1 credit get 2+ AI actions through. Move the
-- check-and-deduct into a single atomic Postgres operation instead.

CREATE OR REPLACE FUNCTION public.deduct_ai_credit(p_amount INT)
RETURNS VOID AS $$
DECLARE
  v_role TEXT;
  v_ai_expiry TIMESTAMPTZ;
  v_updated INT;
BEGIN
  SELECT role, ai_subscription_expiry INTO v_role, v_ai_expiry
    FROM profiles WHERE id = auth.uid();

  -- Admin or active Unlimited AI subscription - no deduction
  IF v_role = 'admin' THEN
    RETURN;
  END IF;
  IF v_ai_expiry IS NOT NULL AND v_ai_expiry > now() THEN
    RETURN;
  END IF;

  UPDATE profiles
     SET ai_credits = ai_credits - p_amount
   WHERE id = auth.uid() AND ai_credits >= p_amount;

  GET DIAGNOSTICS v_updated = ROW_COUNT;

  IF v_updated = 0 THEN
    RAISE EXCEPTION 'Insufficient AI credits';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.deduct_ai_credit(INT) TO authenticated;
