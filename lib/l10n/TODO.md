# Localization (l10n) rollout — status

Infrastructure is fully wired up (`l10n.yaml`, `lib/l10n/app_en.arb` /
`app_fr.arb`, `lib/locale_provider.dart`, `main.dart` `MaterialApp` config,
Settings → Language picker). Adding a new screen means: add English keys to
`app_en.arb` (+ matching French to `app_fr.arb`), run `flutter gen-l10n`,
import `package:go_study/l10n/generated/app_localizations.dart`, and replace
hardcoded strings with `AppLocalizations.of(context)!.xxx`.

**Watch for this trap** (hit it twice already — academic level "Resit" in
`academic_step.dart`, task category/priority in `task_manager_screen.dart`,
semester in `performance_tracker_screen.dart`): if a string is both
*displayed* and *stored/compared* (e.g. a dropdown value saved to Supabase,
or used in `==` filtering), keep the stored value in English and only
translate the displayed label via a small `_xDisplayName(l10n, code)`
mapper. Never let a translated string become the persisted value.

## Done

- Infra: `main.dart`, `locale_provider.dart`, `l10n.yaml`, ARB files
- Onboarding: `onboarding_screen.dart`
- Auth: `signin.dart`, `register_flow.dart`, all 4 `register_steps/*.dart`
- `settings_screen.dart` (incl. Language picker tile)
- `home.dart`
- Toolbox: `task_manager_screen.dart`, `exam_schedule_screen.dart`,
  `focus_timer_screen.dart`, `offline_library_screen.dart`,
  `news_feed_screen.dart`, `performance_tracker_screen.dart`,
  `ai_study_plan_screen.dart`, `knowledge_bot_chat_screen.dart`
- `chatbot_screen.dart` (main AI tutor chat, 1748 lines)
- Navigation: `profile.dart`, `chat_screen.dart` (global chat), `dm_screen.dart`,
  `private_chat_screen.dart`, `user_search_screen.dart`, `admin_panel.dart`,
  `portalScreen.dart`, `navigationbar.dart` (`splash_screen.dart` has no
  translatable UI text — version number only — so it was left untouched)
- detailScreens: `course_detail_screen.dart`, `department_screen.dart`
  (2126 lines, biggest file in the app), `all_departments_screen.dart`,
  `pdf_viewer_screen.dart`, `questions.dart`
- Toolbox (rest): `TranscriptScreen.dart`, `create_exam_screen.dart`,
  `exam_detail_screen.dart`, `quiz_view_screen.dart`,
  `listing_detail_screen.dart`, `knowledge_manager_screen.dart`
- Settings (rest): `notifications.dart`, `about.dart`,
  `developer_info_screen.dart`, `feedback.dart`, `support_dialog.dart`,
  `rating.dart`, `privacy_policy_screen.dart` / `terms_of_service_screen.dart`
  (AppBar chrome only — see note below, legal body text still English)
- Authentication (rest): `authenticate.dart` (no UI text — pure routing
  logic, nothing to translate), `paywall_screen.dart`, `register.dart` (no
  UI text — thin wrapper around `RegisterFlow`), `register_form_widgets.dart`
  (pure reusable widget lib, all text comes from already-localized callers),
  `wrap.dart` (no UI text — pure auth routing logic)
- ComputerCourses: `add_course_dialog.dart`, `add_department_dialog.dart`
- Shared: `ai_usage_gate.dart`; `premium_dialog.dart`, `animations.dart`,
  `shimmer_loading.dart` checked — no hardcoded strings (pure widget/anim
  helpers, text comes from callers)
- `subscription_plans_screen.dart` (1097 lines, biggest Settings file)
- **`UserModel.trialTimeLeft` / `UserProfile.trialTimeLeft` refactor**: both
  getters (in `constanst.dart` and `services/profile.dart`) were changed to
  methods taking `AppLocalizations l10n` — `trialTimeLeft(l10n)` instead of
  a bare getter — so "Unlimited"/"3 days"/"Ending today" render translated.
  All 4 call sites updated: `subscription_plans_screen.dart`, `home.dart`,
  `profile.dart` (Navigation), and the getters' own definitions.

## Not done yet

**Toolbox**:
- `marketplace_screen.dart` — biggest remaining file (887 lines), not started
- `flashcards_screen.dart` (actually a Resume Builder — dead/unreachable code, low priority, see product-analysis memory)

**Settings**:
- `invitefriends.dart` (0-byte dead file — see product-analysis memory, no content to translate)
- `privacy_policy_screen.dart` / `terms_of_service_screen.dart` — body
  *content* (the actual policy/terms text) is still English-only —
  translating a legal document accurately needs real care, don't just
  machine-translate it blindly like UI chrome

**Shared**:
- `constanst.dart` — the hardcoded course catalog (~115 course code → name
  entries) is left as-is on purpose — these are official University of Buea
  curriculum names; auto-translating them would create a mismatch with
  what's on real transcripts.

## Quick way to check remaining scope

```bash
# Files not yet touched:
grep -rL "AppLocalizations" --include="*.dart" lib/Screens/

# Files already migrated:
grep -rl "AppLocalizations" --include="*.dart" lib/Screens/ lib/main.dart
```
