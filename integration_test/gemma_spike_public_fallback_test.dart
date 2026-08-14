// Fast smoke test for the raw flutter_gemma pipeline (download -> load ->
// inference) using a small, ungated public model (166MB vs. the ~530MB
// production model), so it doesn't require a multi-minute download on
// every manual run. Not production code, not the model we ship — see
// integration_test/gemma_service_test.dart for the real regression test
// against GemmaModelManager/AIEngineSelector/GemmaService.
//
// Run with:
//   flutter test integration_test/gemma_spike_public_fallback_test.dart \
//     -d <device>
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _modelUrl =
    'https://huggingface.co/litert-community/SmolLM-135M-Instruct/resolve/main/SmolLM-135M-Instruct_multi-prefill-seq_q8_ekv1280.task';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Public fallback model on-device spike', (tester) async {
    await FlutterGemma.initialize(
      inferenceEngines: const [MediaPipeEngine()],
    );

    final downloadStopwatch = Stopwatch()..start();
    double lastLoggedPercent = -10;
    await FlutterGemma.installModel(modelType: ModelType.general)
        .fromNetwork(_modelUrl)
        .withProgress((progress) {
          if (progress - lastLoggedPercent >= 10) {
            lastLoggedPercent = progress.toDouble();
            // ignore: avoid_print
            print(
              'SPIKE download progress: ${progress.toStringAsFixed(0)}% '
              'at ${downloadStopwatch.elapsedMilliseconds}ms',
            );
          }
        })
        .install();
    downloadStopwatch.stop();
    // ignore: avoid_print
    print('SPIKE download total: ${downloadStopwatch.elapsedMilliseconds}ms');

    final loadStopwatch = Stopwatch()..start();
    final model = await FlutterGemma.getActiveModel(maxTokens: 1024);
    loadStopwatch.stop();
    // ignore: avoid_print
    print('SPIKE model load: ${loadStopwatch.elapsedMilliseconds}ms');

    final chat = await model.createChat(
      systemInstruction:
          'You are a concise, helpful study assistant for university students.',
      maxOutputTokens: 200,
    );

    final inferenceStopwatch = Stopwatch()..start();
    await chat.addQueryChunk(
      Message.text(
        text: 'In two sentences, explain what a derivative is in calculus.',
        isUser: true,
      ),
    );
    final response = await chat.generateChatResponse();
    inferenceStopwatch.stop();

    final responseText = response is TextResponse
        ? response.token
        : response.toString();

    // ignore: avoid_print
    print('SPIKE inference: ${inferenceStopwatch.elapsedMilliseconds}ms');
    // ignore: avoid_print
    print('SPIKE response: $responseText');

    expect(responseText, isNotEmpty);

    await model.close();
  }, timeout: const Timeout(Duration(minutes: 15)));
}
