-- Migration: Disable Hard Paywall for UB-Hub (Community Beta Transition)
-- This migration updates the database security function to grant all registered users
-- access to academic resources, disabling the 4-day trial block and paid subscription gates.

CREATE OR REPLACE FUNCTION public.is_authorized()
RETURNS BOOLEAN AS $$
BEGIN
    -- Return true for any logged-in user to allow free access during community phase
    RETURN auth.uid() IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
