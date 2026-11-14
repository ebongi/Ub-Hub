-- Faculty teaching timetable, loaded once per semester from the university's
-- PDF (see tool/generate_timetable_seed_test.dart), plus each user's chosen
-- courses. Students browse departments -> courses in Settings, tick the
-- courses they want, and the app schedules class reminders for those only.
--
-- Classes repeat weekly, so a slot is a weekday + local start/end time of
-- day (no absolute timestamps). Applied by hand, like the other migrations.

-- 1. Shared, read-only-for-users timetable rows.
CREATE TABLE IF NOT EXISTS timetable_classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    department TEXT NOT NULL,
    program TEXT NOT NULL,
    -- As listed in the timetable, including any lab-group suffix
    -- (e.g. 'MAT211-G1' is its own selectable course).
    course_code TEXT NOT NULL,
    -- ISO weekday: 1 = Monday ... 7 = Sunday (matches Dart's DateTime.weekday).
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    -- Venue exactly as named, e.g. 'CLASSROOM BLOCK II 50 D', 'AMPHI 150 E'.
    hall TEXT,
    lecturers TEXT,
    semester TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (end_time > start_time)
);

CREATE UNIQUE INDEX IF NOT EXISTS timetable_classes_slot_idx
    ON timetable_classes (course_code, day_of_week, start_time, end_time, hall)
    NULLS NOT DISTINCT;
CREATE INDEX IF NOT EXISTS timetable_classes_department_idx
    ON timetable_classes (department);

ALTER TABLE timetable_classes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Signed-in users can read the timetable" ON timetable_classes;
CREATE POLICY "Signed-in users can read the timetable" ON timetable_classes
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admins manage the timetable" ON timetable_classes;
CREATE POLICY "Admins manage the timetable" ON timetable_classes
    FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- 2. The courses each user wants class reminders for. Keyed by course code
-- (not row id) so a choice survives the yearly timetable reload.
CREATE TABLE IF NOT EXISTS user_timetable_courses (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    course_code TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, course_code)
);

ALTER TABLE user_timetable_courses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own timetable courses" ON user_timetable_courses;
CREATE POLICY "Users manage own timetable courses" ON user_timetable_courses
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
