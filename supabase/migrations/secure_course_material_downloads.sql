-- Closes the paywall/moderation-blocking bypass in course material storage.
-- Apply by hand in the Supabase SQL editor (same as the repo's other
-- migrations — this project doesn't use the CLI's migration tracking, see
-- the non-timestamped file names throughout supabase/migrations/).
--
-- Written and verified against the LIVE project schema (read-only queries
-- via `supabase db query --linked`), not just the migration files — those
-- have drifted from production. Notably:
--   * storage.objects already has two unconditionally-public SELECT
--     policies for this bucket ("Allow public read access", "Allow public
--     view course_materials") that no migration file here documents. These
--     MUST be dropped, not just added around — Postgres RLS policies are
--     OR'd, so a new restrictive policy alongside them would have done
--     nothing.
--   * payment_transactions already has a `consumed` boolean (guarded by
--     handle_payment_transaction_update) and a private helper,
--     _consume_payment(p_payment_ref), that atomically claims a successful,
--     not-yet-consumed payment. This migration reuses it rather than adding
--     a redundant column/mechanism.
--
-- Background: the `course_materials` Storage bucket is `public = true` and
-- (via the two policies above) explicitly public even independent of that
-- flag, while `course_materials` rows are `SELECT`-able by anyone. So
-- `file_url` — a plain public Storage path — can be turned into a working
-- download by any client holding only the app's anon key: no auth, no
-- payment, no free-download-count decrement. The entire Fapshi paywall in
-- material_download_actions.dart is client-side UI in front of a publicly
-- fetchable file; this migration makes the file itself only reachable
-- through a server-verified grant.
--
-- This is also a prerequisite for any future "pending, unmoderated
-- submission" state (hybrid content model): a public bucket means an
-- unreviewed upload is publicly fetchable the instant it lands in Storage,
-- regardless of what a `status` column says — moderation would be theater
-- without this fix first.
--
-- Mechanism: `course_materials.file_url` is repurposed to hold the bare
-- Storage object path (e.g. "course/CS101/notes.pdf") instead of a public
-- URL — existing rows are backfilled by stripping the public-URL prefix.
-- Reads of the bucket are gated by a `material_access_grants` ledger that
-- only a SECURITY DEFINER function can write to; the client calls
-- `request_material_access()` to get a grant + the storage path, then asks
-- Storage for a short-lived signed URL, which Storage itself authorizes
-- against the grant via the policy below. This is stateful (a real
-- consumed-once grant/payment) rather than a stateless RLS boolean, so it
-- can't be satisfied by re-reading profile counters without ever calling
-- the function that decrements them.

-- ==========================================================================
-- 1. Re-point file_url at the bare storage path instead of a public URL.
--    Idempotent: only rewrites rows that still look like a full URL. Also
--    undoes the percent-encoding getPublicUrl() applied (storage.objects.name
--    holds the literal, decoded path) — verified against every live row:
--    the only encoded sequence in production data is "%20" (space), and the
--    transform below resolves all 116/116 existing rows to a real storage
--    object. New uploads never go through getPublicUrl() any more (see
--    DatabaseService.uploadMaterialFile), so this is purely historical.
-- ==========================================================================
UPDATE course_materials
   SET file_url = replace(regexp_replace(file_url, '^.*/course_materials/', ''), '%20', ' ')
 WHERE file_url LIKE 'http%/course_materials/%';

-- ==========================================================================
-- 2. Access grant ledger. No INSERT/UPDATE/DELETE policy is defined for any
--    role — the only way to write a row is through request_material_access()
--    below, which runs SECURITY DEFINER and so bypasses RLS entirely. Users
--    may only ever read their own grants (for debugging/support, not relied
--    on by the app).
-- ==========================================================================
CREATE TABLE IF NOT EXISTS material_access_grants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES course_materials(id) ON DELETE CASCADE,
    granted_via TEXT NOT NULL CHECK (granted_via IN ('owner', 'admin', 'free_credit', 'payment')),
    payment_ref TEXT,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_material_access_grants_lookup
    ON material_access_grants(user_id, material_id, expires_at);

ALTER TABLE material_access_grants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own grants" ON material_access_grants;
CREATE POLICY "Users can view own grants" ON material_access_grants
    FOR SELECT USING (auth.uid() = user_id);

-- ==========================================================================
-- 3. request_material_access() — the single place that decides whether a
--    user may read a material's file, mirroring
--    UserProfile.hasUnlimitedDownloads / SubscriptionService.canDownloadForFree
--    (lib/services/subscription_service.dart) plus the owner/admin exemption
--    already used throughout DatabaseService. Keep the "5" and the
--    tier/trial checks in sync with that file if it changes.
--
--    Returns the storage path to fetch and when the grant expires; the
--    client turns that into an actual signed URL via
--    supabase.storage.from('course_materials').createSignedUrl(...), which
--    Storage authorizes against the policy in step 4.
-- ==========================================================================
CREATE OR REPLACE FUNCTION public.request_material_access(
    p_material_id UUID,
    p_payment_ref TEXT DEFAULT NULL
)
RETURNS TABLE(storage_path TEXT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_path TEXT;
    v_uploader UUID;
    v_role TEXT;
    v_sub_tier TEXT;
    v_sub_expiry TIMESTAMPTZ;
    v_free_count BIGINT;
    v_unlimited BOOLEAN;
    v_expires TIMESTAMPTZ := now() + INTERVAL '10 minutes';
    v_payment payment_transactions%ROWTYPE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT cm.file_url, cm.uploader_id INTO v_path, v_uploader
    FROM course_materials cm WHERE cm.id = p_material_id;

    IF v_path IS NULL OR v_path = '' THEN
        RAISE EXCEPTION 'Material not found or has no stored file';
    END IF;

    -- Owner or admin: always allowed, no credit/payment consumed.
    IF is_admin() OR v_uploader = v_uid THEN
        INSERT INTO material_access_grants (user_id, material_id, granted_via, expires_at)
        VALUES (v_uid, p_material_id, CASE WHEN is_admin() THEN 'admin' ELSE 'owner' END, v_expires);
        RETURN QUERY SELECT v_path, v_expires;
        RETURN;
    END IF;

    SELECT p.role, p.subscription_tier, p.subscription_expiry, p.free_download_count
      INTO v_role, v_sub_tier, v_sub_expiry, v_free_count
    FROM profiles p WHERE p.id = v_uid;

    -- Matches UserProfile.hasUnlimitedDownloads (contributor role, or an
    -- active paid/trial subscription — trials also carry subscription_tier
    -- <> 'free', see shorten_free_trial_to_two_weeks.sql).
    v_unlimited := v_role = 'contributor'
        OR (v_sub_tier IS DISTINCT FROM 'free' AND v_sub_expiry IS NOT NULL AND v_sub_expiry > now());

    IF v_unlimited OR COALESCE(v_free_count, 0) < 5 THEN
        IF NOT v_unlimited THEN
            -- Same atomic increment the client used to call directly; now
            -- the only path that can grant a read, so it can't be skipped.
            PERFORM public.increment_free_download_count();
        END IF;
        INSERT INTO material_access_grants (user_id, material_id, granted_via, expires_at)
        VALUES (v_uid, p_material_id, 'free_credit', v_expires);
        RETURN QUERY SELECT v_path, v_expires;
        RETURN;
    END IF;

    -- Paid path: reuse the existing generic payment-redemption helper
    -- (claims the row atomically, raises if missing/not-success/already
    -- consumed) and check it's actually a payment for THIS material.
    IF p_payment_ref IS NULL THEN
        RAISE EXCEPTION 'Payment required';
    END IF;

    v_payment := public._consume_payment(p_payment_ref);

    IF v_payment.item_type <> 'download' OR v_payment.material_id IS DISTINCT FROM p_material_id THEN
        RAISE EXCEPTION 'Payment does not match this material';
    END IF;

    INSERT INTO material_access_grants (user_id, material_id, granted_via, payment_ref, expires_at)
    VALUES (v_uid, p_material_id, 'payment', p_payment_ref, v_expires);
    RETURN QUERY SELECT v_path, v_expires;
END;
$$;

REVOKE ALL ON FUNCTION public.request_material_access(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_material_access(UUID, TEXT) TO authenticated;

-- ==========================================================================
-- 4. Bucket lockdown + read policy. Storage authorizes createSignedUrl()
--    calls against storage.objects SELECT, so this is the real enforcement
--    point: a signed URL can only be minted for an object with a live,
--    matching grant. Must drop the pre-existing blanket-public policies —
--    see the file header; leaving them in place would make the new
--    restrictive policy a no-op (RLS policies are OR'd).
-- ==========================================================================
UPDATE storage.buckets SET public = false WHERE id = 'course_materials';

DROP POLICY IF EXISTS "Allow public read access" ON storage.objects;
DROP POLICY IF EXISTS "Allow public view course_materials" ON storage.objects;
-- "Allow public read access" also covered department_images, which should
-- stay public; "Allow public view department_images" already grants that
-- independently, so nothing further is needed for it.

DROP POLICY IF EXISTS "Read granted material files" ON storage.objects;
CREATE POLICY "Read granted material files" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'course_materials'
        AND EXISTS (
            SELECT 1 FROM material_access_grants g
            JOIN course_materials cm ON cm.id = g.material_id
            WHERE g.user_id = auth.uid()
              AND g.expires_at > now()
              AND cm.file_url = storage.objects.name
        )
    );

-- ==========================================================================
-- 5. Fix the dormant, currently-broken self-upgrade-to-contributor path.
--    handle_profile_update's role guard (live-verified) reverts any
--    non-admin role change unconditionally — it doesn't check
--    app.bypass_subscription_guard the way the subscription/credit columns
--    do, so even a SECURITY DEFINER grant function couldn't change role
--    without this. Extend the guard, then add the grant function.
--    DatabaseService.upgradeUserToContributor() currently does a raw client
--    UPDATE and has no caller anywhere in the app — silently a no-op today.
-- ==========================================================================
CREATE OR REPLACE FUNCTION public.handle_profile_update()
RETURNS TRIGGER AS $$
DECLARE
  v_bypass BOOLEAN := COALESCE(current_setting('app.bypass_subscription_guard', true), 'false')::boolean;
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role AND NOT is_admin() AND NOT v_bypass THEN
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

CREATE OR REPLACE FUNCTION public.grant_contributor_role(p_payment_ref TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_payment payment_transactions%ROWTYPE;
BEGIN
  v_payment := public._consume_payment(p_payment_ref);

  IF v_payment.item_type <> 'contributor_upgrade' THEN
    RAISE EXCEPTION 'Payment is not a contributor upgrade';
  END IF;

  PERFORM set_config('app.bypass_subscription_guard', 'true', true);

  UPDATE profiles
     SET role = 'contributor', upgraded_at = now()
   WHERE id = auth.uid() AND role = 'viewer';
END;
$$;

REVOKE ALL ON FUNCTION public.grant_contributor_role(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.grant_contributor_role(TEXT) TO authenticated;
