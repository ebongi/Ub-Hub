# On-device Gemma migration — status

Roadmap/decisions were scoped in a planning session; full context in
`lib/GEMMA_MIGRATION_TODO.md` (this file, kept current) going forward.
See git history for the original plan doc if needed.

## Current state: shipped as its own Toolbox entry, in the working tree

Phase 0 (feasibility) and Phase 1 (production wiring) are both
implemented and in the working tree (previously stashed while deferred;
recovered and re-architected — see "Architecture change" below).

**Decisions locked in:**
1. End state: fully Gemma-based (chat first, more features later),
   migrated in phases — not a permanent cloud-fallback hybrid.
2. Model: **Gemma 3 1B**, int4, `.task` format (~0.5GB).
3. Platform: **Android first**. iOS needs `flutter_gemma` 16.0+ vs. this
   app's current 13.0 minimum — deferred as its own future decision. On
   iOS, the Toolbox entry opens and explains it isn't available yet
   rather than being hidden outright.
4. AI credits: unaffected for the cloud tutor. Offline AI is a
   separate, always-free, always-local feature — it does not touch
   `useAICredit()`/`AIUsageGate` at all, and never will, since it never
   shares a screen or an `AIService` instance with the cloud paths.

### Architecture change (this session): dedicated Toolbox screen, not an engine swap

The original Phase 1 plan (see "Superseded design" below) wired Gemma in
as an alternate `AIService` that `chatbot_screen.dart` and
`knowledge_bot_chat_screen.dart` would transparently switch to via an
`AIEngineSelector`. That design was fully built and verified working
on-device, then stashed when shipping was deferred. When picking this
back up, the direction changed: **on-device AI now gets its own
Toolbox entry and its own chat screen**, entirely separate from the
cloud tutor and the UB Support Bot. Reasons this is simpler and was
adopted instead:
- No "engine choice frozen per app session" trade-off to explain or
  work around — a fresh, dedicated screen always reflects current
  model state.
- No coupling between the cloud chat screen's UI/perf work (streaming
  throttle, LaTeX rendering fixes — see git history) and Gemma's
  wiring — the two screens now share no files, so changes to one can
  never merge-conflict with or regress the other.
- Clearer UX: users opt into "Offline AI" as its own thing, rather than
  the main Chat/Support Bot silently changing behavior once a
  background download finishes.

**What survived the re-architecture as-is** (already correct,
platform/model-agnostic infrastructure):
- `lib/services/gemma_client.dart`, `gemma_service.dart`,
  `gemma_model_manager.dart` — unchanged.
- `AndroidManifest.xml` foreground-download permissions + the
  `SystemForegroundService` crash fix — unchanged.
- `pubspec.yaml`/`pubspec.lock` (`flutter_gemma`,
  `flutter_gemma_mediapipe`, `flutter_gemma_litertlm`,
  `integration_test`) — unchanged.
- `main.dart`'s `GemmaModelManager().ensureEngineRegistered()` call at
  startup — unchanged (comment updated to reference the new screen
  instead of the removed selector).
- Bunny.net self-hosting of the model file — unchanged.

**What was dropped** (was built and verified working, but doesn't fit
the new architecture — recoverable from git history if ever needed):
- `lib/services/ai_engine_selector.dart` (deleted) — no longer needed
  since nothing auto-switches engines anymore.
- `AIService.requiresCredits` / `AIService.supportsAttachments` on the
  interface stayed (harmless, already implemented by both
  `GeminiService` and `GemmaService`), but nothing outside
  `GemmaChatScreen` reads them — `chatbot_screen.dart`,
  `knowledge_bot_chat_screen.dart`, `knowledge_bot_service.dart`,
  `navigationbar.dart`, and `home.dart`'s Support Bot entry are all
  back to their pre-Gemma, cloud-only state.
- The Settings screen "Offline AI" download/delete tile — replaced by
  download/delete UI built directly into the new
  `GemmaChatScreen` (download-gate on first open; delete via the app
  bar overflow menu).
- The first-run nudge dialog on the cloud chat screen — dropped; the
  Toolbox tile itself is the discovery point now.

## Done

