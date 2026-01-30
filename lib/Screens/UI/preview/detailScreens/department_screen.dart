import 'package:file_picker/file_picker.dart';
import 'package:neo/Screens/Shared/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/ComputerCourses/add_course_dialog.dart'
    show showAddCourseDialog;
import 'package:neo/Screens/UI/preview/detailScreens/course_detail_screen.dart';
import 'package:neo/Screens/UI/preview/detailScreens/pdf_viewer_screen.dart';
import 'package:neo/services/course_material.dart';
import 'package:neo/services/course_model.dart';
import 'package:neo/services/database.dart';
import 'package:url_launcher/url_launcher.dart';

class DepartmentScreen extends StatefulWidget {
  final String departmentName;
  final String departmentId;

  const DepartmentScreen({
    super.key,
    required this.departmentName,
    required this.departmentId,
  });

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  late final DatabaseService _dbService;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      animationDuration: const Duration(milliseconds: 400),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          scrolledUnderElevation: 10,
          title: Text(
            widget.departmentName,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(fontSize: 14),
            indicatorColor: Colors.blueAccent,
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: false,
            labelColor: Colors.blueAccent,
            tabs: const [
              Tab(text: "About", icon: Icon(Icons.info_outline)),
              Tab(text: "Courses", icon: Icon(Icons.school_outlined)),
              Tab(text: "Resources", icon: Icon(Icons.folder_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAboutTab(),
            _buildCoursesTab(),
            _buildResourcesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showUploadSelection,
          tooltip: 'Add Material or Course',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About ${widget.departmentName}",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Details and descriptions about this department will appear here. Students can find general information, faculty details, and more.",
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    return StreamBuilder<List<Course>>(
      stream: _dbService.getCoursesForDepartment(widget.departmentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("No courses found!", _addCourse);
        }

        final courses = snapshot.data!;

        // Group courses by level
        final level200 = courses.where((c) => c.level == '200').toList();
        final level300 = courses.where((c) => c.level == '300').toList();
        final level400 = courses.where((c) => c.level == '400').toList();
        final others = courses
            .where((c) => !['200', '300', '400'].contains(c.level))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (level200.isNotEmpty) ...[
              _buildLevelHeader("Level 200"),
              ...level200.map((c) => _buildCourseTile(c)),
            ],
            if (level300.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLevelHeader("Level 300"),
              ...level300.map((c) => _buildCourseTile(c)),
            ],
            if (level400.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLevelHeader("Level 400"),
              ...level400.map((c) => _buildCourseTile(c)),
            ],
            if (others.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLevelHeader("Other Courses"),
              ...others.map((c) => _buildCourseTile(c)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLevelHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCourseTile(Course course) {
    return FadeInSlide(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ExpansionTile(
          shape: Border.all(color: Colors.transparent),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment, color: Colors.blue),
          ),
          title: Text(
            course.name,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            course.code,
            style: GoogleFonts.outfit(color: Colors.grey[600]),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(course: course),
              ),
            ),
          ),
          children: [_buildCourseMaterials(course)],
        ),
      ),
    );
  }

  Widget _buildCourseMaterials(Course course) {
    return StreamBuilder<List<CourseMaterial>>(
      stream: _dbService.getCourseMaterials(course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: LinearProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return ListTile(
            title: Text(
              "No materials yet",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        final materials = snapshot.data!;
        return Column(
          children: materials.asMap().entries.map((entry) {
            final index = entry.key;
            final m = entry.value;
            return FadeInSlide(
              delay: index * 0.05,
              child: _buildMaterialTile(m),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildResourcesTab() {
    return StreamBuilder<List<CourseMaterial>>(
      stream: _dbService.getDepartmentMaterials(widget.departmentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No department resources yet."));
        }

        final materials = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: materials.length,
          itemBuilder: (context, index) => FadeInSlide(
            delay: index * 0.1,
            child: _buildMaterialTile(materials[index]),
          ),
        );
      },
    );
  }

  Widget _buildMaterialTile(CourseMaterial material) {
    return ListTile(
      dense: true,
      leading: Icon(
        material.fileType == 'pdf'
            ? Icons.picture_as_pdf
            : Icons.insert_drive_file,
        color: Colors.blue[300],
        size: 20,
      ),
      title: Text(
        material.title,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: material.description != null && material.description!.isNotEmpty
          ? Text(
              material.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.download_rounded, size: 20),
      onTap: () => _openFile(material),
    );
  }

  Widget _buildEmptyState(String message, VoidCallback onAction) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: const Text("Add New"),
          ),
        ],
      ),
    );
  }

  void _showUploadSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text("Add New Course"),
              onTap: () {
                Navigator.pop(context);
                _addCourse();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_shared),
              title: const Text("Upload Department Resource"),
              onTap: () {
                Navigator.pop(context);
                _addMaterial(isDepartment: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text("Upload Course Material"),
              onTap: () async {
                Navigator.pop(context);
                final courses = await _dbService
                    .getCoursesForDepartment(widget.departmentId)
                    .first;
                if (courses.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Add a course first!")),
                  );
                  return;
                }
                _showCourseSelectionForUpload(courses);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseSelectionForUpload(List<Course> courses) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Course"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: courses.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(courses[index].name),
              onTap: () {
                Navigator.pop(context);
                _addMaterial(isDepartment: false, course: courses[index]);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addMaterial({
    required bool isDepartment,
    Course? course,
  }) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    FilePickerResult? result;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isDepartment ? "Add Dept Resource" : "Add Course Material",
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (course != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "Course: ${course.name}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  SizedBox(height: 10),
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
              onPressed: () async {
                if (formKey.currentState!.validate() && result != null) {
                  Navigator.pop(context);
                  _uploadLogic(
                    titleController.text,
                    descriptionController.text,
                    result!,
                    isDepartment,
                    course,
                  );
                }
              },
              child: const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadLogic(
    String title,
    String desc,
    FilePickerResult result,
    bool isDept,
    Course? course,
  ) async {
    try {
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) throw "Could not read file";

      final targetId = isDept ? widget.departmentId : course!.code;
      final url = await _dbService.uploadMaterialFile(
        bytes,
        targetId,
        file.name,
        isDept,
      );

      final material = CourseMaterial(
        title: title,
        description: desc,
        fileUrl: url,
        fileName: file.name,
        fileType: file.extension ?? 'file',
        uploadedAt: DateTime.now(),
        departmentId: isDept ? widget.departmentId : null,
        courseId: isDept ? null : course!.id,
      );

      await _dbService.addMaterial(material);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Upload successful!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openFile(CourseMaterial material) async {
    if (material.fileType.toLowerCase() == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PDFViewerScreen(url: material.fileUrl, title: material.title),
        ),
      );
      return;
    }

    final uri = Uri.parse(material.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _addCourse() {
    showAddCourseDialog(context, widget.departmentId);
  }
}
