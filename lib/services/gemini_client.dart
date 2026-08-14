import 'dart:async';
import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart' show DataPart;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_study/core/app_config.dart';
import 'package:go_study/services/ai_service.dart' show AIChatMessage, AIAttachment;

/// Interface for Gemini operations to allow for easier testing.
abstract class GeminiClient {
  Future<String?> sendMessage(String text, {List<DataPart>? attachments});
  Stream<String> sendMessageStream(String text, {List<DataPart>? attachments});
}

Uri _proxyUri(String functionName) =>
    Uri.parse('${AppConfig.supabaseUrl}/functions/v1/$functionName');

Map<String, String> _proxyHeaders() {
  final session = Supabase.instance.client.auth.currentSession;
  return {
    'Content-Type': 'application/json',
    'apikey': AppConfig.supabaseAnonKey,
    if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
  };
}

List<Map<String, dynamic>> _attachmentsJson(List<DataPart>? attachments) {
  if (attachments == null || attachments.isEmpty) return const [];
  return attachments
      .map((a) => {'mimeType': a.mimeType, 'data': base64Encode(a.bytes)})
      .toList();
}

Map<String, dynamic> _historyTurn(
  String role,
  String text, [
  List<DataPart>? attachments,
]) {
  return {
    'role': role,
    'parts': [
      {'text': text},
      ..._attachmentsJson(attachments).map((a) => {'inlineData': a}),
    ],
  };
}

/// Streams a Gemini response through the `gemini-proxy` Supabase Edge
/// Function rather than calling Google's API directly — the real
/// GEMINI_API_KEY lives only in the Edge Function's environment, never in
/// this client (which previously instantiated `GenerativeModel(apiKey:
/// ...)` directly, exposing it in every installed APK). The function
/// re-frames Gemini's SSE stream as newline-delimited JSON
/// (`{"text":"..."}\n` per chunk) — simpler, unambiguous framing to read
/// here with a line splitter over the incrementally-decoded UTF-8 byte
/// stream, independent of how the transport chunks bytes.
Stream<String> _streamFromProxy({
  required String message,
  required String model,
  String? systemInstruction,
  List<Map<String, dynamic>>? history,
  List<DataPart>? attachments,
}) async* {
  final request = http.Request('POST', _proxyUri('gemini-proxy'))
    ..headers.addAll(_proxyHeaders())
    ..body = jsonEncode({
      'model': model,
      if (systemInstruction != null) 'systemInstruction': systemInstruction,
      if (history != null) 'history': history,
      'message': message,
      'attachments': _attachmentsJson(attachments),
      'stream': true,
    });

  final response = await http.Client().send(request);
  if (response.statusCode != 200) {
    final body = await response.stream.bytesToString();
    throw Exception('Gemini proxy error (${response.statusCode}): $body');
  }

  await for (final line in response.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    final parsed = jsonDecode(line) as Map<String, dynamic>;
    final chunk = parsed['text'] as String? ?? '';
    if (chunk.isNotEmpty) yield chunk;
  }
}

/// Stateful implementation of [GeminiClient] for the main chat tutor. The
/// proxy is stateless per request, so this keeps the growing conversation
/// history locally and resends it on every call — mirroring how the SDK's
/// `ChatSession` worked before Gemini calls moved server-side, just with
/// the history living here instead of inside the SDK object.
class GeminiProxyChatClient implements GeminiClient {
  final String _model;
  final String? _systemInstruction;
  final List<Map<String, dynamic>> _history = [];

  GeminiProxyChatClient({
    String model = 'gemini-2.5-flash-lite',
    String? systemInstruction,
    List<AIChatMessage>? initialHistory,
  }) : _model = model,
       _systemInstruction = systemInstruction {
    for (final msg in initialHistory ?? const <AIChatMessage>[]) {
      final parts = <Map<String, dynamic>>[
        {'text': msg.text},
      ];
      if (msg.isUser) {
        for (final att in msg.attachments ?? const <AIAttachment>[]) {
          parts.add({
            'inlineData': {
              'mimeType': att.mimeType,
              'data': base64Encode(att.bytes as List<int>),
            },
          });
        }
      }
      _history.add({'role': msg.isUser ? 'user' : 'model', 'parts': parts});
    }
  }

  @override
  Future<String?> sendMessage(String text, {List<DataPart>? attachments}) {
    return sendMessageStream(
      text,
      attachments: attachments,
    ).fold<String>('', (acc, chunk) => acc + chunk);
  }

  @override
  Stream<String> sendMessageStream(
    String text, {
    List<DataPart>? attachments,
  }) async* {
    var fullText = '';
    await for (final chunk in _streamFromProxy(
      message: text,
      model: _model,
      systemInstruction: _systemInstruction,
      history: List.of(_history),
      attachments: attachments,
    )) {
      fullText += chunk;
      yield chunk;
    }
    _history.add(_historyTurn('user', text, attachments));
    _history.add(_historyTurn('model', fullText));
  }
}

/// Stateless implementation of [GeminiClient]: each call is an independent
/// request through the proxy, with no chat history accumulated or replayed
/// across calls. Use this for features where each request is a
/// self-contained question (e.g. retrieval-augmented Q&A) rather than an
/// ongoing multi-turn conversation — [GeminiProxyChatClient] resends the
/// entire growing history on every call, which makes both latency and cost
/// scale with conversation length.
class GeminiProxyOneShotClient implements GeminiClient {
  final String _model;
  final String _systemInstruction;

  GeminiProxyOneShotClient(
    this._systemInstruction, {
    String model = 'gemini-2.5-flash-lite',
  }) : _model = model;

  @override
  Future<String?> sendMessage(String text, {List<DataPart>? attachments}) {
    return sendMessageStream(
      text,
      attachments: attachments,
    ).fold<String>('', (acc, chunk) => acc + chunk);
  }

  @override
  Stream<String> sendMessageStream(
    String text, {
    List<DataPart>? attachments,
  }) {
    return _streamFromProxy(
      message: text,
      model: _model,
      systemInstruction: _systemInstruction,
      attachments: attachments,
    );
  }
}
