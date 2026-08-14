import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';

/// Owns the on-device Gemma 3 1B model's lifecycle: one-time engine
/// registration, install/uninstall, and a cheap synchronous readiness
/// check. `flutter_gemma`'s own "Modern API" already persists model
/// identity across app restarts (`FlutterGemma.hasActiveModel()`), so this
/// class does not hand-roll a separate SharedPreferences flag for "is it
/// downloaded."
class GemmaModelManager {
  GemmaModelManager._();
  static final GemmaModelManager _instance = GemmaModelManager._();
  factory GemmaModelManager() => _instance;

  /// Self-hosted copy of `litert-community/Gemma3-1B-IT`'s
  /// `gemma3-1b-it-int4.task`. The original HuggingFace repo is gated
  /// (requires a personal account + access request) — not viable to push
  /// onto end users. Verified byte-identical (sha256 match) to the
  /// HuggingFace original during Phase 0.
  static const String modelUrl =
      'https://gostudy.b-cdn.net/models/gemma3-1b-it-int4.task';

  bool _engineRegistered = false;
  InferenceModel? _cachedModel;

  /// Registers the MediaPipe (`.task`) inference engine. Safe to call more
  /// than once — later calls are no-ops. Call once from `main()` before
  /// anything else in this class is used.
  Future<void> ensureEngineRegistered() async {
    if (_engineRegistered) return;
    await FlutterGemma.initialize(
      inferenceEngines: const [MediaPipeEngine()],
    );
    _engineRegistered = true;
  }

  /// Cheap, synchronous: true once a model has been downloaded and set
  /// active, persisted across app restarts by the plugin itself.
  bool get isModelReady => FlutterGemma.hasActiveModel();

  /// Loads (or returns the already-loaded) model for this app session.
  /// Model *load* — not download — was the ~7s-cost operation measured in
  /// Phase 0, so this is memoized rather than repeated per `GemmaService`
  /// instance.
  Future<InferenceModel> getOrLoadModel({int maxTokens = 1024}) async {
    final cached = _cachedModel;
    if (cached != null) return cached;
    final model = await FlutterGemma.getActiveModel(maxTokens: maxTokens);
    _cachedModel = model;
    return model;
  }

  /// Downloads and installs the model. `foreground: true` (not the
  /// auto-detect default) deliberately keeps Android's foreground-service
  /// notification active for the whole download — the auto-detect path
  /// never actually activates it, leaving large downloads on slow/flaky
  /// connections exposed to WorkManager's ~9-minute background-task kill.
  /// Given this app's whole premise is unreliable mobile data, that's a
  /// real failure mode worth the small manifest cost to close (see
  /// AndroidManifest.xml's FOREGROUND_SERVICE_DATA_SYNC permission).
  Future<void> downloadModel({
    required void Function(int percent) onProgress,
    CancelToken? cancelToken,
  }) async {
    var builder = FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromNetwork(modelUrl, foreground: true)
        .withProgress(onProgress);
    if (cancelToken != null) {
      builder = builder.withCancelToken(cancelToken);
    }
    await builder.install();
  }

  /// Deletes the installed model and clears its persisted "active model"
  /// identity so it isn't auto-restored on the next launch.
  Future<void> deleteModel() async {
    final files = FlutterGemma.activeModelSpec?.files ?? const [];
    final filename = files.isNotEmpty ? files.first.filename : null;
    _cachedModel = null;
    if (filename != null) {
      await FlutterGemma.uninstallModel(filename);
    }
    await FlutterGemma.clearActiveInferenceIdentity();
  }

  Future<StorageStats> getStorageInfo() => FlutterGemma.getStorageInfo();
}
