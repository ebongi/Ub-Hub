-- New profile rows have historically been created (by whatever trigger
-- inserts into `profiles` on signup -- not present in this migration
-- history) without an explicit ai_credits value, leaving the column NULL.
--
-- deduct_ai_credit's guard clause:
--   WHERE id = auth.uid() AND ai_credits >= p_amount
-- evaluates `NULL >= p_amount` as NULL/false, so the UPDATE never matches
-- and every first AI request for a brand-new account raises "Insufficient
-- AI credits" -- even though the Dart client's `json['ai_credits'] ?? 5`
-- fallback (lib/services/profile.dart, lib/Screens/Shared/constanst.dart)
-- shows 5 credits and lets the AIUsageGate pass, so the failure only
-- surfaces after the user has already sent a message.
--
-- Backfill existing NULL rows to the 5 credits the client already assumes,
-- then set a column default + NOT NULL so this can't recur regardless of
-- what (still untracked) process creates future profile rows.
--
-- A plain "backfill, then ALTER COLUMN SET NOT NULL" has two problems on a
-- live table: it takes an ACCESS EXCLUSIVE lock for a full-table scan, and
-- it has a race window where a brand-new signup could insert a NULL row
-- between the backfill and the constraint, aborting the whole migration.
-- Instead: add the rule as a NOT VALID check first (this enforces it on
-- every write from this point on, without scanning existing rows), catch
-- anything that raced in during that window with a second backfill, then
-- VALIDATE (SHARE UPDATE EXCLUSIVE -- allows concurrent reads/writes) so
-- the table is provably all non-null before Postgres flips the real NOT
-- NULL flag, which it can then do as a fast metadata-only change.
UPDATE profiles SET ai_credits = 5 WHERE ai_credits IS NULL;

ALTER TABLE profiles ALTER COLUMN ai_credits SET DEFAULT 5;

ALTER TABLE profiles
  ADD CONSTRAINT ai_credits_not_null CHECK (ai_credits IS NOT NULL) NOT VALID;

UPDATE profiles SET ai_credits = 5 WHERE ai_credits IS NULL;

ALTER TABLE profiles VALIDATE CONSTRAINT ai_credits_not_null;

ALTER TABLE profiles ALTER COLUMN ai_credits SET NOT NULL;

ALTER TABLE profiles DROP CONSTRAINT ai_credits_not_null;
