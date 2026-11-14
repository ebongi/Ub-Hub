-- redeem_points_for_plan() used to set the tier and expiry to now() + term,
-- overwriting an active plan: a user with 300 days of yearly left who
-- redeemed a monthly plan was downgraded and lost ~270 paid days.
--
-- Now redemption EXTENDS whatever the user has: the new expiry is
-- GREATEST(current expiry, now()) + term, and an active higher tier is never
-- downgraded (an active yearly user redeeming 'monthly' stays yearly and just
-- gains 30 days; a monthly user redeeming 'yearly' is upgraded and gains 365).
--
-- Apply by hand in the Supabase SQL editor, like every other migration.

CREATE OR REPLACE FUNCTION public.redeem_points_for_plan(p_tier TEXT)
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cost INT;
  v_balance INT;
  v_cur_tier TEXT;
  v_cur_expiry TIMESTAMPTZ;
  v_active BOOLEAN;
  v_new_tier TEXT;
  v_expiry TIMESTAMPTZ;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  v_cost := CASE p_tier
    WHEN 'monthly' THEN 5000
    WHEN 'yearly' THEN 35000
    ELSE NULL
  END;
  IF v_cost IS NULL THEN
    RAISE EXCEPTION 'Invalid tier';
  END IF;

  -- Locks the caller's own row so two concurrent redemptions (double-tap)
  -- can't both read the same balance and both succeed.
  SELECT total_points, subscription_tier, subscription_expiry
    INTO v_balance, v_cur_tier, v_cur_expiry
    FROM profiles WHERE id = auth.uid() FOR UPDATE;
  IF v_balance IS NULL OR v_balance < v_cost THEN
    RAISE EXCEPTION 'Insufficient points: need %, have %', v_cost, COALESCE(v_balance, 0);
  END IF;

  v_active := v_cur_tier IN ('monthly', 'yearly')
              AND v_cur_expiry IS NOT NULL AND v_cur_expiry > now();

  -- Never downgrade an active yearly plan to monthly.
  v_new_tier := CASE
    WHEN v_active AND v_cur_tier = 'yearly' THEN 'yearly'
    ELSE p_tier
  END;

  v_expiry := (CASE WHEN v_active THEN v_cur_expiry ELSE now() END)
              + (CASE WHEN p_tier = 'monthly' THEN INTERVAL '30 days' ELSE INTERVAL '365 days' END);

  INSERT INTO points_ledger (user_id, event_type, points, metadata)
  VALUES (auth.uid(), 'plan_redeemed', -v_cost,
          jsonb_build_object('tier', p_tier, 'resulting_tier', v_new_tier));

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles
     SET subscription_tier = v_new_tier,
         subscription_expiry = v_expiry,
         subscription_is_trial = false,
         free_download_count = 0
   WHERE id = auth.uid();

  RETURN v_expiry;
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_points_for_plan(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_points_for_plan(TEXT) TO authenticated;
