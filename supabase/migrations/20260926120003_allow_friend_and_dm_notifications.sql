-- The only non-admin INSERT policy on `notifications` besides "for yourself"
-- is add_department_notification_policy.sql's same-department check. But
-- FriendsService.sendFriendRequest/respondToRequest and ChatService's DM
-- branch (see friends_service.dart, chat_service.dart) all insert a
-- notification row directly for the *other* person in a friend request or
-- DM — who is very often in a different department. Those inserts are
-- silently rejected by RLS today: chat_service.dart swallows the error in a
-- try/catch (the message still sends, but the recipient never gets an
-- in-app notification row or push for a cross-department DM), while
-- friends_service.dart has no try/catch at all, so accepting/declining or
-- sending a request to a different-department user throws unhandled.
--
-- Allow a notification insert when the caller and the target already have a
-- friend_requests row between them in either direction — covers a freshly
-- sent request (status 'pending', row inserted just before this check
-- runs), an accepted request notifying the original sender back, and a DM
-- message to an accepted friend.

DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notifications')
     AND EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'friend_requests') THEN
    DROP POLICY IF EXISTS "Users can notify friends and pending contacts" ON notifications;
    CREATE POLICY "Users can notify friends and pending contacts" ON notifications
    FOR INSERT
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM friend_requests fr
        WHERE (fr.sender_id = auth.uid() AND fr.receiver_id = notifications.user_id)
           OR (fr.receiver_id = auth.uid() AND fr.sender_id = notifications.user_id)
      )
    );
  END IF;
END $$;
