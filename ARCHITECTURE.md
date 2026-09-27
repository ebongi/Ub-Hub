# GoStudy — How It Works

Engineering reference for the team: what's actually implemented, not the marketing framing in `README.md`/`WEBSITE_BRIEF.md`. Payment/billing internals (Fapshi, subscription pricing, transcript payment tracking) are deliberately **out of scope** here — ask separately if you need those.

App identity: package `go_study`, Flutter client, Supabase backend (Postgres + Auth + Realtime + Storage + Edge Functions), Firebase Cloud Messaging for push, Gemini (cloud) and Gemma 3 1B (on-device) for AI. Built for University of Buea students.

## 1. App bootstrap

`lib/main.dart` initializes Supabase, Firebase, and `SharedPreferences` in parallel, then wires up a `MultiProvider` (`MessageProvider`, `UserModel`, `ThemeProvider`, `LocaleProvider`, plus a `StreamProvider<User?>` on Supabase's auth-state stream). Entry point is `SplashScreen`, which routes to the onboarding carousel on first launch or `AuthWrapper` otherwise. Notification init and a Play Store update check both run fire-and-forget so they never block first frame.

On Android only, `GemmaModelManager().ensureEngineRegistered()` also fires here — the on-device model needs `flutter_gemma`, which requires iOS 16+ and this app's iOS Podfile isn't configured for that yet.

Localization is English + French (`lib/l10n/app_en.arb`, `app_fr.arb`) via `LocaleProvider`.

### Screen layout (`lib/Screens/`)
- `onboarding/` — first-launch carousel
- `authentication/` — sign in/up, paywall, registration
- `Shared/` — cross-cutting widgets (AI usage gate, premium dialog, section headers)
- `UI/preview/Navigation/` — main tab screens: home, chat, DMs, leaderboard, profile, settings, admin panel, moderation queue
- `UI/preview/Toolbox/` — feature tools: exams, flashcards, focus timer, marketplace, news, offline library, performance tracker, task manager, transcripts
- `UI/preview/detailScreens/` — course/department drill-down, PDF viewer, AI-answer actions, language lesson/practice
- `UI/preview/ComputerCourses/` — admin dialogs for adding courses/departments

## 2. Auth & backend

`lib/services/auth.dart` is a thin wrapper over Supabase Auth (`signUp` / `signInWithPassword` / `signOut`). Account deletion (`deleteAccount()`) calls a server-side `delete-account` Edge Function rather than deleting client-side, because removing an `auth.users` row needs the service-role key, which only ever lives server-side; the client signs out locally once the server confirms.

`lib/services/database.dart` (~1,550 lines) is the single `DatabaseService` fronting roughly 40 Supabase tables/streams: institutions, schools, departments, courses, course materials (upload, moderation queue, access requests), flashcard decks, exams, tasks, payments, marketplace listings, grades, campus locations, admin user search/roles, and the news feed. File uploads go through dedicated Supabase Storage buckets (materials, marketplace images, avatars, news images).

**Startup-hang fix (profile cache):** `AuthWrapper` used to block on the live Supabase realtime profile stream, which never emits with no internet — an infinite spinner, even for features that don't need the network. Fix: `UserModel` now caches a JSON profile snapshot to `SharedPreferences`. On resume, a cached snapshot for the signed-in uid is used immediately while the live stream still overwrites it once it arrives; no cache or a mismatched uid falls through to the original wait (no cross-account leak).

## 3. AI stack

`AIService` (`lib/services/ai_service.dart`) is an abstract interface — `sendMessage`/`streamMessage`, `generateStudyPlan`, `generateQuiz`, `generateFlashcards`, `summarizePdf`, `answerQuestion` — with two implementations behind it:

- **`GeminiService`** — cloud, Gemini API, full feature set, `requiresCredits = true`.
- **`GemmaService`** — on-device Gemma 3 1B via `flutter_gemma`, `requiresCredits = false`, Android-only, chat-only in this phase (the document-processing methods explicitly throw `UnimplementedError`, deferred to a later phase).

`GemmaModelManager` owns the on-device model's lifecycle: registers the MediaPipe inference engine once, downloads a self-hosted, sha256-verified, int4-quantized copy of Gemma 3 1B from a CDN, memoizes the loaded model, and supports delete/reinstall. The download runs as an Android foreground service so it survives WorkManager killing background tasks.

**"UB Support Bot" (knowledge bot):** `KnowledgeBotService` is retrieval-free — it stuffs one shared, admin-maintained knowledge document (`DatabaseService.getSharedBotKnowledge`, capped at 100k characters) into every question's prompt via a fixed system persona. There's no per-user conversation history: each question is an independent call. This was previously gated behind a `comingSoon` flag because an earlier version replayed a growing chat session (re-sending the full persona plus knowledge snippets every turn), so cost and latency scaled with conversation length. Root-caused and fixed by switching to a stateless one-shot client (flat cost regardless of conversation length); the gate was then removed and the feature now ships live.

`AISyncService` persists AI chat sessions/messages to Supabase so cloud-AI conversation history survives across devices and restarts.

A more recent addition lets students pull up past exam-question papers and get a step-by-step AI-generated answer (Gemini only, LaTeX-aware), gated by the same access checks as other document-AI features.

## 4. Chat & DMs

Global Chat and DMs share one `messages` table, distinguished only by `room_id` (`'global'` vs a deterministic per-pair DM id). `ChatService.sendMessage` branches on that prefix to route notifications differently — DMs write a per-recipient row plus a direct push; group/global rooms resolve membership server-side (via an Edge Function) and fan out, so the client never needs to hold everyone's push tokens.

`MessageProvider` holds a realtime subscription for unread counts/toasts and filters incoming rows client-side to global-or-own-DMs as defense in depth alongside row-level security. `FriendsService` implements friend-request-gated DMs (`sendFriendRequest`/`respondToRequest`/`removeFriend`).

**DM privacy hole (recently closed):** the `messages` table allowed any authenticated user to insert into — and, per a legacy policy found during the fix, even read — any other pair's DM room, because room membership was never checked server-side; `friend_requests` also lacked an ownership check on accept/decline. The fix scoped row-level security on `messages`, `friend_requests`, and `notifications` to actual participants, added client-side filtering as defense in depth, and removed a duplicate notification trigger found in the process.

## 5. Course materials & offline library

A course material's `fileUrl` is a private Storage *object path*, not a directly fetchable URL — `DatabaseService.requestMaterialAccess()` resolves a short-lived signed URL first. Materials carry a moderation status (pending/published/rejected) set server-side by trigger, never client-set.

`StorageService` downloads and AES-encrypts files to local disk for offline viewing, with the encryption key in `flutter_secure_storage`.

**Offline Library fix (recently shipped):** the library correctly listed locally-downloaded file IDs, but then called the live Supabase materials query just to get each file's title/type for display — so it broke with no internet despite the encrypted PDF already being on disk. Fix: downloading a material now also caches its title/type/category as metadata alongside the encrypted file, and the offline list is rebuilt entirely from that on-device cache — no network call needed.

## 6. Notifications

`NotificationService` wraps `FirebaseMessaging` + `flutter_local_notifications`: FCM token registration/refresh to Supabase, foreground/background/tap handlers, Android notification channels, and a `notifications` table with read/unread streams. It supports single-recipient notifications and broadcast fan-out (e.g. new content in a department), and hands group/global chat push delivery off to a Supabase Edge Function that resolves room membership server-side.

## 7. News feed

Fully built: admin-authored posts with student likes and comments, backed by dedicated `news_posts`/`news_comments`/`news_likes` tables. This replaced an earlier scraped-news-article feed, which has been removed. Screens: the feed itself, a post detail view, and an admin composer.

## 8. Other feature areas (brief)

- **Marketplace** — physical/digital campus listings.
- **Gamification** — points accrual, level/tier computation, and a ranked leaderboard.
- **Task manager** — student to-do entries.
- **Exam scheduler** — exam date/event entries.
- **Flashcards** — AI-generated or manually authored study decks.
- **Language practice** — exercise tracks (cloze, matching, word banks) with per-user progress tracking.
- **Institutions** — the data model supports multiple institutions, though content is UB-specific today.
- **Transcript requests** — exists as a student-services feature; payment/delivery-tracking internals are out of scope for this doc.

## Recent hardening, at a glance

| Fix | What was actually broken |
|---|---|
| Profile snapshot cache | App start hung indefinitely offline, waiting on a realtime stream that never emits without a connection |
| Offline Library | "Offline" list still made a live network call just to render titles, so it failed exactly when offline |
| DM/notifications RLS | Any authenticated user could read or write into other users' DM rooms server-side; RLS now scopes to participants |
| Knowledge Bot latency/cost | Chat-session replay made every question resend the full persona + history; now a flat-cost, stateless call per question |