- **New file**: `lib/Screens/UI/preview/Toolbox/gemma_chat_screen.dart`
  — self-contained `GemmaChatScreen`. Owns its whole lifecycle:
  - Not Android → friendly "not available on this device" state.
  - Model not downloaded → download prompt (size/no-credits copy) → tap
    Download opens an info dialog first (storage ~530MB, RAM guidance
    "works best on 4GB+", on-device performance/battery trade-off vs.
    cloud, accuracy caveat for this smaller model, and a "only download
    on a mid-range-or-better phone" recommendation) → confirming starts
    the real download → progress UI (percent + cancel) → success builds
    the `GemmaService` in place, or an inline error with retry (retry
    skips the info dialog — already seen once).
  - Model ready → simple single-conversation chat UI (no session
    list/backend sync — this is local-only by design), streaming
    responses throttled to an 80ms UI-update cadence (same fix as the
    cloud chat screen, applied independently here), Markdown + LaTeX
    rendering (own copy of the currency-vs-math heuristic — see
    `chatbot_screen.dart`'s `LatexSyntax` for the shared reasoning,
    intentionally duplicated rather than imported to keep the two
    screens decoupled).
  - App bar actions when ready: new-chat (resets `GemmaService`'s
    history), overflow menu → remove downloaded model (confirm dialog
    → `GemmaModelManager().deleteModel()`).
- **`home.dart`**: added one `ToolItem` ("Offline AI",
  `Icons.download_for_offline_rounded`, green) to `_toolboxItems()`,
  pointing at `const GemmaChatScreen()` — same pattern every other
  Toolbox entry uses, no special-casing.
- **New ARB keys** (`app_en.arb`/`app_fr.arb`, ~16 keys, both
  languages): `homeToolOfflineAi` + `gemmaChat*` (title, download
  prompt, progress, cancel/retry, remove-model confirm, empty state,
  input hint, unavailable state). Reused existing keys where possible
  (`cancel`, `thinkingLabel`, `stopButton`, `newChatButton`,
  `sorryEncounteredError`).
- **`integration_test/gemma_service_test.dart`** — updated to
  construct `GemmaService(client: GemmaChatSessionClient(...))`
  directly instead of the removed `AIEngineSelector.createChatEngine()`
  — same end-to-end coverage (real download → load → inference, no
  credits, no attachments), now aimed at the actual production call
  shape `GemmaChatScreen` uses.
- **Verification**: `flutter analyze` → 47 issues (baseline was 48,
  net *fewer* — no new issues from any Gemma file). `flutter test` →
  39 pass / 13 fail; the 13 failures are the same pre-existing
  failures present before this work (Provider/Supabase test-fixture
  issues in unrelated screens, untouched this session) — all 14 Gemma
  unit tests (`gemma_service_test.dart`, `gemma_client_test.dart`)
  pass.

## Not done yet / next concrete step

- **Not yet run end-to-end on a real device since the re-architecture.**
  The underlying service layer (`GemmaClient`/`GemmaService`/
  `GemmaModelManager`) is unchanged from what was verified working
  on-device earlier (real download, load, inference on a Galaxy S21
  Ultra — see spike log below), but the new `GemmaChatScreen` UI itself
  has only been analyzed/unit-tested, not manually exercised on a
  device yet. Do that before considering this shipped: open the
  Offline AI tile from a fresh install → download → chat → force-stop
  and reopen (model should still show as ready) → remove model →
  confirm it goes back to the download prompt.
- **`integration_test/gemma_service_test.dart`** hasn't been re-run
  since being updated to drop `AIEngineSelector` — run it on a
  connected device: `flutter test integration_test/gemma_service_test.dart -d <device>`.
- Real budget/low-end Android device testing — still the actual go/no
  -go signal for shipping broadly (see "Blocked on you" below);
  unchanged by this session's UI re-architecture.

## Superseded design — engine-swap into existing chat screens (kept for reference)

This was the original Phase 1 approach: fully built, and **verified
working end-to-end on a real device** (full model download via a
Settings UI → no crash → `TaskStatus.complete, HTTP: 200`) before
being replaced by the dedicated-Toolbox-screen design above. Kept here
in case any of these pieces are useful again later — none of this is
in the working tree.

- `lib/services/ai_engine_selector.dart` — `createChatEngine()` /
  `createSupportBotEngine()`: synchronous decision (Gemma if ready +
  Android, else Gemini/null), used to swap `ChatbotScreen`'s and
  `KnowledgeBotChatScreen`'s `AIService` at construction time in
  `navigationbar.dart`/`home.dart`.
- `chatbot_screen.dart` changes: credit-gate call wrapped in
  `if (_aiService.requiresCredits)`; attach-file button wrapped in
  `if (_aiService.supportsAttachments)`; a one-time dismissible
  first-run nudge pointing at Settings.
- `knowledge_bot_chat_screen.dart` / `knowledge_bot_service.dart`
  changes: same credit-gate wrap; `KnowledgeBotService` field widened
  from `GeminiService` to `AIService`; persona string made public
  (`kKnowledgeBotSystemPersona`) for reuse by the selector.
- `settings_screen.dart` — "Offline AI" tile (Android-only) in App
  Preferences, three states (not-downloaded/downloading/downloaded),
  confirm → cancellable progress → success/failure dialogs, delete
  confirm.
- The real trade-off this design required and that the new
  architecture avoids: `ChatbotScreen`'s `_aiService` is `late final`,
  set once in `initState`, and the screen lives inside
  `navigationbar.dart`'s `IndexedStack` for the whole logged-in
  session — so a mid-session download wouldn't take effect without an
  app restart. Recorded then as an accepted trade-off; now moot.
- Recoverable in git history: this was implemented, committed to a
  stash, and the stash was later applied and hand-edited down to the
  current design in the same session — search recent commits/reflog if
  the full original diff is ever needed again.

## Important findings that still apply

- **Gemma 3 1B is a GATED HuggingFace model** — not viable to ship
  end-users through HuggingFace directly. **Resolved**: self-hosted on
  Bunny.net instead (see below).
- **PDF text extraction already exists in this app** —
  `syncfusion_flutter_pdf` is already used in
  `lib/Screens/UI/preview/Toolbox/knowledge_manager_screen.dart:157-158`.
  De-risks a future PDF quiz-gen/summarize migration to Gemma.
- **`google_mlkit_text_recognition`** is already a pubspec dependency,
  unused in `lib/` — available for scanned/handwritten PDF OCR
  whenever that migration happens.
- **`flutter_gemma_rag_sqlite`** — a better fit than naive snippet
  -stuffing if/when the UB Support Bot gets its own on-device RAG
  pathway in the future.
- iOS setup (whenever it happens): `Podfile` needs
  `platform :ios, '16.0'`, `Info.plist` needs `UIFileSharingEnabled`,
  `Runner.entitlements` needs 3 memory entitlement keys for large
  models, `use_frameworks! :linkage => :static` in Podfile.
- `maxOutputTokens` is silently ignored on `.task` (MediaPipe) models
  — confirmed via the plugin's own runtime log. `GemmaClient`'s
  `shouldStopForLength`/`gemmaMaxResponseChars` (4000 chars) is the
  app-level backstop for this, independent of the model's own
  stop-token behavior.

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

## Spike attempt log — Gemma 3 1B (the model we plan to ship)

Real numbers from Phase 0, on a connected Galaxy S21 Ultra (flagship —
see caveat below), `gemma3-1b-it-int4.task` (529 MB):
- Download: **254.6s** for 529 MB (~2.1 MB/s on this network)
- Model load: **7.0s**
- Inference: **2.2s** for a 2-sentence answer to "explain what a
  derivative is in calculus" — coherent, on-topic, stopped cleanly.
- Two real package bugs found and fixed along the way:
  `FlutterGemma.initialize()` must be `await`ed (undocumented), and
  `chat.generateChatResponse()` returns a `TextResponse` object, not a
  raw `String` (`.token` is the actual text).

⚠️ **Caveat, still unresolved**: this is a flagship device (12GB RAM).
These numbers are a strong positive signal for the architecture and
model choice, but they are **not** a stand-in for the actual go/no-go
question — how this performs on the budget/mid-range Android hardware
students actually carry is still unmeasured.

## Android build notes

- Package needs Dart `>=3.12.0`, Flutter `>=3.44.0` — satisfied by the
  environment used to build this (Dart 3.12.2, Flutter 3.44.9).
- `flutter build apk --debug` succeeds with the dependency, no
  `android/app/build.gradle.kts` changes needed for basic (CPU
  -backend, text-only) integration.
- For `.task`/`.bin` MediaPipe models specifically (what Gemma 3 1B
  uses), Android text inference works on **arm64-v8a, x86_64, AND
  armeabi-v7a** — broader coverage than the arm64-only restriction that
  applies to `.litertlm` (FFI)/embeddings/vision. No `abiFilters`
  restriction needed.

## Blocked on you — action items

1. **Get real low/mid-range Android hardware into the loop.** Only a
   flagship (Galaxy S21 Ultra) has been tested. Options: lend a budget
   device, run the walkthrough yourself and report back, or set up a
   cloud device-testing service (Firebase Test Lab / BrowserStack). This
   is still the single biggest open question — the mechanism works, but
   "works well on what students actually own" is unverified.
2. **Pull iOS 13–15 usage share before deciding on the iOS-16 bump.**
   Check App Store Connect → Analytics (or Firebase/Crashlytics if
   wired up).
3. **Confirm you're OK with the ongoing Bunny.net CDN egress cost.** A
   ~530MB download × install volume is a real recurring hosting bill —
   the $20 trial credit will run out. Worth checking Bunny's pricing
   dashboard once real download volume is known.
4. **Skim the Gemma Terms of Use yourself** (not legal advice from me):
   https://ai.google.dev/gemma/terms.
