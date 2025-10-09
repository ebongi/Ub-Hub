import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/services/course_model.dart';
import 'package:neo/services/database.dart';

/// Shows a dialog to add a new course to a department.
Future<void> showAddCourseDialog(
  BuildContext context,
  String departmentId,
) async {
  final dbService = DatabaseService();
  final courseNameController = TextEditingController();
  final courseCodeController = TextEditingController();
  final addCourseKey = GlobalKey<FormState>();

  return showDialog(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        backgroundColor:
            theme.scaffoldBackgroundColor == const Color(0xFF121212)
            ? const Color(0xFF121212)
            : const Color(0xFFF7F8FA),
        title: Text(
          "Add Course",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: addCourseKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: courseNameController,
                decoration: const InputDecoration(labelText: "Course Name"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a course name'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: courseCodeController,
                decoration: const InputDecoration(labelText: "Course Code"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a course code'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (addCourseKey.currentState!.validate()) {
                final newCourse = Course(
                  name: courseNameController.text,
                  code: courseCodeController.text,
                  departmentId: departmentId,
                );
                try {
                  await dbService.createCourse(newCourse);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Text('Course "${newCourse.name}" added!'),
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Failed to add course: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      );
    },
  );
}
