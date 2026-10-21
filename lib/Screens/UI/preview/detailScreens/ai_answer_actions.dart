import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:markdown_widget/markdown_widget.dart';

import 'package:go_study/Screens/Shared/ai_usage_gate.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/pdf_viewer_screen.dart'
    show latexGenerator, LatexSyntax;
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/core/pdf_ai_utils.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/course_material.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/gemini_service.dart';
import 'package:go_study/services/profile.dart';

/// Sends a past question's document to Gemini and shows the answer in a
/// bottom sheet. Mirrors `generateFlashcardsForMaterial` (same access/credit
/// gates) and `PDFViewerScreen._summarizeDocument`/`_showSummarySheet` (same
/// result presentation) — kept separate since this is triggered from a list
/// tile's menu rather than from inside the PDF viewer.
Future<void> askAiToAnswerQuestion({
  required BuildContext context,
  required DatabaseService dbService,
  required UserProfile? userProfile,
  required CourseMaterial material,
}) async {
  final l10n = AppLocalizations.of(context)!;

  // Only PDFs have a client-side text-extraction path today (see
  // openMaterialFile) — mirrors generateFlashcardsForMaterial's guard.
  if (material.fileType.toLowerCase() != 'pdf') {
    ErrorHandler.showErrorSnackBar(context, l10n.aiAnswerPdfOnlyMessage);
    return;
  }

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
            Expanded(child: Text(l10n.generatingAiAnswerMessage)),
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
    // Same paid/free-download access gate as viewing or downloading this
    // material (material_download_actions.dart) — this used to be able to
    // read material.fileUrl directly, letting this bypass the paywall.
    final signedUrl = await dbService.requestMaterialAccess(material.id);
    final response = await http
        .get(Uri.parse(signedUrl))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw '${l10n.aiServiceUnavailable} (${response.statusCode})';
    }

    final Uint8List bytes = response.bodyBytes;
    final Object source = extractPdfText(bytes) ?? bytes;

    final answer = await GeminiService()
        .answerQuestion(source)
        .timeout(const Duration(seconds: 90));

    final trimmed = answer.trim();
    if (trimmed == 'OUT_OF_CREDITS') {
      closeProgress();
      if (context.mounted) await AIUsageGate.checkAndShow(context, userProfile);
      return;
    }
    if (looksLikeAiError(trimmed)) {
      throw kDebugMode && trimmed.isNotEmpty ? trimmed : l10n.aiServiceUnavailable;
    }

    closeProgress();
    if (context.mounted) _showAnswerSheet(context, l10n, trimmed);
  } catch (e) {
    closeProgress();
    if (context.mounted) ErrorHandler.showErrorSnackBar(context, e);
  }
}

void _showAnswerSheet(BuildContext context, AppLocalizations l10n, String answer) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              PremiumDialogHeader(
                title: l10n.aiAnswerSheetTitle,
                subtitle: l10n.aiAnswerSheetSubtitle,
                icon: Icons.auto_awesome_rounded,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: MarkdownWidget(
                      data: answer,
                      shrinkWrap: true,
                      config: MarkdownConfig.defaultConfig.copy(
                        configs: [
                          PConfig(
                            textStyle: GoogleFonts.outfit(
                              fontSize: 16,
                              height: 1.6,
                              color: isDark ? Colors.white70 : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      markdownGenerator: MarkdownGenerator(
                        generators: [latexGenerator],
                        inlineSyntaxList: [LatexSyntax()],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: PremiumSubmitButton(
                  label: l10n.gotItButton,
                  isLoading: false,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
