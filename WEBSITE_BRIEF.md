# GoStudy — Marketing Website Brief

**One-line purpose:** A companion website for the GoStudy Android app — introduces the product to prospective students, hosts the legal/compliance pages Play Store requires, and gives existing users a way to manage their account without opening the app.

## Brand identity

- **Name:** GoStudy — wordmark, not "Go Study" (two words) or "GOSTUDY" (all caps)
- **Tagline:** "Your Academic Companion"
- **Positioning line:** Built for University of Buea students
- **Logo:** blue "G"-mark icon (already built — `assets/store/feature_graphic.png` shows it applied)
- **Color palette:** deep navy background (`#0F172A`), primary blue (`#1E88E5`), light accent blue (`#38BDF8` / `#7DD3FC`), light surface (`#F8FAFC`) for content areas — same palette as the app's dark theme and the feature graphic, keep the site visually continuous with the app rather than inventing new brand colors
- **Typography:** Outfit (Google Fonts) — used throughout the app's UI, reuse it site-wide for consistency
- **Tone:** friendly, energetic, student-to-student — not corporate-SaaS, not childish. Confident but approachable, the way a well-run campus service talks to its own students.

## Sitemap

1. Home (landing/marketing)
2. Features
3. Pricing
4. Support / Contact
5. Privacy Policy
6. Terms of Service
7. Delete My Account

## 1. Home

- **Hero:** logo + "GoStudy" wordmark, tagline "Your Academic Companion," sub-line "Built for University of Buea students." Google Play badge (App Store badge later, greyed/"coming soon" if not live yet). Background: dark navy gradient with soft blue blobs, matching the feature graphic aesthetic.
- **Feature highlight strip** (short, icon + one-line each, expand fully on Features page): AI Study Assistant · Course Materials & Offline Library · Global Chat & DMs · Campus Marketplace · Exam Scheduler & Focus Timer · Language Practice · Transcript Requests
- **Screenshot carousel** — real device screenshots (placeholder frames for now)
- **"Why GoStudy" section** — 3-4 short value props: everything in one app, AI help on demand, connect with your class, official services (transcripts) without the queue
- **Footer:** links to all other pages, support email, copyright

## 2. Features

Expand each into its own block with a short paragraph, mirroring the app's actual feature set:

- 🧠 **AI Study Tools** — Gemini-powered Study Assistant, UB Support Bot (university-specific Q&A), offline AI chat, AI-generated study plans, flashcards & auto-quizzes, language practice (lessons, cloze exercises, matching, word banks)
- 📚 **Courses & Materials** — browse UB faculties/departments/courses, built-in PDF viewer, offline library, performance tracking
- 🗓️ **Productivity** — exam scheduler, focus timer, task manager
- 👥 **Community** — Global Chat, friend-request-gated direct messages, leaderboard, campus Marketplace (physical & digital listings)
- 📰 **News** — official campus announcements posted by admins
- 🎓 **Student Services** — official transcript requests with delivery-method choice and payment tracking

## 3. Pricing

Present current tiers plainly (pull live values from `subscription_service.dart` at build time rather than hardcoding, since they change): Monthly (500 XAF), Yearly (3500 XAF), and any AI-credit or contributor tiers currently running. Include a short note that mobile money (MTN MoMo / Orange Money) is the supported payment method — this is a selling point for the audience, not a limitation, so frame it that way.

## 4. Support / Contact

- Support email (whatever is used for `feedback.dart` in-app)
- Link to WhatsApp support if surfacing the same number already used for transcript delivery
- Short FAQ block: "How do I delete my account," "How do I reset my password," "Is my payment info safe" — each with a 1-2 sentence answer, linking to the relevant full page where needed

## 5. Privacy Policy

Migrate/host the existing privacy policy text here (whatever's currently linked in Play Console) so it lives at a stable, permanent URL independent of wherever it was before. Must explicitly cover: Supabase (data storage/auth), Firebase (push notifications), Google Gemini (AI queries), Fapshi (payment processing) — matching what's declared in Data Safety.

## 6. Terms of Service

Mirror the in-app `terms_of_service_screen.dart` content here as the canonical, linkable version.

## 7. Delete My Account

Needs two clear paths:

- **In-app:** Settings → Delete Account → confirm — explain this deletes the account and all associated data immediately and permanently
- **Without the app installed:** a simple contact form or a stated email address ("email [support email] with your registered account email; we'll delete your account and all data within X business days") — this is what satisfies Play Console's "web-based deletion request" requirement
- State plainly what gets deleted (account, profile, messages, materials, marketplace listings) and note if anything is legally retained (e.g., payment/transaction records for accounting purposes) and for how long

---

## Priority if building incrementally

Privacy Policy and Delete My Account are the two pages that unblock Play Console submission — prioritize those first if not building all seven pages at once.
