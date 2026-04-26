-- Rename subscription tiers in profiles table
-- Silver becomes monthly, Gold becomes yearly

UPDATE profiles 
SET subscription_tier = 'monthly' 
WHERE subscription_tier = 'silver';

UPDATE profiles 
SET subscription_tier = 'yearly' 
WHERE subscription_tier = 'gold';

-- Also update any check constraints if they exist
-- (Based on existing migrations, there might not be a strict check constraint on subscription_tier yet, 
-- but it's good practice to ensure it's handled if added later)

COMMENT ON COLUMN profiles.subscription_tier IS 'Subscription tier: free, monthly, or yearly';
