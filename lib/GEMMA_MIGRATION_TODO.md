# On-device Gemma migration — status

Roadmap/decisions were scoped in a planning session; full context in
`lib/GEMMA_MIGRATION_TODO.md` (this file, kept current) going forward.
See git history for the original plan doc if needed.

## ⚠️ Current state: code is stashed, not in the working tree

Phase 1 was fully implemented and **verified working end-to-end on a
real device** (full model download via the actual Settings UI → no
crash → `TaskStatus.complete, HTTP: 200`), but the decision was made to
defer shipping it — "that will be a later feature." All code for Phase 0
+ Phase 1 was removed from the working tree via `git stash push -u` (not
deleted — fully recoverable) so `main` stays clean until this is picked
back up. This file was deliberately kept out of the stash.

**To resume:** `git stash list` to find it (should be `stash@{0}` if
nothing else has been stashed since), then `git stash pop` (or `apply`
to keep the stash entry as a backup) to restore every file — new
services (`gemma_client.dart`, `gemma_service.dart`,
`gemma_model_manager.dart`, `ai_engine_selector.dart`), all the modified
screens/manifest/ARB/pubspec changes, and the tests — exactly as they
were when last verified working. Run `flutter pub get` afterward (the
stash includes `pubspec.yaml`/`pubspec.lock`, restoring the
`flutter_gemma` deps). Everything below this point describes that
stashed code, not what's currently in the tree.

