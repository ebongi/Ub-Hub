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
import 'package:neo/services/nkwa_service.dart';
import 'package:neo/services/payment_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final currentUser = Supabase.instance.client.auth.currentUser;
    _dbService = DatabaseService(uid: currentUser?.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: colorScheme.surface,
                scrolledUnderElevation: 2,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 56,
                    bottom: 16,
                  ),
                  title: Text(
                    widget.departmentName,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primaryContainer.withOpacity(0.3),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    indicatorColor: colorScheme.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(
                        text: "About",
                        icon: Icon(Icons.info_rounded, size: 20),
                      ),
                      Tab(
                        text: "Courses",
                        icon: Icon(Icons.school_rounded, size: 20),
                      ),
                      Tab(
                        text: "Docs",
                        icon: Icon(Icons.description_rounded, size: 20),
                      ),
                      Tab(
                        text: "PQ",
                        icon: Icon(Icons.history_edu_rounded, size: 20),
                      ),
                    ],
                  ),
                  colorScheme.surface,
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildAboutTab(),
              _buildCoursesTab(),
              _buildResourcesTab(),
              _buildPastQuestionsTab(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showUploadSelection,
          icon: const Icon(Icons.add_rounded),
          label: const Text("Upload"),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_rounded,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Department Info",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        widget.departmentName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: colorScheme.onSecondaryContainer.withOpacity(
                            0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Description",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Details and descriptions about this department will appear here. Students can find general information, faculty details, and more.",
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
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
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCourseTile(Course course) {
    final colorScheme = Theme.of(context).colorScheme;
    return FadeInSlide(
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            course.name,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            course.code,
            style: GoogleFonts.outfit(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(course: course),
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildCourseMaterials(course),
            ),
          ],
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
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text(
            "No materials yet",
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.outline,
            ),
          );
        }

        final materials = snapshot.data!;
        return Column(
          children: materials.asMap().entries.map((entry) {
            final m = entry.value;
            return _buildMaterialTile(m);
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
          return _buildEmptyState("No resources available", () {});
        }

        final materials = snapshot.data!
            .where((m) => m.materialCategory == 'regular')
            .toList();

        if (materials.isEmpty) {
          return _buildEmptyState("No resources available", () {});
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: materials.length,
          itemBuilder: (context, index) => _buildMaterialTile(materials[index]),
        );
      },
    );
  }

  Widget _buildPastQuestionsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<CourseMaterial>>(
      stream: _dbService.getDepartmentMaterials(widget.departmentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("No past questions available", () {});
        }

        final materials = snapshot.data!;
        final questions = materials
            .where((m) => m.materialCategory == 'past_question')
            .toList();

        if (questions.isEmpty) {
          return _buildEmptyState("No past questions available", () {});
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final q = questions[index];
            final relatedAnswers = materials
                .where(
                  (m) =>
                      m.materialCategory == 'answer' &&
                      m.linkedMaterialId == q.id,
                )
                .toList();

            return Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: colorScheme.secondaryContainer.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
              ),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                collapsedShape: const RoundedRectangleBorder(
                  side: BorderSide.none,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history_edu_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(
                  q.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  "Past Question • ${relatedAnswers.length} Answers",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.download_rounded,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => _handleDownload(q),
                ),
                children: [
                  if (relatedAnswers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No answers uploaded yet",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.outline,
                        ),
                      ),
                    )
                  else
                    ...relatedAnswers.map(
                      (a) => ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.green,
                          size: 18,
                        ),
                        title: Text(
                          a.title,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          "Verified Answer • 300 XAF",
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.download_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          onPressed: () => _handleDownload(a),
                        ),
                        onTap: () => _openFile(a),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialTile(CourseMaterial material) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPdf = material.fileType.toLowerCase() == 'pdf';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isPdf ? Colors.red : Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
          color: isPdf ? Colors.red[400] : Colors.blue[400],
          size: 18,
        ),
      ),
      title: Text(
        material.title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: material.description != null && material.description!.isNotEmpty
          ? Text(
              material.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.download_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
            onPressed: () => _handleDownload(material),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: colorScheme.outline,
          ),
        ],
      ),
      onTap: () => _openFile(material),
    );
  }

  Future<void> _handleDownload(CourseMaterial material) async {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isProcessing = false;

    double fee = NkwaService.getDocumentDownloadFee();
    if (material.materialCategory == 'past_question') {
      fee = NkwaService.getPastQuestionDownloadFee();
    } else if (material.materialCategory == 'answer') {
      fee = NkwaService.getAnswerDownloadFee();
    }

    await showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: Text(
              "Download Material",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      "To download \"${material.title}\" (${material.materialCategory.replaceAll('_', ' ')}), a fee of ${fee.toInt()} XAF is required.",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: phoneController,
                    enabled: !isProcessing,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      labelText: "Payment Phone",
                      hintText: "6xxxxxxxx",
                      prefixIcon: const Icon(Icons.phone_android_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => isProcessing = true);
                        try {
                          await _processDownloadPayment(
                            material,
                            phoneController.text,
                          );
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setState(() => isProcessing = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $e"),
                                backgroundColor: colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Pay & Download",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processDownloadPayment(
    CourseMaterial material,
    String phoneNumber,
  ) async {
    final userId = _dbService.uid;
    if (userId == null) throw "User not authenticated";

    final paymentRef = NkwaService.generatePaymentRef();
    double amount = NkwaService.getDocumentDownloadFee();
    if (material.materialCategory == 'past_question') {
      amount = NkwaService.getPastQuestionDownloadFee();
    } else if (material.materialCategory == 'answer') {
      amount = NkwaService.getAnswerDownloadFee();
    }
    final formattedPhone = NkwaService.formatPhoneNumber(phoneNumber);

    // 1. Create pending transaction
    final transaction = PaymentTransaction(
      id: '',
      userId: userId,
      paymentRef: paymentRef,
      amount: amount,
      currency: NkwaService.getCurrency(),
      status: PaymentStatus.pending,
      materialId: material.id,
      itemType: 'download',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _dbService.createPaymentTransaction(transaction);

    // 2. Initiate Payment
    final collectResponse = await NkwaService.collectPayment(
      amount: amount,
      phoneNumber: formattedPhone,
      description: 'Download: ${material.title}',
    );

    final nkwaPaymentId = collectResponse['id'] ?? collectResponse['paymentId'];
    if (nkwaPaymentId == null) throw "Failed to initiate payment";

    // 3. Poll
    PaymentStatus status = PaymentStatus.pending;
    int attempts = 0;
    while (status == PaymentStatus.pending && attempts < 60) {
      // 3 minutes total
      print('Polling attempt ${attempts + 1}/60 for download...');
      await Future.delayed(const Duration(seconds: 3));
      status = await NkwaService.checkPaymentStatus(nkwaPaymentId.toString());
      attempts++;
    }

    // 4. Update status
    await _dbService.updatePaymentStatus(
      paymentRef,
      status,
      materialId: material.id,
    );

    if (status == PaymentStatus.success) {
      final uri = Uri.parse(material.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch download link';
      }
    } else {
      throw "Payment failed or timed out.";
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

    // For other files, treat as download (which currently requires payment)
    _handleDownload(material);
  }

  Widget _buildEmptyState(String message, VoidCallback onAction) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Be the first to contribute to this department's resources!",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showUploadSelection,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Add New"),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadSelection() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.school_rounded, color: colorScheme.primary),
              title: const Text("Add New Course"),
              onTap: () {
                Navigator.pop(context);
                _addCourse();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.folder_shared_rounded,
                color: colorScheme.primary,
              ),
              title: const Text("Upload Department Resource"),
              onTap: () {
                Navigator.pop(context);
                _addMaterial(isDepartment: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.note_add_rounded, color: colorScheme.primary),
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
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(
                Icons.history_edu_rounded,
                color: Colors.orange,
              ),
              title: const Text("Upload Past Question"),
              onTap: () async {
                Navigator.pop(context);
                final courses = await _dbService
                    .getCoursesForDepartment(widget.departmentId)
                    .first;
                if (courses.isEmpty) {
                  _addMaterial(
                    isDepartment: true,
                    initialCategory: 'past_question',
                  );
                } else {
                  _showCourseSelectionForUpload(
                    courses,
                    category: 'past_question',
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
              ),
              title: const Text("Upload Answer"),
              onTap: () async {
                Navigator.pop(context);
                final courses = await _dbService
                    .getCoursesForDepartment(widget.departmentId)
                    .first;
                if (courses.isEmpty) {
                  _addMaterial(isDepartment: true, initialCategory: 'answer');
                } else {
                  _showCourseSelectionForUpload(courses, category: 'answer');
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showCourseSelectionForUpload(
    List<Course> courses, {
    String? category,
    String? linkedId,
  }) {
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
                _addMaterial(
                  isDepartment: false,
                  course: courses[index],
                  initialCategory: category,
                  initialQuestionId: linkedId,
                );
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
    String? initialCategory,
    String? initialQuestionId,
  }) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    FilePickerResult? result;
    String selectedCategory = initialCategory ?? 'regular';
    String? selectedQuestionId = initialQuestionId;

    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: Text(
              isDepartment ? "Add Dept Resource" : "Add Course Material",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (course != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withOpacity(
                            0.4,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Course: ${course.name}",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      style: GoogleFonts.outfit(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.category_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'regular',
                          child: Text("General"),
                        ),
                        DropdownMenuItem(
                          value: 'past_question',
                          child: Text("Past Question"),
                        ),
                        DropdownMenuItem(
                          value: 'answer',
                          child: Text("Answer"),
                        ),
                      ],
                      onChanged: isUploading
                          ? null
                          : (v) {
                              setState(() {
                                selectedCategory = v!;
                                if (selectedCategory != 'answer') {
                                  selectedQuestionId = null;
                                }
                              });
                            },
                    ),
                    if (selectedCategory == 'answer') ...[
                      const SizedBox(height: 16),
                      StreamBuilder<List<CourseMaterial>>(
                        stream: isDepartment
                            ? _dbService.getDepartmentMaterials(
                                widget.departmentId,
                              )
                            : _dbService.getCourseMaterials(course!.id),
                        builder: (context, snapshot) {
                          final questions =
                              snapshot.data
                                  ?.where(
                                    (m) =>
                                        m.materialCategory == 'past_question',
                                  )
                                  .toList() ??
                              [];
                          return DropdownButtonFormField<String>(
                            value: selectedQuestionId,
                            style: GoogleFonts.outfit(
                              color: colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: "Link to Question",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.link_rounded),
                            ),
                            items: questions
                                .map(
                                  (q) => DropdownMenuItem(
                                    value: q.id,
                                    child: Text(
                                      q.title,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: isUploading
                                ? null
                                : (v) => setState(() => selectedQuestionId = v),
                            validator: (v) =>
                                selectedCategory == 'answer' && v == null
                                ? "Required for answers"
                                : null,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      enabled: !isUploading,
                      style: GoogleFonts.outfit(),
                      decoration: InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title_rounded),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      enabled: !isUploading,
                      style: GoogleFonts.outfit(),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Description (Optional)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: isUploading
                          ? null
                          : () async {
                              final res = await FilePicker.platform.pickFiles(
                                withData: true,
                              );
                              if (res != null) setState(() => result = res);
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: result == null
                                ? colorScheme.outline
                                : colorScheme.primary,
                            width: result == null ? 1 : 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: result == null
                              ? Colors.transparent
                              : colorScheme.primary.withOpacity(0.05),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              result == null
                                  ? Icons.upload_file_rounded
                                  : Icons.check_circle_rounded,
                              color: result == null
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                result == null
                                    ? "Select file to upload"
                                    : result!.files.single.name,
                                style: GoogleFonts.outfit(
                                  color: result == null
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                  fontWeight: result == null
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Uploads are always free!",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.outfit(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: (isUploading || result == null)
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setState(() => isUploading = true);
                          try {
                            await _uploadLogic(
                              title: titleController.text,
                              desc: descriptionController.text,
                              result: result!,
                              isDept: isDepartment,
                              course: course,
                              category: selectedCategory,
                              linkedId: selectedQuestionId,
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setState(() => isUploading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: $e"),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                icon: isUploading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  isUploading ? "Uploading..." : "Upload",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadLogic({
    required String title,
    required String desc,
    required FilePickerResult result,
    required bool isDept,
    Course? course,
    String category = 'regular',
    String? linkedId,
  }) async {
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
        materialCategory: category,
        isPastQuestion: category == 'past_question',
        isAnswer: category == 'answer',
        linkedMaterialId: linkedId,
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

  void _addCourse() {
    showAddCourseDialog(context, widget.departmentId);
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
