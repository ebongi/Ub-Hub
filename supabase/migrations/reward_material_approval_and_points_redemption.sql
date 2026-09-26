-- UGC points on approval + point-funded plan redemption.
-- Apply by hand in the Supabase SQL editor (see
-- secure_course_material_downloads.sql for why this repo doesn't use the
-- CLI's migration tracking).
--
-- Golden rule: a submitter earns points only when their material transitions
-- pending -> published. That transition has exactly one path in this schema
-- — moderate_material() (hybrid_content_moderation.sql), guarded by
-- `WHERE status = 'pending'` — so extending that single atomic UPDATE is
-- what gives "exactly once" for free, with no separate idempotency table.
-- (addMaterial()'s immediate `award_points('material_uploaded')` call is
-- unrelated and untouched: that only ever fires for contributors/admins,
-- whose uploads are auto-published, so upload == publish for them.)

-- ==========================================================================
-- 1. courses.bounty_multiplier — admin-settable per-course reward boost
--    ("Bounty (+2x Points)"). Default 1 (no boost) for every existing row.
--    No new RLS needed: "Admins can manage courses" (FOR ALL) already
--    covers UPDATE of this column, and non-admins have no UPDATE policy on
--    courses at all (restrict_content_creation_to_admins.sql).
-- ==========================================================================
ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS bounty_multiplier NUMERIC NOT NULL DEFAULT 1
    CHECK (bounty_multiplier > 0);

-- ==========================================================================
-- 2. moderate_material() — now RETURNS INT (points awarded to the
--    submitter; 0 on reject, or on approve if the submitter's rolling 24h
--    reward cap was already hit). The point VALUE is always computed here,
--    same trust boundary as award_points() — the calling admin never
--    supplies it. Credits the material's uploader_id, not auth.uid()
--    (auth.uid() here is the approving admin) — this is exactly the gap
--    flagged in DatabaseService._broadcastNewMaterial's comment.
-- ==========================================================================
CREATE OR REPLACE FUNCTION public.moderate_material(
    p_material_id UUID,
    p_decision TEXT,
    p_reason TEXT DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uploader_id UUID;
  v_course_id UUID;
  v_multiplier NUMERIC := 1;
  v_points INT := 0;
  v_recent_awards INT;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only admins can moderate materials';
  END IF;
  IF p_decision NOT IN ('approve', 'reject') THEN
    RAISE EXCEPTION 'decision must be ''approve'' or ''reject''';
  END IF;

  -- Same single atomic UPDATE as before (WHERE status = 'pending' is what
  -- makes a double-approve a no-op) — just also captures who to credit.
  UPDATE course_materials
     SET status = CASE WHEN p_decision = 'approve' THEN 'published' ELSE 'rejected' END,
         rejection_reason = CASE WHEN p_decision = 'reject' THEN p_reason ELSE NULL END,
         reviewed_by = auth.uid(),
         reviewed_at = now()
   WHERE id = p_material_id AND status = 'pending'
  RETURNING uploader_id, course_id INTO v_uploader_id, v_course_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Material not found or not pending review';
  END IF;

  IF p_decision = 'approve' AND v_uploader_id IS NOT NULL THEN
    IF v_course_id IS NOT NULL THEN
      SELECT COALESCE(bounty_multiplier, 1) INTO v_multiplier
        FROM courses WHERE id = v_course_id;
    END IF;

    -- Anti-abuse cap: max 5 approval rewards per user in a rolling 24h
    -- window (deliberately rolling, not calendar-day like award_points'
    -- caps — an admin approving a backlog shouldn't let someone straddle
    -- midnight for 10 in a row).
    SELECT COUNT(*) INTO v_recent_awards
      FROM points_ledger
     WHERE user_id = v_uploader_id
       AND event_type = 'material_approved'
       AND created_at >= now() - INTERVAL '24 hours';

    IF v_recent_awards < 5 THEN
      v_points := ROUND(50 * v_multiplier)::INT;
      INSERT INTO points_ledger (user_id, event_type, points, metadata)
      VALUES (
        v_uploader_id,
        'material_approved',
        v_points,
        jsonb_build_object('material_id', p_material_id, 'multiplier', v_multiplier)
      );
      -- profiles.total_points stays in sync via trg_points_ledger_total_sync.
    END IF;
  END IF;

  RETURN v_points;
END;
$$;

REVOKE ALL ON FUNCTION public.moderate_material(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.moderate_material(UUID, TEXT, TEXT) TO authenticated;

-- ==========================================================================
-- 3. redeem_points_for_plan() — spends accumulated points on the same App
--    Plan tiers Fapshi payments grant (grant_subscription() in
--    add_payment_grant_functions.sql), without a payment_transactions row.
--    Mirrors grant_subscription()'s bypass-guard mechanism (see
--    harden_subscription_and_payment_writes.sql) since it legitimately
--    writes profiles.subscription_*.
--
--    Points are spent via a negative points_ledger row rather than a direct
--    profiles.total_points UPDATE — that keeps every point movement
--    (earned or spent) in the one append-only, auditable ledger, and reuses
--    its existing trigger to keep total_points in sync.
--
--    Costs below are a first cut (10 points ~ 1 XAF, matching
--    SubscriptionService.monthlyPrice/yearlyPrice) — tune
--    v_cost as the actual redemption economics are decided.
-- ==========================================================================
CREATE OR REPLACE FUNCTION public.redeem_points_for_plan(p_tier TEXT)
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cost INT;
  v_balance INT;
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
  SELECT total_points INTO v_balance FROM profiles WHERE id = auth.uid() FOR UPDATE;
  IF v_balance IS NULL OR v_balance < v_cost THEN
    RAISE EXCEPTION 'Insufficient points: need %, have %', v_cost, COALESCE(v_balance, 0);
  END IF;

  v_expiry := now() + (CASE WHEN p_tier = 'monthly' THEN INTERVAL '30 days' ELSE INTERVAL '365 days' END);

  INSERT INTO points_ledger (user_id, event_type, points, metadata)
  VALUES (auth.uid(), 'plan_redeemed', -v_cost, jsonb_build_object('tier', p_tier));

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles
     SET subscription_tier = p_tier,
         subscription_expiry = v_expiry,
         subscription_is_trial = false,
         free_download_count = 0
   WHERE id = auth.uid();

  RETURN v_expiry;
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_points_for_plan(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_points_for_plan(TEXT) TO authenticated;
