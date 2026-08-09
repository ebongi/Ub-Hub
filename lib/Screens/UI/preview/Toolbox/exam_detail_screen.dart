import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/exam_event.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/create_exam_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';

class ExamDetailScreen extends StatelessWidget {
  final ExamEvent exam;
  const ExamDetailScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final startStr = DateFormat('dd-MMM-yyyy HH:mm:ss').format(exam.startTime);
    final endStr = DateFormat('dd-MMM-yyyy HH:mm:ss').format(exam.endTime);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.eventsCalendarTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateExamScreen(exam: exam)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(l10n.eventIdLabel, exam.id.substring(0, 8).toUpperCase()),
            _buildDetailItem(l10n.eventNameLabel, exam.name),
            _buildDetailItem(l10n.eventCategoryLabel, exam.category),
            _buildDetailItem(
              l10n.descriptionLabel,
              exam.description ?? l10n.noDescriptionProvided,
            ),
            _buildDetailItem(l10n.venueLabel, exam.venue ?? l10n.tbdValue),
            _buildDetailItem(l10n.eventStartTimeLabel, startStr),
            _buildDetailItem(l10n.eventEndTimeLabel, endStr),
            _buildDetailItem(
              l10n.eventStatusLabel,
              exam.status.toUpperCase(),
              color: Colors.green,
            ),

            if (exam.imageUrl != null) ...[
              const SizedBox(height: 24),
              Text(
                l10n.eventImageLabel,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: exam.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ],

            const SizedBox(height: 40),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  l10n.addCommentButton,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showPremiumGeneralDialog(
      context: context,
      barrierLabel: l10n.deleteEventTitle,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumDialogHeader(
              title: l10n.deleteEventTitle,
              subtitle: l10n.deleteChatDialogSubtitle,
              icon: Icons.delete_forever_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Text(
                    l10n.confirmDeleteEventBody,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PremiumSubmitButton(
                          label: l10n.deleteNowButton,
                          isLoading: false,
                          onPressed: () async {
                            final user =
                                Supabase.instance.client.auth.currentUser;
                            if (user != null) {
                              await DatabaseService(uid: user.id)
                                  .deleteExam(exam.id);
                              if (context.mounted) {
                                Navigator.pop(context); // Pop dialog
                                Navigator.pop(context); // Pop detail screen
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
