-- start_trial_on_signup() (20261021120000_auto_start_trial_on_signup.sql)
-- gave EVERY inserted profile a fresh 14-day 'monthly' trial, so deleting an
-- account (delete-account removes the profile row and auth user) and
-- re-registering restarted the trial each time, and trusted inserts of a
-- non-trial profile were overwritten.
--
-- Now:
--  * The trial is keyed to a normalized email in trial_claims, a table that
--    outlives the profile/auth user, so delete + re-register gets no second
--    trial. Normalization lowercases, strips "+tag", and removes dots for
--    gmail.com / googlemail.com so trivial aliases don't bypass it.
--  * Inserts made while app.bypass_subscription_guard is set (the transaction-
--    local flag only trusted server-side functions set) keep whatever
--    subscription columns they specify.
--
-- Limits: a user can still register a genuinely different email address;
-- that needs phone/device verification, which is out of scope here.
--
-- Apply by hand in the Supabase SQL editor, like every other migration.

-- 1. trial_claims ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.trial_claims (
  email_normalized TEXT PRIMARY KEY,
  claimed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS on with no policies: no client can read or write it. Only the
-- SECURITY DEFINER functions below (running as owner) touch it.
ALTER TABLE public.trial_claims ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.trial_claims FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.normalize_trial_email(p_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
  v_local TEXT;
  v_domain TEXT;
BEGIN
  IF p_email IS NULL OR position('@' IN p_email) = 0 THEN
    RETURN NULL;
  END IF;
  v_local := lower(split_part(p_email, '@', 1));
  v_domain := lower(split_part(p_email, '@', 2));
  v_local := split_part(v_local, '+', 1);
  IF v_domain IN ('gmail.com', 'googlemail.com') THEN
    v_local := replace(v_local, '.', '');
    v_domain := 'gmail.com';
  END IF;
  RETURN v_local || '@' || v_domain;
END;
$$;

-- 2. Backfill: everyone who already used a trial counts as claimed ---------
INSERT INTO public.trial_claims (email_normalized)
SELECT DISTINCT public.normalize_trial_email(u.email)
  FROM auth.users u
  JOIN public.profiles p ON p.id = u.id
 WHERE p.trial_used = true
   AND public.normalize_trial_email(u.email) IS NOT NULL
ON CONFLICT DO NOTHING;

-- 3. Trigger ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_trial_on_signup()
RETURNS TRIGGER AS $$
DECLARE
  v_email TEXT;
  v_claimed BOOLEAN;
BEGIN
  -- Trusted server-side inserts keep their explicit subscription columns.
  IF current_setting('app.bypass_subscription_guard', true) = 'true' THEN
    RETURN NEW;
  END IF;

  SELECT public.normalize_trial_email(email) INTO v_email
    FROM auth.users WHERE id = NEW.id;

  -- No resolvable email: can't prove it's a first trial, so don't grant one.
  IF v_email IS NOT NULL THEN
    INSERT INTO public.trial_claims (email_normalized)
    VALUES (v_email)
    ON CONFLICT DO NOTHING;
    -- FOUND is true only if this call inserted the row (first claim).
    v_claimed := NOT FOUND;
  ELSE
    v_claimed := true;
  END IF;

  IF v_claimed THEN
    -- Trial already used for this email: start on the free tier.
    NEW.subscription_tier := 'free';
    NEW.subscription_expiry := NULL;
    NEW.subscription_is_trial := false;
    NEW.trial_used := true;
  ELSE
    NEW.subscription_tier := 'monthly';
    NEW.subscription_expiry := now() + INTERVAL '14 days';
    NEW.subscription_is_trial := true;
    NEW.trial_used := true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Trigger itself is unchanged (BEFORE INSERT ON profiles).
DROP TRIGGER IF EXISTS on_profile_insert_start_trial ON profiles;
CREATE TRIGGER on_profile_insert_start_trial
  BEFORE INSERT ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.start_trial_on_signup();
