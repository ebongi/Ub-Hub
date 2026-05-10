-- Migration: Enforce Hard Paywall for UB-Hub
-- This migration ensures that users whose 4-day trial has expired and who have no active subscription 
-- are denied access to their academic data and university resources at the database level.

-- 1. Helper function to check if a user is currently authorized
CREATE OR REPLACE FUNCTION public.is_authorized()
RETURNS BOOLEAN AS $$
DECLARE
    is_admin_or_contributor BOOLEAN;
    is_trial_active BOOLEAN;
    has_active_subscription BOOLEAN;
BEGIN
    -- Check if user is Admin or Contributor
    SELECT (role IN ('admin', 'contributor')) INTO is_admin_or_contributor
    FROM profiles
    WHERE id = auth.uid();

    IF is_admin_or_contributor THEN
        RETURN TRUE;
    END IF;

    -- Check if user is within their 4-day trial (345600 seconds)
    SELECT (EXTRACT(EPOCH FROM (now() - created_at)) < 345600) INTO is_trial_active
    FROM profiles
    WHERE id = auth.uid();

    IF is_trial_active THEN
        RETURN TRUE;
    END IF;

    -- Check if user has an active subscription
    -- Subscription is active if tier is not 'free' and expiry is in the future (or null for life-time if we add that)
    SELECT (
        subscription_tier != 'free' AND 
        (subscription_expiry IS NULL OR subscription_expiry > now())
    ) INTO has_active_subscription
    FROM profiles
    WHERE id = auth.uid();

    IF has_active_subscription THEN
        RETURN TRUE;
    END IF;

    -- If none of the above, they are locked out
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update RLS Policies for sensitive tables
-- We will replace the 'true' or 'auth.uid() = user_id' checks with 'is_authorized() AND ...'

-- Exams
DROP POLICY IF EXISTS "Users can manage own exams" ON exams;
CREATE POLICY "Users can manage own exams" ON exams 
FOR ALL USING (auth.uid() = user_id AND is_authorized());

-- Tasks
DROP POLICY IF EXISTS "Users can manage own tasks" ON tasks;
CREATE POLICY "Users can manage own tasks" ON tasks 
FOR ALL USING (auth.uid() = user_id AND is_authorized());

-- Grades
DROP POLICY IF EXISTS "Users can manage own grades" ON grades;
CREATE POLICY "Users can manage own grades" ON grades 
FOR ALL USING (auth.uid() = user_id AND is_authorized());

-- Bot Knowledge (Personal)
DROP POLICY IF EXISTS "Users can manage own knowledge" ON bot_knowledge;
CREATE POLICY "Users can manage own knowledge" ON bot_knowledge 
FOR ALL USING (auth.uid() = user_id AND is_authorized());

-- Course Materials (Viewing)
DROP POLICY IF EXISTS "Anyone can view materials" ON course_materials;
CREATE POLICY "Anyone can view materials" ON course_materials 
FOR SELECT USING (is_authorized());

-- 3. Note: Public info like News, Campus Locations, and Profiles stay viewable 
-- so the app doesn't crash and the user can still see the login/profile screens.
