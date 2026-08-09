import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/services/course_model.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/Shared/constanst.dart';


/// Shows a dialog to add a new course to a department.
Future<void> showAddCourseDialog(
  BuildContext context,
  String departmentId, {
  void Function(Course)? onOptimisticCreate,
}) async {
  final userModel = Provider.of<UserModel>(context, listen: false);
  final dbService = DatabaseService(uid: userModel.uid);
  final courseNameController = TextEditingController();

  final courseCodeController = TextEditingController();
  final addCourseKey = GlobalKey<FormState>();
  String? selectedLevel;
  bool isSubmitting = false;
  final l10n = AppLocalizations.of(context)!;

  return showPremiumGeneralDialog(
    context: context,
    barrierLabel: l10n.addCourseTitle,
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PremiumDialogHeader(
                title: l10n.addCourseTitle,
                subtitle: l10n.organizeAcademicContentSubtitle,
                icon: Icons.book_rounded,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Form(
                    key: addCourseKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PremiumTextField(
                          controller: courseNameController,
                          label: l10n.courseNameLabel,
                          hint: l10n.courseNameHintExample,
                          icon: Icons.title_rounded,
                          enabled: true,
                          validator: (value) => value == null || value.isEmpty
                              ? l10n.pleaseEnterCourseName
                              : null,
                        ),
                        const SizedBox(height: 18),
                        PremiumTextField(
                          controller: courseCodeController,
                          label: l10n.courseCodeLabel,
                          hint: l10n.courseCodeHintExample,
                          icon: Icons.code_rounded,
                          enabled: true,
                          validator: (value) => value == null || value.isEmpty
                              ? l10n.pleaseEnterCourseCode
                              : null,
                        ),
                        const SizedBox(height: 18),
                        PremiumDropdownField<String>(
                          value: selectedLevel,
                          label: l10n.levelLabel,
                          hint: l10n.selectAcademicLevelHint,
                          icon: Icons.layers_rounded,
                          enabled: true,
                          items: [
                            DropdownMenuItem(value: "200", child: Text(l10n.levelHeader('200'))),
                            DropdownMenuItem(value: "300", child: Text(l10n.levelHeader('300'))),
                            DropdownMenuItem(value: "400", child: Text(l10n.levelHeader('400'))),
                          ],
                          onChanged: (value) => setDialogState(() => selectedLevel = value),
                          validator: (value) =>
                              value == null ? l10n.pleaseSelectLevel : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel,
                            style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PremiumSubmitButton(
                        label: l10n.addCourseTitle,
                        isLoading: isSubmitting,

                        onPressed: () async {
                          if (addCourseKey.currentState!.validate()) {
                            if (userModel.uid == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.userNotAuthenticatedMessage)),
                              );
                              return;
                            }
                            setDialogState(() => isSubmitting = true);


                            final newCourse = Course(
                              id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                              name: courseNameController.text.trim(),
                              code: courseCodeController.text.trim(),

                              departmentId: departmentId,
                              level: selectedLevel,
                              adminId: userModel.uid,
                              createdAt: DateTime.now(),
                            );


                            // Optimistic Update
                            onOptimisticCreate?.call(newCourse);
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);

                            try {
                              await dbService.createCourse(newCourse).timeout(
                                const Duration(seconds: 15),
                                onTimeout: () => throw 'Connection timed out. Please check your internet.',
                              );
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(ErrorHandler.getFriendlyMessage(e)),
                                  backgroundColor: const Color(0xFF991B1B),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }


                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
