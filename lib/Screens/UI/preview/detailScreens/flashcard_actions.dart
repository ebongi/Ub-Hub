import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:go_study/Screens/Shared/ai_usage_gate.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/flashcard_study_screen.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/core/pdf_ai_utils.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/course_material.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/flashcard_model.dart';
import 'package:go_study/services/gemini_service.dart';
import 'package:go_study/services/profile.dart';

/// Generates a flashcard deck from a course material, persists it, and opens
/// the study screen. Shared by `CourseDetailScreen` and `DepartmentScreen` so
/// the (AI-credit-gated) flow lives in one place — mirrors
/// `material_download_actions.dart`.
///
/// The material's text is extracted on-device (Syncfusion) and sent to the
/// model as plain text: far smaller and more reliable than shipping the whole
/// PDF as a base64 attachment (which routinely trips size limits and returns
/// an opaque failure), and model-agnostic. Scanned / image-only PDFs with no
/// extractable text fall back to sending the raw PDF bytes, which only the
/// cloud (Gemini) model can read.
Future<void> generateFlashcardsForMaterial({
  required BuildContext context,
  required DatabaseService dbService,
  required UserProfile? userProfile,
  required CourseMaterial material,
}) async {
  final l10n = AppLocalizations.of(context)!;

  // Only PDFs have a client-side content path today (see openMaterialFile).
  if (material.fileType.toLowerCase() != 'pdf') {
    ErrorHandler.showErrorSnackBar(context, l10n.flashcardsPdfOnlyMessage);
    return;
  }

  final count = await _pickCardCount(context, l10n);
  if (count == null || !context.mounted) return;

  if (userProfile == null) return;
  final canProceed = await AIUsageGate.checkAndShow(context, userProfile);
  if (!canProceed || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(l10n.generatingFlashcardsMessage)),
          ],
        ),
      ),
    ),
  );

  var progressOpen = true;
  void closeProgress() {
    if (progressOpen && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      progressOpen = false;
    }
  }

  try {
    final response = await http
        .get(Uri.parse(material.fileUrl))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw '${l10n.flashcardGenerationFailed} (${response.statusCode})';
    }

    // Prefer extracted text; fall back to raw bytes for scanned PDFs.
    final Object source = extractPdfText(response.bodyBytes) ?? response.bodyBytes;

    final raw = await GeminiService()
        .generateFlashcards(source, count: count)
        .timeout(const Duration(seconds: 90));

    final trimmed = raw.trim();
    if (trimmed == 'OUT_OF_CREDITS') {
      closeProgress();
      if (context.mounted) await AIUsageGate.checkAndShow(context, userProfile);
      return;
    }
    // GeminiService swallows transport/model failures into a plain-text
    // sentence rather than throwing — treat those as a service error. In
    // debug builds surface the raw sentence so the real cause is visible.
    if (looksLikeAiError(trimmed)) {
      throw kDebugMode && trimmed.isNotEmpty
          ? trimmed
          : l10n.flashcardServiceUnavailable;
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(extractJsonObject(trimmed)) as Map<String, dynamic>;
    } catch (_) {
      throw kDebugMode
          ? 'Flashcard JSON parse failed. Model returned: '
                '${trimmed.length > 300 ? '${trimmed.substring(0, 300)}…' : trimmed}'
          : l10n.flashcardGenerationFailed;
    }

    final rawCards = (decoded['cards'] as List?) ?? const [];
    final cards = <Flashcard>[];
    for (final entry in rawCards) {
      if (entry is! Map) continue;
      final question = (entry['question'] ?? '').toString().trim();
      final answer = (entry['answer'] ?? '').toString().trim();
      if (question.isEmpty || answer.isEmpty) continue;
      cards.add(
        Flashcard(question: question, answer: answer, position: cards.length),
      );
    }

    if (cards.isEmpty) throw l10n.flashcardGenerationFailed;

    final decodedTitle = (decoded['title'] ?? '').toString().trim();
    final title = decodedTitle.isNotEmpty ? decodedTitle : material.title;

    final deck = await dbService.createDeckWithCards(
      materialId: material.id,
      courseId: material.courseId,
      departmentId: material.departmentId,
      title: title,
      cards: cards,
    );

    closeProgress();

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlashcardStudyScreen(deck: deck, cards: cards),
        ),
      );
    }
  } catch (e) {
    closeProgress();
    if (context.mounted) ErrorHandler.showErrorSnackBar(context, e);
  }
}

/// "How many cards?" picker — mirrors the difficulty dialog in
/// `pdf_viewer_screen.dart`.
Future<int?> _pickCardCount(BuildContext context, AppLocalizations l10n) {
  const options = [10, 15, 20, 30];
  var selected = 15;

  return showPremiumGeneralDialog<int>(
    context: context,
    barrierLabel: l10n.generateFlashcardsButton,
    child: StatefulBuilder(
      builder: (context, setDialogState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          surfaceTintColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumDialogHeader(
                  title: l10n.generateFlashcardsButton,
                  subtitle: l10n.flashcardCountQuestion,
                  icon: Icons.style_rounded,
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SegmentedButton<int>(
                        segments: [
                          for (final n in options)
                            ButtonSegment(value: n, label: Text('$n')),
                        ],
                        selected: {selected},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) =>
                            setDialogState(() => selected = s.first),
                      ),
                      const SizedBox(height: 32),
                      PremiumSubmitButton(
                        label: l10n.generateFlashcardsButton,
                        isLoading: false,
                        onPressed: () => Navigator.pop(context, selected),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.cancel,
                          style: GoogleFonts.outfit(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
