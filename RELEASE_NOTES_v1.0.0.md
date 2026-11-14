# GO Study — v1.0.0

The first release of GO Study, an academic companion app for university students in Cameroon, built at the University of Buea. GO Study brings course materials, an AI tutor, campus tools, and a student marketplace into one app — with a mode that keeps working when there's no data connection.

## Highlights

- **AI Study Tutor** — powered by Google Gemini, with step-by-step answers, LaTeX math rendering, and streaming chat.
- **Offline AI Chat** — an on-device model (via Flutter Gemma) that answers questions with zero internet and no usage limits, bundled in the arm64-v8a build.
- **UB Support Bot** — a Gemini-backed assistant for registry, fees, and admin questions.
- **Course Materials & Past Papers** — browse by department, view PDFs in-app, and download for offline use.
- **Offline Library** — save materials so they stay available without a connection.
- **Global Student Chat** — real-time messaging via Supabase, with friend requests and profile pictures.
- **Student Marketplace** — buy and sell textbooks and course materials with other students.
- **Tasks, Exams & Focus Timer** — a persistent task manager, exam scheduler, and focus sessions, with local notifications for deadlines and alerts.
- **Performance Tracker / GPA Calculator** — log grades and track your average across the semester.
- **Campus News Feed** — university announcements in one place.
- **Resume Builder** — a built-in tool for building a student resume.
- **English & French localization** — the full app is available in both languages.
- **Light & dark theme** support throughout.
- **Admin dashboard** for managing departments, courses, and marketplace listings.

## Accounts & payments

- Supabase-backed authentication and data, with Row Level Security policies enforced across tables.
- Yearly AI/App Plan subscription tiers, with in-app payment via Fapshi.
- Transcript submission is gated behind delivery-method choice and payment.
- Users can delete their account and all associated data at any time from Settings.

## Tech stack

- **Frontend:** Flutter
- **Backend:** Supabase (auth, database, real-time chat)
- **AI:** Google Gemini (cloud) and Flutter Gemma (on-device, offline)
- **Push notifications:** Firebase Cloud Messaging
- **Payments:** Fapshi
- **Local storage:** Shared Preferences & Flutter Secure Storage

## Known limitations

- The on-device offline AI model is only included in the arm64-v8a build; the armeabi-v7a and x86_64 builds require an internet connection for the AI Study Tutor, and the offline model noticeably increases APK size.
- Distributed as a direct APK download alongside a pending Google Play listing.

---

**Full changelog:** [v1.0.0...HEAD comparison on GitHub](../../compare/v1.0.0...main) — note the existing `v1.0.0` tag currently points at an earlier commit (`b727d6f`, real-time chat/notifications); see below before publishing.
