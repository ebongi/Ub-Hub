import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extracts embedded text from a PDF's bytes. Returns null when there is too
/// little to work with (a scanned / image-only PDF) or the file can't be
/// parsed — callers then fall back to sending the raw bytes to a multimodal
/// model.
///
/// Sending the extracted text instead of a base64 copy of the whole file is
/// dramatically smaller (a lecture PDF is ~100 KB of text vs tens of MB of
/// file) and far more reliable — the big base64 payloads routinely trip the
/// Edge Function / Gemini request-size limits and come back as an opaque
/// failure.
String? extractPdfText(List<int> bytes, {int maxChars = 120000}) {
  try {
    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    document.dispose();
    final cleaned = text.trim();
    if (cleaned.length < 200) return null;
    return cleaned.length > maxChars ? cleaned.substring(0, maxChars) : cleaned;
  } catch (_) {
    return null;
  }
}

/// Pulls the first JSON object out of a model response, tolerating ```json
/// fences and surrounding prose that `gemini-2.5-flash-lite` adds despite
/// being told to return JSON only.
String extractJsonObject(String raw) {
  var s = raw.trim();
  if (s.startsWith('```')) {
    s = s.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
    final fenceEnd = s.lastIndexOf('```');
    if (fenceEnd != -1) s = s.substring(0, fenceEnd);
    s = s.trim();
  }
  final start = s.indexOf('{');
  final end = s.lastIndexOf('}');
  if (start != -1 && end > start) s = s.substring(start, end + 1);
  return s;
}

/// Whether a model "response" is really one of GeminiService's swallowed
/// error sentences (it returns these as text instead of throwing).
bool looksLikeAiError(String response) {
  final t = response.trim();
  return t.isEmpty ||
      t.startsWith('I encountered an error') ||
      t.startsWith('Error:') ||
      t.startsWith("I'm sorry") ||
      t.startsWith('Sorry, I encountered an error') ||
      t.contains('error connecting to the AI service');
}
