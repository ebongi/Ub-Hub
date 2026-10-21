-- Follow-up to restrict_content_creation_to_admins.sql.
--
-- Querying the LIVE project's pg_policies revealed several wide-open
-- write policies on courses/departments/course_materials that do not
-- appear anywhere in this repo's supabase/migrations/ history — they must
-- have been created directly against the database (dashboard SQL editor
-- or an untracked change) outside of any tracked migration. Because
-- Postgres OR's together every permissive policy for a given command,
-- restrict_content_creation_to_admins.sql's new admin-only policies did
-- NOT actually restrict anything: these older, differently-named
-- policies were still independently granting the same access. This
-- migration removes them by their real (live) names so the admin-only
-- policies are actually the only path for these writes.
--
-- Apply by hand in the Supabase SQL editor, same as every other migration.

-- course_materials: two additional open INSERT policies beyond the one
-- restrict_content_creation_to_admins.sql already dropped.
DROP POLICY IF EXISTS "Allow authenticated insert materials" ON course_materials;
DROP POLICY IF EXISTS "Authenticated users can upload" ON course_materials;

-- courses: open INSERT and UPDATE policies with no role check at all.
DROP POLICY IF EXISTS "Allow authenticated insert courses" ON courses;
DROP POLICY IF EXISTS "Allow authenticated update courses" ON courses;

-- departments: an INSERT policy that allowed contributors (not just
-- admins, which is what the UI actually restricts creation to) plus two
-- fully-open INSERT/UPDATE policies with no role check at all.
DROP POLICY IF EXISTS "Admins and contributors can create departments" ON departments;
DROP POLICY IF EXISTS "Allow authenticated insert department" ON departments;
DROP POLICY IF EXISTS "Allow authenticated update department" ON departments;
