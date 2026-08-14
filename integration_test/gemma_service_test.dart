// Phase 1 regression test for the on-device AI production code path (see
// lib/GEMMA_MIGRATION_TODO.md). Unlike the Phase 0 spike files this
// supersedes, this calls through the real GemmaModelManager / GemmaService —
// the same code GemmaChatScreen runs — rather than raw FlutterGemma.* calls,
// so it actually regression-tests production behavior (credit-free, no
// attachments, real download/load/inference).
//
// Run with:
//   flutter test integration_test/gemma_service_test.dart -d <device>
import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/services/ai_service.dart';
import 'package:go_study/services/gemma_client.dart';
import 'package:go_study/services/gemma_model_manager.dart';
import 'package:go_study/services/gemma_service.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GemmaModelManager + GemmaService end-to-end on-device', (
    tester,
  ) async {
    final manager = GemmaModelManager();
    await manager.ensureEngineRegistered();

    if (!manager.isModelReady) {
      final downloadStopwatch = Stopwatch()..start();
      await manager.downloadModel(
        onProgress: (percent) {
          if (percent % 25 == 0) {
            // ignore: avoid_print
            print(
              'TEST download progress: $percent% at '
              '${downloadStopwatch.elapsedMilliseconds}ms',
            );
          }
        },
      );
      downloadStopwatch.stop();
      // ignore: avoid_print
      print('TEST download total: ${downloadStopwatch.elapsedMilliseconds}ms');
    }

    expect(manager.isModelReady, isTrue);

    final AIService aiService = GemmaService(
      client: GemmaChatSessionClient(manager.getOrLoadModel),
    );
    expect(
      aiService.requiresCredits,
      isFalse,
      reason: 'on-device chat must never consume AI credits',
    );
    expect(
      aiService.supportsAttachments,
      isFalse,
      reason: 'Phase 1 is text-only on-device',
    );

    final inferenceStopwatch = Stopwatch()..start();
    final response = await aiService.sendMessage(
      'In two sentences, explain what a derivative is in calculus.',
    );
    inferenceStopwatch.stop();

    // ignore: avoid_print
    print('TEST inference: ${inferenceStopwatch.elapsedMilliseconds}ms');
    // ignore: avoid_print
    print('TEST response: $response');

    expect(response, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 15)));
}
