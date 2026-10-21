-- Restricts course-material uploads, department creation, and course
-- creation to admins only, and closes a gap in bot_knowledge's "global"
-- flag. Apply by hand in the Supabase SQL editor (same as the repo's other
-- migrations).
--
-- Background: course_materials/departments/courses previously allowed ANY
-- authenticated user to INSERT at the RLS layer (`auth.uid() IS NOT NULL`)
-- — the Flutter UI already hid the create affordance from non-admins for
-- departments/courses, but that was a client-side-only restriction; a
-- direct API call from any signed-in session could still create rows.
-- Course material uploads had no client-side restriction either
-- (`UserProfile.canUploadMaterial` was hardcoded `true`). This migration
-- makes the RLS match "admins only" for all three, matching the app's
-- actual product intent.

-- ==========================================================================
-- 1. course_materials — creation is now admin-only. Update/delete stays
--    "uploader OR admin" (unchanged, via the existing "Owners can manage
--    materials" policy in comprehensive_rls_policies.sql) so materials
--    uploaded before this change remain manageable by their original
--    uploader.
-- ==========================================================================
DROP POLICY IF EXISTS "Authenticated users can upload materials" ON course_materials;
CREATE POLICY "Admins can upload materials" ON course_materials
    FOR INSERT WITH CHECK (is_admin());

-- ==========================================================================
-- 2. departments — creation AND management are now admin-only. Replaces
--    both the fully-open "any authenticated user" INSERT policy and the
--    is_contributor()-based FOR ALL policy (contributors were never able to
--    reach department creation through the UI in the first place).
-- ==========================================================================
DROP POLICY IF EXISTS "Authenticated users can create departments" ON departments;
DROP POLICY IF EXISTS "Contributors can manage departments" ON departments;
CREATE POLICY "Admins can manage departments" ON departments
    FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- ==========================================================================
-- 3. courses — same treatment as departments.
-- ==========================================================================
DROP POLICY IF EXISTS "Authenticated users can create courses" ON courses;
DROP POLICY IF EXISTS "Contributors can manage courses" ON courses;
CREATE POLICY "Admins can manage courses" ON courses
    FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- ==========================================================================
-- 4. bot_knowledge — a user may still manage their own personal knowledge
--    entries, but only an admin may set is_global = true (previously any
--    user could flag their own note global, making it feed the AI bot's
--    answers for every user). Consolidates two previously-coexisting,
--    differently-named policies ("Users can manage their own knowledge" /
--    "Users can manage own knowledge") from update_bot_knowledge_global.sql
--    and enforce_hard_paywall.sql into one.
-- ==========================================================================
DROP POLICY IF EXISTS "Users can manage their own knowledge" ON bot_knowledge;
DROP POLICY IF EXISTS "Users can manage own knowledge" ON bot_knowledge;
CREATE POLICY "Users can manage their own knowledge" ON bot_knowledge
    FOR ALL
    USING (auth.uid() = user_id OR is_global = true)
    WITH CHECK (auth.uid() = user_id AND (is_global = false OR is_admin()));
