# GoStudy — Customer Support Guide

What each part of the app does and how to help a user who's stuck. Written for support, not engineering — no code, no billing/payment details (escalate those separately).

GoStudy is the academic companion app for University of Buea students: AI study help, course materials, chat, and campus tools in one app, available in English and French.

---

## Account & login

- Sign-up needs an email + password (a name, and other profile details, can be filled in during/after registration).
- **Forgot password / can't log in:** this goes through standard email-based reset; if a user says they never got the reset email, first check they're checking the right inbox/spam before escalating.
- **"Delete my account":** In-app path is Settings → Delete Account → confirm. This is immediate and permanent — it removes the account, profile, messages, materials, and marketplace listings. There's no "undo" or grace period, so always confirm the user understands this before they proceed. If they don't have the app installed, they can request deletion by contacting support with their registered account email instead.
- **App seems to hang on a blank/loading screen at launch:** this used to happen when a user opened the app with no internet connection — it would wait indefinitely. That's fixed; the app now shows the user's last-known profile immediately and updates it once a connection is available. If a user still reports this, it's worth escalating as a possible regression rather than assuming it's expected.

## AI Study Assistant

Two "engines" power AI features, but users just see one AI experience:
- A cloud AI (more capable, handles documents/quizzes/summaries/study plans).
- An on-device AI on some Android phones (works offline, text-chat only — it can't yet summarize PDFs, generate quizzes/flashcards, or build study plans; those will say unsupported if attempted on-device).
- iOS doesn't have the on-device option yet — iOS users are always on the cloud AI.

Some AI features are usage-limited per account. If a user reports an AI feature suddenly "not working" or asking them to upgrade/wait, that's most likely a usage-limit message, not a bug — route billing/limit questions to the appropriate channel rather than treating it as a technical issue.

**"Past questions → Ask AI to Answer":** students can open an old exam question paper and have the AI walk through a step-by-step answer, including math formatting. This only works with the cloud AI.

## UB Support Bot ("ask about the university")

A separate AI chat that only answers from an official, admin-maintained knowledge document about University of Buea (policies, procedures, general info) — it does not have a personal conversation memory, and it does not know about a student's individual account, grades, or materials.

If it replies "I'm sorry, I don't have that specific information..." — that means the answer genuinely isn't in the admin-maintained knowledge base yet, not a bug. Worth flagging to whoever maintains that knowledge document if the same question comes up repeatedly.

## Course materials & Offline Library

- Materials (course PDFs, past papers, etc.) go through an approval step before other students can see them — a newly submitted material won't appear for others until it's approved.
- Students can download materials for offline access. A file must be downloaded once while online before it's available offline — it won't appear in the Offline Library otherwise.
- **"My downloaded files disappeared / show blank titles when I'm offline":** this was a real bug (the offline list used to need an internet connection just to display file names, defeating the point of "offline"), and it's fixed. If a user reports it now, treat it as worth escalating rather than expected behavior.

## Global Chat & Direct Messages (DMs)

- **Global Chat** is open to everyone — one shared room.
- **Direct Messages** require both people to be friends first (friend request sent and accepted). A user can't DM someone who hasn't accepted their friend request.
- DMs are private — only the two participants in a conversation can see it (this was hardened recently after a security review found a gap; it's fully closed now). If a user ever reports seeing someone else's messages, treat that as a high-priority security report and escalate immediately rather than a routine bug.

## Notifications

Push notifications cover: new chat/DM messages, exam schedule reminders, focus timer alerts, and task deadlines. If a user says they're not receiving notifications, the usual causes are: notifications disabled at the OS level for the app, or the app not having been opened/connected recently enough to refresh its notification registration. Reinstalling or logging out/in typically resolves a stale registration.

## Other features (quick reference)

- **Marketplace** — students buy/sell/list physical or digital items with each other.
- **Leaderboard & points** — students earn points for activity (e.g. contributing approved materials) and see a ranked leaderboard.
- **Task Manager** — personal to-do list with reminders.
- **Exam Scheduler** — personal exam date tracking.
- **Focus Timer** — a study-session timer.
- **Flashcards** — AI-generated or manually created study decks.
- **Language Practice** — practice exercises (fill-in-the-blank, matching, word banks) with progress tracking.
- **News Feed** — official campus announcements posted by admins; students can like and comment.
- **Transcript requests** — students can request an official transcript through the app; delivery/payment specifics are handled outside this guide — escalate those questions rather than answering from here.

## Escalation rule of thumb

- Anything involving **payments, billing, subscriptions, or transcript payment status** → escalate, not covered here.
- Anything suggesting a **user can see another user's private data** (DMs, account info) → escalate immediately as a security issue.
- Anything matching one of the "this was a real bug, now fixed" notes above but still happening → escalate as a possible regression.
