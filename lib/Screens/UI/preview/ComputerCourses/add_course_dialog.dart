import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/course_model.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

/// Shows a dialog to add a new course to a department.
Future<void> showAddCourseDialog(
  BuildContext context,
  String departmentId,
) async {
  final dbService = DatabaseService();
  final courseNameController = TextEditingController();
  final courseCodeController = TextEditingController();
  final addCourseKey = GlobalKey<FormState>();
  String? selectedLevel;
  bool isLoading = false;

  return showPremiumGeneralDialog(
    context: context,
    barrierLabel: "Add Course",
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
              const PremiumDialogHeader(
                title: "Add Course",
                subtitle: "Organize your academic content",
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
                          label: "Course Name",
                          hint: "e.g. Data Structures",
                          icon: Icons.title_rounded,
                          enabled: !isLoading,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a course name'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        PremiumTextField(
                          controller: courseCodeController,
                          label: "Course Code",
                          hint: "e.g. CS201",
                          icon: Icons.code_rounded,
                          enabled: !isLoading,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a course code'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        PremiumDropdownField<String>(
                          value: selectedLevel,
                          label: "Level",
                          hint: "Select academic level",
                          icon: Icons.layers_rounded,
                          enabled: !isLoading,
                          items: const [
                            DropdownMenuItem(value: "200", child: Text("Level 200")),
                            DropdownMenuItem(value: "300", child: Text("Level 300")),
                            DropdownMenuItem(value: "400", child: Text("Level 400")),
                          ],
                          onChanged: (value) => setDialogState(() => selectedLevel = value),
                          validator: (value) =>
                              value == null ? 'Please select a level' : null,
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
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        child: Text("Cancel",
                            style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PremiumSubmitButton(
                        label: "Add Course",
                        isLoading: isLoading,
                        onPressed: () async {
                          if (addCourseKey.currentState!.validate()) {
                            setDialogState(() => isLoading = true);
                            final newCourse = Course(
                              name: courseNameController.text,
                              code: courseCodeController.text,
                              departmentId: departmentId,
                              level: selectedLevel,
                              createdAt: DateTime.now(),
                            );
                            try {
                              await dbService.createCourse(newCourse);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('Course "${newCourse.name}" added!'),
                                ),
                              );
                            } catch (e) {
                              setDialogState(() => isLoading = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text('Failed to add course: $e'),
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
