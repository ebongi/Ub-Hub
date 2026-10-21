-- `profiles` was never added to the supabase_realtime publication, so
-- DatabaseService.userProfile's `.stream(primaryKey: ['id'])` only ever
-- delivered its initial snapshot and never fired again on later UPDATEs —
-- whether from the points_ledger trigger (total_points), a subscription
-- grant, an AI-credit deduction, or any other profile change. Symptom:
-- the Profile screen's points/level card (and any other profile-derived
-- UI) stays stale until the app is restarted, since AuthWrapper's
-- subscription to this stream never receives a second event.
--
-- The Dart client already filters this stream to `.eq('id', uid!)` (see
-- lib/services/database.dart), so each user only ever subscribes to their
-- own row — adding the table to the publication doesn't broadcast any
-- other user's profile data to them.
--
-- Apply by hand in the Supabase SQL editor, same as every other migration.

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
