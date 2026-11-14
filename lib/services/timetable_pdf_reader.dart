import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:go_study/services/timetable_parser.dart';

/// Reads a timetable PDF into positioned words and parses it. Kept apart
/// from [TimetableParser] so the parser itself stays free of PDF code.
///
/// Throws if the PDF can't be opened. An empty result (no class rows) means
/// the file isn't in the supported layout — the caller should offer the AI
/// fallback or manual entry rather than saving nothing.
class TimetablePdfReader {
  const TimetablePdfReader._();

  static List<PositionedLine> readLines(Uint8List bytes) {
    final doc = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(doc)
          .extractTextLines()
          .map((line) => PositionedLine(
                line.bounds.top,
                line.wordCollection
                    .map((w) =>
                        PositionedWord(w.text, w.bounds.left, w.bounds.right))
                    .toList(),
              ))
          .toList();
    } finally {
      doc.dispose();
    }
  }

  static TimetableParseResult parse(Uint8List bytes) =>
      TimetableParser.parse(readLines(bytes));
}
