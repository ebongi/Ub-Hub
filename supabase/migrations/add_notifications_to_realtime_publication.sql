-- `notifications` was never added to the supabase_realtime publication, so
-- the client's `.stream()` (NotificationService.unreadCountStream, which
-- drives the home bell dot and the bottom-nav Messages badge) only got its
-- initial REST snapshot. markAllAsRead()/markAsRead() updated the rows, but
-- the update never reached the open stream, leaving the red count stuck
-- until the widget was rebuilt. Same fix as add_realtime_publication_gaps.sql.
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
