# FCM Push Notifications Setup Summary

We have successfully integrated server-side Firebase Cloud Messaging (FCM) push notifications triggered when new material is uploaded or a message is sent to a group/department chat.

---

## 🛠️ Summary of Changes Made

### 1. Database Schema (`supabase/migrations/`)
- **File Created**: [`add_fcm_token_to_profiles.sql`](file:///home/joviallaps/Desktop/Ub-Hub/supabase/migrations/add_fcm_token_to_profiles.sql)
- **SQL Executed**:
  ```sql
  ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
  CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON profiles (fcm_token) WHERE fcm_token IS NOT NULL;
  ```
- **Purpose**: Allows saving each user's FCM token upon app launch and indexes the tokens for rapid lookup by the Edge Function.

### 2. Edge Function (`supabase/functions/`)
- **File Created**: [`send-push-notification/index.ts`](file:///home/joviallaps/Desktop/Ub-Hub/supabase/functions/send-push-notification/index.ts)
- **Functionality**:
  - Dynamically resolves recipients for room-based group chats (excluding the message sender).
  - Fetches the FCM tokens from the database.
  - Generates short-lived OAuth2 tokens from the Firebase Service Account JSON.
  - Sends high-priority push notifications to devices using the FCM HTTP v1 API.

### 3. Flutter Service Updates (`lib/services/`)
- **[`notification_service.dart`](file:///home/joviallaps/Desktop/Ub-Hub/lib/services/notification_service.dart)**:
  - Added the helper method `triggerPushViaEdgeFunction` to call the new Edge Function asynchronously.
- **[`chat_service.dart`](file:///home/joviallaps/Desktop/Ub-Hub/lib/services/chat_service.dart)**:
  - Integrated FCM push trigger for all non-DM room messages (e.g., `'global'` or department rooms).
- **[`database.dart`](file:///home/joviallaps/Desktop/Ub-Hub/lib/services/database.dart)**:
  - Added trigger calls in `addMaterial()`, `createCourse()`, and `createDepartment()` so users whose devices are backgrounded or terminated receive push notifications.

---

## ⚙️ Configuration Completed

We linked the CLI to your project (`urglmgtjxtljzsjodmbf`) and configured the following remote settings:
1. **Secrets Set**:
   - `FIREBASE_PROJECT_ID`: `facultyofscienceapp-neo`
   - `FIREBASE_SERVICE_ACCOUNT_JSON`: Loaded with the private key JSON file provided.
2. **Edge Function Deployed**: `send-push-notification` deployed successfully.
3. **Flutter Configuration**: `lib/firebase_options.dart` and `android/app/google-services.json` updated to support `facultyofscienceapp-neo`.

---

## 📱 How to Verify & Test

1. **Token Registration**: Open the app. The token will be requested and saved to the `fcm_token` column on the current user's profile row in the database.
2. **Group Message Push**:
   - Log in on two different devices/emulators with different accounts.
   - Background the app on Device A.
   - Send a message in the Global or Department chat from Device B.
   - Device A should receive a push notification.
3. **Material Broadcast**:
   - Background the app on Device A.
   - Upload new course material on Device B (belonging to the same department).
   - Device A should receive a push notification notifying them about the new upload.

---

## 🧩 Delivery hardening (later pass)

Follow-up changes so pushes actually render on real devices:

### Code (done)
- **`AndroidManifest.xml`** — declared `android.permission.POST_NOTIFICATIONS` (Android 13+ shows nothing without it) and a `default_notification_channel_id` meta-data pointing at `go_study_alerts`.
- **`notification_service.dart`**
  - Creates the `go_study_alerts` / `go_study_chat` / `go_study_reminders` Android channels at startup, and calls `requestNotificationsPermission()` — a push can arrive before any in-app notification, and with no channel Android 8+ drops it.
  - Saves the FCM token regardless of the permission prompt result, and re-saves on `onTokenRefresh`.
  - Foreground `onMessage` now renders from `message.data`, and **skips** `material` / `course` / `department` types (those already surface via the realtime `notifications` subscription) to avoid a double notification.
  - `onMessageOpenedApp` + `getInitialMessage()` wired so tapping a background/terminated push routes via `_handleNotificationTap`.
- **Edge Function `index.ts`** — sends **data-only** messages (no `notification` block): `title` / `body` / `type` ride in `data`, so the client renders exactly one notification with no OS auto-display racing it. Kept an `apns.alert` block for iOS. `type` is now included in the FCM `data` for tap-routing.
- **`main.dart`** — `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.

### Still manual (not code)
- **Enable the Firebase Cloud Messaging API (v1)** in the `facultyofscienceapp-neo` Google Cloud project, and confirm the service account has `roles/firebasecloudmessaging.admin` (or Editor). A disabled API 403s the send.
- **Run `add_fcm_token_to_profiles.sql` on the live DB** if not already applied — confirm `profiles.fcm_token` + `idx_profiles_fcm_token` exist.
- **Redeploy the Edge Function** after the `index.ts` change: `supabase functions deploy send-push-notification`.
- **iOS** — `ios/Runner/GoogleService-Info.plist` still points at the old project; needs regenerating for `facultyofscienceapp-neo`, plus an APNs auth key uploaded to Firebase and Push/Background-Modes capabilities.
- Test on a **physical Android device** (or a Play-services emulator image) — FCM does not deliver on a plain emulator or the iOS simulator.
