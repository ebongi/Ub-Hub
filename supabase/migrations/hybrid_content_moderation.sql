-- Phase 1 of the hybrid content model: adds a pending/published/rejected
-- lifecycle to course_materials so regular students can submit content for
-- admin review, while contributors (Class Reps) and admins still publish
-- immediately — see the architecture proposal for the full design.
-- Apply by hand in the Supabase SQL editor (see
-- secure_course_material_downloads.sql for why this repo doesn't use the
-- CLI's migration tracking).
--
-- Verified against the LIVE schema first (course_materials.file_hash
-- already exists, unused — reused here rather than re-added; no
-- status/rejection_reason/reviewed_by/reviewed_at columns or moderation
-- function exist yet).
--
-- Depends on secure_course_material_downloads.sql (course_materials.file_url
-- holding a bare storage path, is_admin()) already being applied.

-- ==========================================================================
-- 1. New columns. status defaults to 'published' so all 116 existing rows
--    (implicitly admin-uploaded under the old admin-only INSERT policy)
--    stay visible with no backfill needed.
-- ==========================================================================
ALTER TABLE course_materials
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'published'
    CHECK (status IN ('pending', 'published', 'rejected')),
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
  ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_course_materials_status ON course_materials(status);

-- ==========================================================================
-- 2. INSERT: open to any authenticated user (was admin-only). What actually
--    happens on submit — auto-publish vs. pending — is decided server-side
--    by the trigger below, not by what the client sends, so a client can't
--    just set status: 'published' on insert to skip review.
-- ==========================================================================
DROP POLICY IF EXISTS "Admins can upload materials" ON course_materials;
CREATE POLICY "Authenticated users can submit materials" ON course_materials
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE OR REPLACE FUNCTION public.handle_course_material_insert()
RETURNS TRIGGER AS $$
DECLARE
  v_role TEXT;
BEGIN
  -- Not client-spoofable: whoever is actually inserting is the uploader.
  NEW.uploader_id := auth.uid();

  SELECT role INTO v_role FROM profiles WHERE id = auth.uid();

  NEW.status := CASE WHEN v_role IN ('contributor', 'admin') THEN 'published' ELSE 'pending' END;
  NEW.rejection_reason := NULL;
  NEW.reviewed_by := NULL;
  NEW.reviewed_at := NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS on_course_material_insert ON course_materials;
CREATE TRIGGER on_course_material_insert
    BEFORE INSERT ON course_materials
    FOR EACH ROW EXECUTE FUNCTION public.handle_course_material_insert();

-- ==========================================================================
-- 3. UPDATE guard: the existing "Uploaders or admins can update materials" /
--    "Users can update their own materials" policies let an uploader UPDATE
--    their own row with no column restriction (USING only, no WITH CHECK) —
--    without this, a student could just set status: 'published' on their
--    own pending row directly. Only admins may touch the moderation columns
--    or reassign uploader_id; is_admin() alone is enough here (no bypass GUC
--    needed, since the only legitimate caller — moderate_material() below —
--    always runs as a real admin's own auth.uid()).
-- ==========================================================================
CREATE OR REPLACE FUNCTION public.handle_course_material_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT is_admin() THEN
    IF NEW.status IS DISTINCT FROM OLD.status THEN NEW.status := OLD.status; END IF;
    IF NEW.rejection_reason IS DISTINCT FROM OLD.rejection_reason THEN NEW.rejection_reason := OLD.rejection_reason; END IF;
    IF NEW.reviewed_by IS DISTINCT FROM OLD.reviewed_by THEN NEW.reviewed_by := OLD.reviewed_by; END IF;
    IF NEW.reviewed_at IS DISTINCT FROM OLD.reviewed_at THEN NEW.reviewed_at := OLD.reviewed_at; END IF;
    IF NEW.uploader_id IS DISTINCT FROM OLD.uploader_id THEN NEW.uploader_id := OLD.uploader_id; END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS on_course_material_update ON course_materials;
CREATE TRIGGER on_course_material_update
    BEFORE UPDATE ON course_materials
    FOR EACH ROW EXECUTE FUNCTION public.handle_course_material_update();

-- ==========================================================================
-- 4. SELECT: pending/rejected submissions are only visible to their
--    submitter and admins — everyone else only sees published materials.
--    Must drop BOTH existing USING(true) policies (RLS is OR'd — see
--    secure_course_material_downloads.sql for why leaving either in place
--    would make this a no-op), confirmed live as exactly these two names.
-- ==========================================================================
DROP POLICY IF EXISTS "Allow authenticated select materials" ON course_materials;
DROP POLICY IF EXISTS "Anyone can view materials" ON course_materials;
CREATE POLICY "View published or own materials" ON course_materials
    FOR SELECT USING (status = 'published' OR uploader_id = auth.uid() OR is_admin());

-- ==========================================================================
-- 5. moderate_material() — the only way a pending submission becomes
--    published or rejected. Admin-only; stamps the reviewer and timestamp.
--    Notifying the submitter is left to the calling UI (mirrors how
--    DatabaseService.addMaterial's broadcast is done from Dart, not SQL,
--    everywhere else in this schema).
-- ==========================================================================
CREATE OR REPLACE FUNCTION public.moderate_material(
    p_material_id UUID,
    p_decision TEXT,
    p_reason TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only admins can moderate materials';
  END IF;
  IF p_decision NOT IN ('approve', 'reject') THEN
    RAISE EXCEPTION 'decision must be ''approve'' or ''reject''';
  END IF;

  UPDATE course_materials
     SET status = CASE WHEN p_decision = 'approve' THEN 'published' ELSE 'rejected' END,
         rejection_reason = CASE WHEN p_decision = 'reject' THEN p_reason ELSE NULL END,
         reviewed_by = auth.uid(),
         reviewed_at = now()
   WHERE id = p_material_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Material not found or not pending review';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.moderate_material(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.moderate_material(UUID, TEXT, TEXT) TO authenticated;
