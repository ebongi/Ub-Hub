-- Material upload is open to any authenticated student (not just admins),
-- but the existing notifications INSERT policies (admin_management_policies.sql)
-- only allow a user to insert a row for themself, or for anyone if they're
-- an admin. That meant a regular student's "new material uploaded"
-- broadcast to their department (DatabaseService.addMaterial) was silently
-- rejected by RLS. Add a scoped policy: a user may notify another user who
-- shares the same department, matching the department-broadcast use case
-- without opening a general "notify anyone" vector.

DO $$ BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notifications') THEN
    DROP POLICY IF EXISTS "Users can notify their own department" ON notifications;
    CREATE POLICY "Users can notify their own department" ON notifications
    FOR INSERT
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM profiles sender
        WHERE sender.id = auth.uid()
          AND sender.department IS NOT NULL
          AND sender.department = (
            SELECT recipient.department FROM profiles recipient
            WHERE recipient.id = notifications.user_id
          )
      )
    );
  END IF;
END $$;
