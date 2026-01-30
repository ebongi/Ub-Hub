import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/detailScreens/pdf_viewer_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addMaterial(),
          ),
        ],
      ),
      body: StreamBuilder<List<CourseMaterial>>(
        stream: _dbService.getCourseMaterials(widget.course.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No materials for this course yet.",
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final materials = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            itemBuilder: (context, index) =>
                _buildMaterialTile(materials[index]),
          );
        },
      ),
    );
  }

  Widget _buildMaterialTile(CourseMaterial material) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          material.fileType == 'pdf'
              ? Icons.picture_as_pdf
              : Icons.insert_drive_file,
          color: Colors.red,
        ),
        title: Text(
          material.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        subtitle: material.description != null
            ? Text(
                material.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 12),
              )
            : null,
        trailing: const Icon(Icons.download),
        onTap: () async {
          if (material.fileType.toLowerCase() == 'pdf') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PDFViewerScreen(
                  url: material.fileUrl,
                  title: material.title,
                ),
              ),
            );
            return;
          }

          final uri = Uri.parse(material.fileUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  Future<void> _addMaterial() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    FilePickerResult? result;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Course Material"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 20),
                  result == null
                      ? ElevatedButton.icon(
                          onPressed: () async {
                            final res = await FilePicker.platform.pickFiles(
                              withData: true,
                            );
                            if (res != null) setState(() => result = res);
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text("Select File"),
                        )
                      : Text("Selected: ${result!.files.single.name}"),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate() && result != null) {
                        setState(() => isLoading = true);
                        try {
                          final file = result!.files.single;
                          final url = await _dbService.uploadMaterialFile(
                            file.bytes!,
                            widget.course.code,
                            file.name,
                            false,
                          );

                          final material = CourseMaterial(
                            title: titleController.text,
                            description: descriptionController.text,
                            fileUrl: url,
                            fileName: file.name,
                            fileType: file.extension ?? 'file',
                            uploadedAt: DateTime.now(),
                            courseId: widget.course.id,
                          );

                          await _dbService.addMaterial(material);
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        } finally {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }
}