**The one bug fixed after everything below was written**, worth knowing
before resuming: a real on-device crash was found and fixed post-writeup
— `androidx.work.impl.foreground.SystemForegroundService` (used by
`background_downloader`'s `foreground: true` downloads) ships with no
`foregroundServiceType` on itself, causing a hard
`IllegalArgumentException` crash on Android 14+ the moment a real
download starts. Fixed with an explicit `<service>` override in
`AndroidManifest.xml` (`tools:node="merge"`, `foregroundServiceType="dataSync"`).
This fix **is** included in the stash.

**Decisions locked in:**
1. End state: fully Gemma-based (chat + Support Bot first), migrated in
   phases — not a permanent cloud-fallback hybrid.
2. Phase 1 pilot: Chat tutor + UB Support Bot (both text-only).
3. Model: **Gemma 3 1B**, int4, `.task` format (~0.5GB).
4. Platform: **Android first**. iOS needs `flutter_gemma` 16.0+ vs. this
   app's current 13.0 minimum — deferred as its own future decision.
5. AI credits: kept, rescoped. Chat/Support Bot stop consuming credits
   once on-device (no API cost); credits keep gating whatever's still
   cloud (PDF quiz-gen/summarize) until those migrate too.

## Done

- **Package added**: `flutter_gemma: ^1.5.2` + `flutter_gemma_mediapipe: ^1.0.4`
  in `pubspec.yaml` (the modular core + the MediaPipe engine needed for
  `.task` models — Gemma 3 1B is `.task`, not `.litertlm`, so
  `flutter_gemma_litertlm` is NOT needed for this model). Resolved
  cleanly, no dependency conflicts (`flutter pub add` — 16 deps changed,
  nothing broken).
- **Dart/Flutter SDK check**: package needs Dart `>=3.12.0`, Flutter
  `>=3.44.0`. Installed here: Dart 3.12.2, Flutter 3.44.9 — satisfies it.
  Project's own `pubspec.yaml` `environment.sdk: ^3.9.2` did not need
  raising.
- **Android build verified**: `flutter build apk --debug` succeeds with
  the new dependency, no code changes to `android/app/build.gradle.kts`
  needed for basic (CPU-backend, text-only) integration. Only routine
  "upgrade Gradle/AGP/Kotlin soon" warnings (pre-existing, unrelated to
  this change) — Gradle 8.12.0, AGP 8.9.1, Kotlin 2.1.0 all still work.
- **Installed + launched on a real physical device**: Samsung Galaxy
  S21 Ultra (SM-G998U1, Android 15/API 35, arm64) connected via USB.
  App installs (`adb install -r`) and launches cleanly, process stays
  alive, no crash/FATAL in logcat from the new native plugin
  registration — confirmed even though no Gemma code path is wired up
  or exercised yet (this only proves plugin *registration* is safe, not
  that inference works).
  ⚠️ Note: this reused the developer's existing connected test device
  (package `com.ebongsume.gostudy`) via `-r` (reinstall, preserves app
  data) — if that device had a differently-signed build installed,
  reinstall would have failed rather than silently overwritten it; since
  it succeeded, it was already a compatible debug build.
- **Architecture support corrected** (earlier assumption was wrong): for
  `.task`/`.bin` MediaPipe models specifically (what Gemma 3 1B uses),
  Android text inference works on **arm64-v8a, x86_64, AND armeabi-v7a**
  — broader device coverage than initially assumed. The arm64-v8a-only
  restriction only applies to `.litertlm` (FFI) models, embeddings, and
  vision — not our text-only chat use case. **No `abiFilters`
  restriction needed** in `build.gradle.kts`.
- **Real API surface confirmed** (from the package's current README,
  v1.5.2 — this is a fast-moving package, re-check README on next
  session if picking this back up much later):
  ```dart
  // One-time install:
  await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
    .fromNetwork(modelUrl, token: hfToken)
    .withProgress((p) => ...)
    .install();

  // Use (repeatable):
  final model = await FlutterGemma.getActiveModel(maxTokens: 1024);
  final chat = await model.createChat(
    systemInstruction: '...',
    maxOutputTokens: 512,
  );
  await chat.addQueryChunk(Message.text(text: '...', isUser: true));
  final response = await chat.generateChatResponse(); // or stream variant
  ```
  Must also call `FlutterGemma.initialize(...)` once in `main()`
  registering the engine package(s) added to pubspec — core registers no
  engine by itself.

## Important findings that change the plan

- **Gemma 3 1B is a GATED HuggingFace model** (`litert-community/`
  repos require clicking "Request Access" on the model's HF page, then a
  personal HF access token per download). **This is not something we can
  ship to end users as-is** — we cannot require every student to create
  a HuggingFace account and request gated-model access just to download
  the chat model. **Action needed before Phase 1 ships**: self-host a
  copy of the model file (e.g. a Supabase Storage bucket, or another
  CDN) using one project-level HF token to fetch it once, then point
  `fromNetwork()` at our own URL instead of HuggingFace directly. Gemma's
  license permits this (redistribution is allowed provided the Gemma
  Terms of Use + any-changes notice travel with it) — need to budget for
  the one-time CDN egress cost of a ~500MB file × install volume.
- **PDF text extraction already exists in this app** — `syncfusion_flutter_pdf`
  (already a dependency) is already used in
  `lib/Screens/UI/preview/Toolbox/knowledge_manager_screen.dart:157-158`
  (`PdfTextExtractor(document).extractText()`). This significantly
  de-risks Phase 3 (PDF quiz-gen/summarize migration) — the extraction
  half of that problem is already solved and proven in this codebase.
- **`google_mlkit_text_recognition` is already a pubspec dependency but
  is currently unused anywhere in `lib/`** — the OCR tool flagged as
  needed for Phase 3 (scanned/handwritten PDFs) is already available,
  just not wired up. Also de-risks Phase 3.
- **`flutter_gemma_rag_sqlite`** (a real opt-in package in the same
  family, works on all 6 platforms incl. web via `sqlite-vec`) is a
  better fit for the UB Support Bot's on-device RAG than the originally
  planned "just bundle/cache BotKnowledge snippets as flat text" — worth
  using this instead when Phase 1 gets to the Support Bot half, for
  proper semantic search over the knowledge base rather than naive
  snippet stuffing into the prompt.
- iOS setup (for whenever Phase 4 happens): `Podfile` needs
  `platform :ios, '16.0'`, `Info.plist` needs `UIFileSharingEnabled`,
  `Runner.entitlements` needs 3 memory entitlement keys for large
  models, `use_frameworks! :linkage => :static` in Podfile.

## Not done yet

**Phase 0 (feasibility spike) — partially done:**
- ✅ Package integration, build, install/launch smoke test (see above).
- ❌ **Real budget/low-end Android device testing** — not possible from
  this environment. The only connected device is a Galaxy S21 Ultra
  (flagship, 12GB RAM), not representative of the target market's
  typical hardware. Actual inference latency/RAM/battery/download-time
  numbers on real budget hardware are still unknown and are the actual
  go/no-go gate — this still needs to happen before committing further
  engineering time to Phase 1's UI/UX work.
- ❌ Actually downloading and running Gemma 3 1B inference even once —
  blocked on getting a HuggingFace token with access to the gated
  `litert-community/Gemma3-1B-IT` repo (needs a human to visit the model
  page and click "Request Access" — can't be done from this session).
  Once approved: get a personal token from
  https://huggingface.co/settings/tokens, request access at
  https://huggingface.co/litert-community/Gemma3-1B-IT, then a minimal
  spike (install + one `generateChatResponse()` call) can run on the
  connected device to get first real latency/quality numbers (still on
  flagship hardware, but better than nothing).

**Phase 1 (Chat + Support Bot on Gemma) — not started:**
- Resolve the gated-model distribution problem (self-host the model
  file) before building anything user-facing.
- `lib/services/gemma_service.dart` — `GemmaService implements AIService`.
- `lib/services/gemma_model_manager.dart` — download/cache/delete
  lifecycle, mirroring `storage_service.dart`'s pattern minus encryption.
- Settings "Offline AI" entry + download UI with progress/size warning.
- Device-capability check + fallback to `GeminiService()` on
  incompatible/undownloaded devices (confirm this default is still
  wanted before building it).
- Swap `AIService` selection in `chatbot_screen.dart` and
  `knowledge_bot_service.dart`.
- Bundle/cache `BotKnowledge` via `flutter_gemma_rag_sqlite` instead of
  flat snippets (see finding above).
- Remove `useAICredit()` calls from the Gemma code path; update
  `ai_usage_gate.dart` / `subscription_plans_screen.dart` copy.

**Phase 2 (Study Plan) / Phase 3 (PDF tools) / Phase 4 (iOS)**: not
started — see original plan for scope of each.

## Spike attempt log — Gemma 3 1B (the model we plan to ship)

`integration_test/gemma_spike_test.dart`: download → load → one
`generateChatResponse()` call, timed. Not production code — throwaway
measurement harness per Phase 0.

- **Attempt 1**: failed — `FlutterGemma.initialize(...)` must be
  `await`ed (the README's own example snippet doesn't show this, but
  the runtime enforces it: calling `.install()` right after a
  non-awaited `initialize()` races the internal service registry and
  throws `StateError: FlutterGemma not initialized!`). Fixed by adding
  `await`.
- **Attempt 2**: failed — real HTTP 403 from HuggingFace: `Access to
  model litert-community/Gemma3-1B-IT is restricted and you are not in
  the authorized list.` The token authenticated fine (metadata API
  calls worked), but **file downloads enforce gated-access separately
  from metadata listing** — the account hadn't been granted access to
  this specific repo yet.
- **Resolved**: `litert-community/Gemma3-1B-IT` is `"gated": "auto"` on
  the HF API (self-serve, not a manual review queue) — visiting the
  model page and accepting access granted it instantly. Confirmed via
  the model page banner: "Gated model — You have been granted access to
  this model."
- **Attempt 3 — SUCCESS**, real numbers on the connected Galaxy S21
  Ultra (flagship — see caveat below), `gemma3-1b-it-int4.task` (529 MB):
  - Download: **254.6s** for 529 MB (~2.1 MB/s on this network)
  - Model load: **7.0s**
  - Inference: **2.2s** for a 2-sentence answer to "explain what a
    derivative is in calculus" — coherent, on-topic, stopped cleanly
    (contrast with the SmolLM-135M fallback spike below, which rambled
    for 90s and never stopped properly — Gemma 3 1B's instruction-tuning
    held up noticeably better at this size class)
  - Also fixed the same `generateChatResponse()` return-type bug found
    in the fallback spike (see below) before this run.

  ⚠️ **Caveat, unchanged from the original Phase 0 plan**: this is a
  flagship device (12GB RAM). These numbers are real and are a strong
  positive signal for the architecture and model choice, but they are
  **not** a stand-in for the actual go/no-go question — how this
  performs on the budget/mid-range Android hardware students actually
  carry is still unmeasured. Treat these as "the mechanism works well
  and the chosen model gives good answers fast," not "this is fast
  enough on a $60 Android phone."

## Spike attempt log — public-model pipeline validation (before HF access cleared)

Run while blocked on Gemma access, to avoid being idle and to prove the
pipeline itself (not Gemma-specific) works:

- `integration_test/gemma_spike_public_fallback_test.dart` —
  SmolLM-135M-Instruct (ungated, 166MB `.task`, `ModelType.general`).
  **Succeeded** on the first real attempt: download 69.3s, model load
  3.0s, inference "succeeded" but ran for 90.7s and produced a long,
  repetitive, eventually-hallucinated multi-turn response that never hit
  a proper stop token — expected for a model this small, and it
  surfaced a real integration detail (see next point).
  - Test itself initially "failed" on `expect(response, isNotEmpty)` —
    not a real bug in the model/pipeline, just that
    `chat.generateChatResponse()` returns a `TextResponse` object, not a
    raw `String` (`response.token` is the actual text; the Quick Start
    README example glosses over this by relying on `TextResponse`'s
    `toString()` in a print statement). Fixed in all three spike files.
  - **Real finding**: `maxOutputTokens` is silently ignored on `.task`
    (MediaPipe) models — confirmed via an explicit runtime log line
    (`"[MediaPipe] maxOutputTokens (200) is not supported on the .task
    path (no session-level output cap); ignoring."`). This is the exact
    format Gemma 3 1B ships in, so **production code cannot rely on
    `maxOutputTokens` to bound response length/latency on Android** —
    needs either a smaller `maxTokens` (context window) to force an
    earlier natural cutoff, app-level output truncation, or switching to
    `.litertlm` (which does honor it, but that format isn't available
    for Gemma 3 1B on `litert-community`, only for Gemma 4).

## Detour — Gemma 4 E2B from a locally-downloaded file (parked)

You had already downloaded `gemma-4-E2B-it.litertlm` locally (2.5GB,
Apache-2.0/ungated — that's how you got it directly without going
through the access flow above). Attempted to use it as a bonus
higher-tier quality reference point via `flutter_gemma_litertlm` +
`FileSource.fromFile()`. **Parked, not resolved** — not core to the
plan (Gemma 4 E2B is ~5x the size of what we intend to ship, so this
was purely exploratory), and the debugging cost stopped being worth it:

- `flutter_gemma_litertlm` added to `pubspec.yaml` for `.litertlm`
  support (harmless to leave in — needed eventually for iOS/Desktop
  parity per the original package docs, even if unused right now).
- Pushed the file to the device's app-scoped external storage
  (`/storage/emulated/0/Android/data/com.ebongsume.gostudy/files/`) via
  `adb push`.
- **Root problem found**: `flutter test integration_test/... -d <device>`
  fully uninstalls+reinstalls the app on every invocation, which wipes
  app-scoped external storage every time — so any file pushed before
  running `flutter test` is gone by the time the test code runs.
  Confirmed by direct `adb shell ls` showing the directory itself gone
  after a `flutter test` run, even immediately after re-pushing.
- Worked around it partway with `adb install -r` (confirmed this
  preserves app data, unlike flutter test's install path) + a new
  `test_driver/integration_test.dart` + `flutter drive
  --use-application-binary=<already-built-apk>` to drive the test
  against an already-installed binary without triggering another
  rebuild/reinstall — this was mid-flight when the detour was stopped.
- `integration_test/gemma4_e2b_local_spike_test.dart` and
  `test_driver/integration_test.dart` are left in the repo in case this
  is picked back up later, but **the E2B question was never actually
  answered** (load time / inference speed / quality unmeasured).
- If resuming this later: the `flutter drive --use-application-binary`
  approach was the right direction and was one step from working — just
  needed the driver command re-run after the file was in place.

## Self-hosting — done

The model file is self-hosted on Bunny.net (Storage Zone `joviallabs` +
Pull Zone `gostudy`), not HuggingFace:
- **Public URL** (no auth, used by production code):
  `https://gostudy.b-cdn.net/models/gemma3-1b-it-int4.task`
- Verified byte-identical to HuggingFace's copy: same size
  (554,661,243 bytes) and matching sha256
  (`e3d981c0...7bd9dee`), confirmed both via Bunny's own storage-API
  checksum response and a live `curl -I` against the public URL
  (HTTP 200, correct `content-length`).
- `GemmaModelManager.modelUrl` (`lib/services/gemma_model_manager.dart`)
  is the single source of truth for this URL in code.

## Phase 1 — done

Full production wiring landed: Chat tutor + UB Support Bot both run on
Gemma 3 1B when it's downloaded (Android only), with a transparent
fallback to cloud Gemini otherwise.

**New files:**
- `lib/services/gemma_client.dart` — `GemmaClient` interface +
  `GemmaChatSessionClient`/`GemmaOneShotClient`. Both take a *lazy*
  `Future<InferenceModel> Function()` loader (not a resolved model), so
  they can be constructed synchronously — the actual model load (~7s per
  Phase 0) happens on first real use, not before the screen is built.
  Also holds the two pure, directly-unit-tested functions:
  `unwrapModelResponseText` (sealed `ModelResponse` → `String`, only
  `TextResponse` carries text) and `shouldStopForLength` (app-level
  backstop for the `maxOutputTokens`-ignored-on-`.task` bug — bounds
  streamed responses to `gemmaMaxResponseChars` = 4000 chars via
  `chat.stopGeneration()`, independent of the model's own stop-token
  behavior).
- `lib/services/gemma_service.dart` — `GemmaService implements
  AIService`. Never calls `useAICredit` (that absence, not a
  conditional, is what makes it free). `generateStudyPlan`/`generateQuiz`
  /`summarizePdf` throw `UnimplementedError` (Phase 2/3 scope); non-empty
  `attachments` throw `UnsupportedError`.
- `lib/services/gemma_model_manager.dart` — thin wrapper, narrower than
  originally sketched since `flutter_gemma`'s own API already persists
  model state (`hasActiveModel()`) across restarts — no hand-rolled
  SharedPreferences flag needed. Owns: `ensureEngineRegistered()`
  (registers `MediaPipeEngine`, call once), `isModelReady`, memoized
  `getOrLoadModel()`, `downloadModel()` (`foreground: true` —
  see below), `deleteModel()`, `getStorageInfo()`.
- `lib/services/ai_engine_selector.dart` — `createChatEngine()` /
  `createSupportBotEngine()`: synchronous decision (Gemma if ready +
  Android, else Gemini/null). This is where the "engine choice is frozen
  per app session" trade-off (accepted this session) actually lives —
  `ChatbotScreen`'s `_aiService` is `late final`, set once in `initState`,
  and the screen itself lives inside `navigationbar.dart`'s
  `IndexedStack` for the whole logged-in session.

**Modified:**
- `lib/services/ai_service.dart` — added `bool get requiresCredits` and
  `bool get supportsAttachments` (both required, no default — every
  implementer must state them explicitly). This is the mechanism that
  lets `chatbot_screen.dart`/`knowledge_bot_chat_screen.dart` skip the
  `AIUsageGate` paywall for Gemma without any `is GemmaService` type
  checks anywhere.
- `lib/services/gemini_service.dart` — `requiresCredits => true`,
  `supportsAttachments => true`.
- `lib/services/knowledge_bot_service.dart` — field widened
  `GeminiService` → `AIService` (only ever called `.streamMessage()`,
  already part of the interface — zero behavior change for existing
  callers). Persona string made public
  (`kKnowledgeBotSystemPersona`) so `AIEngineSelector` can reuse the
  exact same persona for the Gemma path instead of duplicating it.
- `navigationbar.dart` / `home.dart` — `ChatbotScreen`/
  `KnowledgeBotChatScreen` now constructed with
  `AIEngineSelector.createChatEngine()` /
  `.createSupportBotEngine()` instead of bare `const Screen()`.
- `chatbot_screen.dart` — credit-gate call wrapped in
  `if (_aiService.requiresCredits)`; attach-file button wrapped in
  `if (_aiService.supportsAttachments)`; added a one-time, dismissible
  first-run nudge (`SharedPreferences` flag
  `offline_ai_nudge_shown`) pointing at the new Settings entry —
  Android-only, skipped if the model's already downloaded.
- `knowledge_bot_chat_screen.dart` — same credit-gate wrap; constructor
  now takes an optional `AIService? aiService`.
- `settings_screen.dart` — new "Offline AI" tile (Android-only, hidden
  entirely on iOS rather than letting a tap attempt a download that
  can't work) in the App Preferences card, after Language. Three states
  (not-downloaded/downloading/downloaded) with confirm → progress
  (cancellable, live percent) → success/failure dialogs. Deleting shows
  a confirm dialog too.
- `main.dart` — `GemmaModelManager().ensureEngineRegistered()` awaited
  early, Android-only, before `runApp()` (must complete before
  `AIEngineSelector.createChatEngine()` is ever called).
- `android/app/src/main/AndroidManifest.xml` — added
  `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_DATA_SYNC` permissions.
  **Real bug this fixes**: `flutter_gemma`'s auto-detect foreground mode
  (the default when `foreground:` isn't passed) never actually activates
  Android's foreground-service notification — confirmed by reading the
  plugin's own source
  (`smart_downloader.dart`'s `shouldConfigureForegroundNotification` doc
  comment). That leaves a ~530MB download on a slow/flaky connection
  exposed to WorkManager's ~9-minute background-task kill with zero
  visible warning — a real risk given this app's whole premise is
  unreliable Cameroon mobile data. `downloadModel()` now passes
  `foreground: true` explicitly. The actual foreground service class
  (`background_downloader`'s own `UIDTJobService`) is declared in that
  plugin's own manifest and merges in automatically — verified directly
  from the installed package source, not guessed; only the permissions
  needed adding here. `POST_NOTIFICATIONS` was already declared via the
  existing `flutter_local_notifications` dependency.

**New ARB keys** (`app_en.arb`/`app_fr.arb`, ~26 keys): Settings tile
(3 states), download confirm/progress/complete/failed dialogs, remove
-model confirm, first-run nudge. All present in both languages.

**Cleanup**: deleted the three Phase 0 spike files no longer needed
(`gemma4_e2b_local_spike_test.dart`, `gemma_spike_test.dart` — hit
gated HuggingFace directly, production never will — and
`test_driver/integration_test.dart`, only needed for the parked E2B
detour). `gemma_spike_public_fallback_test.dart` repurposed as a fast
ungated-model smoke test (166MB vs. the ~530MB production model).
`gemma_spike_selfhosted_test.dart`'s logic promoted into
`integration_test/gemma_service_test.dart`, which now calls through the
real `GemmaModelManager`/`AIEngineSelector`/`GemmaService` production
path instead of raw `FlutterGemma.*` — the durable regression test
going forward (not yet run on-device this session, since the device
-testing loop for the Gemma 4 E2B detour was explicitly stopped; rerun
when picking this back up: `flutter test
integration_test/gemma_service_test.dart -d <device>`).

**Tests added**: `test/services/gemma_service_test.dart` (9 cases —
`requiresCredits`/`supportsAttachments` values, pass-through behavior,
`UnsupportedError` on attachments, `UnimplementedError` on the 3
out-of-scope methods, never yields `"OUT_OF_CREDITS"`).
`test/services/gemma_client_test.dart` (6 cases, the pure
`unwrapModelResponseText`/`shouldStopForLength` functions — no plugin
/native dependency needed, `ModelResponse` subtypes are plain
constructible value classes). `test/screens/chatbot_screen_test.dart` —
added "Never shows the credit paywall when the active engine is
credit-free" (the crux of the whole credit-bypass design — the behavior
most likely to silently regress later); **also fixed 2 pre-existing
failures** in this same file (`ProviderNotFoundException` for
`UserModel`, then a missing-`AppLocalizations`-delegates null-check —
both needed fixing to make the new test meaningful, since `_sendMessage`
can't run without them).

**Verification**: `flutter analyze` → 48 issues, matches baseline
exactly, zero new. `flutter test` → **42 pass / 11 fail** (new
baseline going forward — improved from 23/13: the 2 chatbot_screen_test
fixes above account for the entire fail-count reduction; every other
newly-failing-looking test was independently confirmed pre-existing and
unrelated — e.g. `gemini_service_test.dart`'s 5 failures are a
`Supabase.instance` "not initialized" error inside `sendMessage`'s
existing, untouched credit-check code, and the diff to
`gemini_service.dart` this session is provably limited to two unrelated
getters that the failing code path never calls).

## Next concrete step

Phase 1 is code-complete and verified at the unit/analyze level, but
**not yet run end-to-end on a real device this session** — the
`integration_test/gemma_service_test.dart` run and the manual walkthrough
from the plan (fresh install → nudge → download → restart → offline
chat works, no paywall, attach button hidden → Support Bot works → delete
falls back to cloud) are both still outstanding. Do that before
considering Phase 1 actually shipped, not just written.

## Blocked on you — action items

1. **Get real low/mid-range Android hardware into the loop.** Only a
   flagship (Galaxy S21 Ultra) has been tested. Options: lend a budget
   device, run the walkthrough yourself and report back, or set up a
   cloud device-testing service (Firebase Test Lab / BrowserStack). This
   is still the single biggest open question — Phase 1 works, but "works
   well on what students actually own" is unverified.
2. **Pull iOS 13–15 usage share before deciding on the iOS-16 bump.**
   Check App Store Connect → Analytics (or Firebase/Crashlytics if
   wired up).
3. **Confirm you're OK with the ongoing Bunny.net CDN egress cost.** A
   ~530MB download × install volume is a real recurring hosting bill —
   the $20 trial credit will run out. Worth checking Bunny's pricing
   dashboard once real download volume is known.
4. **Skim the Gemma Terms of Use yourself** (not legal advice from me):
   https://ai.google.dev/gemma/terms.
