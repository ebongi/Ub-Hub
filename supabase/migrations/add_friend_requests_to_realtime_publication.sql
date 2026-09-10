-- `friend_requests` was never added to the supabase_realtime publication, so
-- FriendsService's `.stream()` subscriptions (getPendingRequestsStream,
-- getFriendsStream, getAllRequestsStream) only ever deliver their initial
-- REST snapshot and never receive live INSERT/UPDATE postgres_changes
-- events. Symptom: incoming friend requests, accept/decline, and the DM
-- list's last-message ordering only update after the widget is torn down
-- and rebuilt — same class of bug as add_realtime_publication_gaps.sql and
-- add_profiles_to_realtime_publication.sql, just never caught here because
-- DmScreen/_NavBarState happened to recreate their streams on almost every
-- rebuild, masking the missing publication entry with implicit polling.
--
-- Confirmed safe to publish: friend_requests' SELECT policy already scopes
-- to `auth.uid() = sender_id OR auth.uid() = receiver_id`, so Realtime's
-- RLS-scoped broadcast won't expose other users' requests.
--
-- Apply by hand in the Supabase SQL editor, same as every other migration.

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE friend_requests;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
