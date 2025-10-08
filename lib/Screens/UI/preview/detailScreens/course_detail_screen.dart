import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/services/course_material.dart';
import 'package:neo/services/course_model.dart';
import 'package:neo/services/database.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final DatabaseService _dbService = DatabaseService();

  Future<void> _addMaterial() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    FilePickerResult? result;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add New Material"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: "Title"),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: "Description (Optional)"),
                      ),
                      const SizedBox(height: 20),
                      result == null
                          ? OutlinedButton.icon(
                              onPressed: () async {
                                final pickedFile = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg'],
                                );
                                if (pickedFile != null) {
                                  setDialogState(() => result = pickedFile);
                                }
                              },
                              icon: const Icon(Icons.attach_file),
                              label: const Text("Select File"),
                            )
                          : Column(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 30),
                                Text(result!.files.single.name, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate() && result != null) {
                      Navigator.pop(dialogContext); // Close dialog immediately
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Uploading material...'), duration: Duration(seconds: 10)),
                      );

                      try {
                        final file = result!.files.single;
                        final fileBytes = file.bytes;

                        if (fileBytes == null) {
                          // This can happen if the file is too large or on certain platforms.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not read file data. Please try another file.'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        final fileName = file.name;

                        final fileUrl = await _dbService.uploadCourseMaterialFile(fileBytes, widget.course.code, fileName);

                        final newMaterial = CourseMaterial(
                          courseId: widget.course.code,
                          title: titleController.text,
                          description: descriptionController.text,
                          fileUrl: fileUrl,
                          fileName: fileName,
                          fileType: file.extension ?? 'file',
                          uploadedAt: DateTime.now(),
                        );

                        await _dbService.addCourseMaterial(newMaterial);

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Material added successfully!'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } else if (result == null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a file.'), backgroundColor: Colors.orange),
                      );
                    }
                  },
                  child: const Text("Upload"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.course.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          bottom: const TabBar(
            tabs: [
              Tab(text: "About"),
              Tab(text: "Resources"),
              Tab(text: "Questions"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAboutTab(),
            _buildResourcesTab(),
            const Center(child: Text("Past Questions will be available here.")),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addMaterial,
          tooltip: 'Add Material',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Course Code: ${widget.course.code}', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600)),
          const Divider(height: 32),
          _buildDetailSection(context, icon: Icons.info_outline, title: 'About this course', content: 'Details about this course will be available here soon.'),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    return StreamBuilder<List<CourseMaterial>>(
      stream: _dbService.getCourseMaterials(widget.course.code),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No materials yet. Be the first to add one!"));
        }
        final materials = snapshot.data!;
        return ListView.builder(
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final material = materials[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(material.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file, color: Colors.blue),
                title: Text(material.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text(material.fileName),
                onTap: () async {
                  final url = Uri.parse(material.fileUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open ${material.fileName}')),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection(BuildContext context, {required IconData icon, required String title, required String content}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text(content, style: GoogleFonts.poppins()),
      ),
    );
  }
}