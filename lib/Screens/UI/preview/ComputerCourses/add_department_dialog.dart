// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neo/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/department.dart';

Future<void> showAddDepartmentDialog(BuildContext context) async {
  XFile? imageFile;
  final dbService = DatabaseService();
  final departname = TextEditingController();
  final schoolid = TextEditingController();
  final description = TextEditingController();
  final adddepartmentKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickImage() async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(
              source: ImageSource.gallery,
            );
            if (pickedFile != null) {
              setDialogState(() {
                imageFile = pickedFile;
              });
            }
          }

          return AlertDialog(
            backgroundColor:
                theme.scaffoldBackgroundColor == const Color(0xFF121212)
                    ? const Color(0xFF121212)
                    : const Color(0xFFF7F8FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
            contentTextStyle: GoogleFonts.poppins(),
            title: Center(
              child: Text(
                "Add Department",
                style: GoogleFonts.poppins().copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            content: Form(
              key: adddepartmentKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: departname,
                      autofocus: true,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Department name cannot be empty'
                          : null,
                      decoration: const InputDecoration(
                        hintText: "Deparment name",
                        icon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: schoolid,
                      validator: (value) => value == null || value.isEmpty
                          ? 'School ID cannot be empty'
                          : null,
                      decoration: const InputDecoration(
                        hintText: "School ID",
                        icon: Icon(Icons.school),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      maxLength: 250,
                      maxLines: 2,
                      expands: false,
                      controller: description,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Description cannot be empty'
                          : null,
                      decoration: const InputDecoration(
                        hintText: "Enter the description of your department here",
                        icon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 15),
                    imageFile == null
                        ? OutlinedButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Select Image'),
                          )
                        : Column(
                            children: [
                              FutureBuilder<Uint8List>(
                                future: imageFile!.readAsBytes(),
                                builder: (context, snapshot) =>
                                    snapshot.hasData
                                        ? Image.memory(
                                            snapshot.data!,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : const SizedBox(
                                            height: 100,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                              ),
                              TextButton(
                                onPressed: pickImage,
                                child: const Text('Change Image'),
                              ),
                            ],
                          ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!adddepartmentKey.currentState!.validate()) return;

                  String? imageUrl;
                  try {
                    if (imageFile != null) {
                      final imageBytes = await imageFile!.readAsBytes();
                      imageUrl = await dbService.uploadDepartmentImage(
                        imageBytes,
                        departname.text,
                      );
                    }
                    final newDepartment = Department(
                      id: '', // Firestore will generate this
                      name: departname.text,
                      schoolId: schoolid.text,
                      description: description.text,
                      imageUrl: imageUrl,
                      createdAt: DateTime.now(),
                    );

                    final docRef =
                        await dbService.createDepartment(newDepartment);
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Department "${newDepartment.name}" added successfully!'),
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DepartmentScreen(
                          departmentName: newDepartment.name,
                          departmentId: docRef.id,
                        ),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add department: $e')),
                    );
                  }
                },
                child: const Text("Add"),
              ),
            ],
          );
        },
      );
    },
  );
}