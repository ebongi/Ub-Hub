-- Re-enables the hard paywall (disabled by disable_hard_paywall.sql for the
-- "Community Beta" phase), reconciled against the *current* trial model
-- (subscription_is_trial/trial_used/subscription_expiry) rather than the
-- old, retired 4-day/created_at-only logic from enforce_hard_paywall.sql.
CREATE OR REPLACE FUNCTION public.is_authorized()
RETURNS BOOLEAN AS $$
DECLARE
  v_role TEXT;
  v_tier TEXT;
  v_expiry TIMESTAMPTZ;
  v_created TIMESTAMPTZ;
BEGIN
  SELECT role, subscription_tier, subscription_expiry, created_at
    INTO v_role, v_tier, v_expiry, v_created
    FROM profiles WHERE id = auth.uid();

  IF v_role IN ('admin', 'contributor') THEN
    RETURN TRUE;
  END IF;

  -- Covers both paid tiers and the active free trial month (the trial sets
  -- subscription_tier='monthly' with subscription_is_trial=true, so no
  -- separate trial check is needed here).
  IF v_tier IS DISTINCT FROM 'free' AND v_expiry IS NOT NULL AND v_expiry > now() THEN
    RETURN TRUE;
  END IF;

  -- New-account grace window: keep in sync with Duration(days: 3) in
  -- UserProfile.hasAccess (lib/services/profile.dart) and its UserModel
  -- mirror (lib/Screens/Shared/constanst.dart).
  IF v_created IS NOT NULL AND (now() - v_created) < INTERVAL '3 days' THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- course_materials must NOT inherit this gate: it's pay-per-document and
-- needs unconditional browse/SELECT access so a paywalled user can still
-- see a material's price/fileUrl and start the Fapshi payment dialog. This
-- was the table's original baseline policy before enforce_hard_paywall.sql
-- put it behind is_authorized().
DROP POLICY IF EXISTS "Anyone can view materials" ON course_materials;
CREATE POLICY "Anyone can view materials" ON course_materials FOR SELECT USING (true);

-- exams/tasks/grades/bot_knowledge already call is_authorized() via
-- enforce_hard_paywall.sql's still-live policies — no changes needed there,
-- they pick up the new behavior automatically.
