-- Decouple the App Plan (general subscription_tier/subscription_expiry)
-- from the separately-purchased Unlimited AI subscription, and add
-- trial-tracking so the App Plan's free first month never grants free AI.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS trial_used BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS subscription_is_trial BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS ai_subscription_expiry TIMESTAMPTZ;

COMMENT ON COLUMN public.profiles.trial_used IS 'True once the user has ever activated the one-time free App Plan trial month.';
COMMENT ON COLUMN public.profiles.subscription_is_trial IS 'True while the current subscription_tier/subscription_expiry period is the free trial rather than a paid period.';
COMMENT ON COLUMN public.profiles.ai_subscription_expiry IS 'Expiry of the separately-purchased Unlimited AI subscription. Independent of subscription_tier/subscription_expiry (the App Plan) and never granted for free.';
