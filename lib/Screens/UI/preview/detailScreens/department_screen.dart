import 'package:file_picker/file_picker.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/UI/preview/ComputerCourses/add_course_dialog.dart'
    show showAddCourseDialog;
import 'package:go_study/Screens/UI/preview/detailScreens/course_detail_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/pdf_viewer_screen.dart';
import 'package:go_study/services/course_material.dart';
import 'package:go_study/services/course_model.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/nkwa_service.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/services/subscription_service.dart';
import 'package:go_study/services/storage_service.dart';
import 'package:go_study/Screens/UI/preview/Navigation/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_study/Screens/Shared/shimmer_loading.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

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

class _DepartmentScreenState extends State<DepartmentScreen>
    with SingleTickerProviderStateMixin {
  late final DatabaseService _dbService;
  late final TabController _tabController;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    final currentUser = Supabase.instance.client.auth.currentUser;
    _dbService = DatabaseService(uid: currentUser?.id);
    _tabController = TabController(length: 5, vsync: this);

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _dbService.userProfile.listen((profile) {
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
                background: Container(
                  color: isDark
                      ? theme.scaffoldBackgroundColor
                      : theme.colorScheme.primary.withOpacity(0.02),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
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
                    Tab(
                      text: "Chat",
                      icon: Icon(Icons.forum_rounded, size: 20),
                    ),
                  ],
                ),
                colorScheme.surface,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAboutTab(),
            _buildCoursesTab(),
            _buildResourcesTab(),
            _buildPastQuestionsTab(),
            ChatScreen(
              roomId: widget.departmentId,
              title: "${widget.departmentName} Group",
              subtitle: "Departmental Study Group",
            ),
          ],
        ),
      ),
      floatingActionButton:
          (_userProfile?.canUploadMaterial ?? false) &&
              _tabController.index != 4
          ? FloatingActionButton.extended(
              onPressed: _showUploadSelection,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Upload"),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            )
          : null,
    );
  }

  Widget _buildAboutTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerLow
                  : colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? Colors.white70 : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "About Department",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : colorScheme.primary,
                        ),
                      ),
                      Text(
                        widget.departmentName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
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
          return const CourseListShimmer();
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
              ...level200.asMap().entries.map(
                (e) => _buildCourseTile(e.value, delay: e.key * 0.05),
              ),
            ],
            if (level300.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLevelHeader("Level 300"),
              ...level300.asMap().entries.map(
                (e) => _buildCourseTile(e.value, delay: e.key * 0.05),
              ),
            ],
            if (level400.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLevelHeader("Level 400"),
              ...level400.asMap().entries.map(
                (e) => _buildCourseTile(e.value, delay: e.key * 0.05),
              ),
            ],
            if (others.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLevelHeader("Other Courses"),
              ...others.asMap().entries.map(
                (e) => _buildCourseTile(e.value, delay: e.key * 0.05),
              ),
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

  Widget _buildCourseTile(Course course, {double delay = 0}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    return FadeInSlide(
      delay: delay,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.15),
          ),
        ),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.school_outlined,
              color: isDark ? Colors.white70 : colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            course.name,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            course.code,
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 13,
            ),
          ),
          trailing: IconButton(
            tooltip: "Course Materials",
            icon: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: isDark ? Colors.white70 : colorScheme.primary,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          return const MaterialListShimmer();
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
          itemBuilder: (context, index) => FadeInSlide(
            delay: index * 0.05,
            child: _buildMaterialTile(materials[index]),
          ),
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
          return const MaterialListShimmer();
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

            return StreamBuilder<List<Course>>(
              stream: _dbService.getCoursesForDepartment(widget.departmentId),
              builder: (context, courseSnapshot) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final course = courseSnapshot.data
                    ?.where((c) => c.id == q.courseId)
                    .firstOrNull;
                final courseCode = course != null ? " • ${course.code}" : "";

                return FadeInSlide(
                  delay: index * 0.05,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: isDark
                          ? colorScheme.surfaceContainerLow
                          : Colors.white,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.15),
                      ),
                    ),
                    child: ExpansionTile(
                      shape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      collapsedShape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.history_edu_outlined,
                          color: Colors.orange[400],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        "${q.title}$courseCode",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        "Past Question • ${relatedAnswers.length} Answers",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.download_rounded,
                          color: isDark ? Colors.white70 : colorScheme.primary,
                          size: 20,
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color color;
    String label;
    switch (category) {
      case 'past_question':
        color = Colors.orange;
        label = "PQ";
        break;
      case 'answer':
        color = Colors.green;
        label = "ANS";
        break;
      default:
        color = Colors.blue;
        label = "DOC";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              material.title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildCategoryBadge(material.materialCategory),
        ],
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
    // If user is a contributor or admin, or has a premium subscription, skip payment
    if (_userProfile != null &&
        SubscriptionService.canDownloadForFree(_userProfile!)) {
      // Secure for offline use
      await _secureForOffline(material);

      // Increment free download count if not unlimited
      if (!_userProfile!.hasUnlimitedDownloads) {
        await _dbService.incrementFreeDownloadCount();
      }

      final uri = Uri.parse(material.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch download link")),
          );
        }
      }
      return;
    }

    // Otherwise, show payment dialog (existing logic)
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isProcessing = false;

    double fee = NkwaService.getDocumentDownloadFee();
    if (material.materialCategory == 'past_question') {
      fee = NkwaService.getPastQuestionDownloadFee();
    } else if (material.materialCategory == 'answer') {
      fee = NkwaService.getAnswerDownloadFee();
    }

    await showPremiumGeneralDialog(
      context: context,
      barrierLabel: "Download",
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
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
                    title: "Download Material",
                    subtitle: "Secure access to study resources",
                    icon: Icons.download_for_offline_rounded,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : theme.colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : theme.colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                              ),
                            ),
                            child: Text(
                              "To download \"${material.title}\" (${material.materialCategory.replaceAll('_', ' ')}), a fee of ${fee.toInt()} XAF is required.",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          PremiumTextField(
                            controller: phoneController,
                            label: "Payment Phone",
                            hint: "6xxxxxxxx (MTN/Orange)",
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            enabled: !isProcessing,
                            validator: (v) =>
                                v == null || v.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: isProcessing
                                      ? null
                                      : () => Navigator.pop(context),
                                  child: Text(
                                    "Cancel",
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: PremiumSubmitButton(
                                  label: "Pay & Download",
                                  isLoading: isProcessing,
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setState(() => isProcessing = true);
                                    try {
                                      await _processDownloadPayment(
                                        material,
                                        phoneController.text,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      setState(() => isProcessing = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text("Error: $e"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
      // Automatic secure download for offline use
      await _secureForOffline(material);

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

  Future<void> _secureForOffline(CourseMaterial material) async {
    try {
      await StorageService().downloadAndEncrypt(
        material.fileUrl,
        material.id,
        material.fileName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Material secured for offline access! 🔒"),
          ),
        );
      }
    } catch (e) {
      print("Offline cache failed: $e");
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
            if (_userProfile?.canUploadMaterial ?? false)
              const SizedBox(height: 24),
            if (_userProfile?.canUploadMaterial ?? false)
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
    if (!(_userProfile?.canUploadMaterial ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only contributors and admins can upload content.')),
      );
      return;
    }
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
    showPremiumGeneralDialog(
      context: context,
      barrierLabel: "Select Course",
      child: Builder(
        builder: (context) {
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
                  title: "Select Course",
                  subtitle: "Which course is this for?",
                  icon: Icons.book_rounded,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shrinkWrap: true,
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: isDark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.grey[50],
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          course.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "Level ${course.level} • ${course.code}",
                          style: GoogleFonts.outfit(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _addMaterial(
                            isDepartment: false,
                            course: course,
                            initialCategory: category,
                            initialQuestionId: linkedId,
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addMaterial({
    required bool isDepartment,
    Course? course,
    String? initialCategory,
    String? initialQuestionId,
  }) async {
    if (!(_userProfile?.canUploadMaterial ?? false)) return;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    FilePickerResult? result;
    String selectedCategory = initialCategory ?? 'regular';
    String? selectedQuestionId = initialQuestionId;

    bool isUploading = false;

    await showPremiumGeneralDialog(
      context: context,
      barrierLabel: "Add Material",
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              surfaceTintColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumDialogHeader(
                      title: isDepartment ? "Dept Resource" : "Add Material",
                      subtitle: isDepartment
                          ? "Share faculty-wide documents"
                          : "Add resources for ${course?.name ?? 'Course'}",
                      icon: isDepartment
                          ? Icons.folder_shared_rounded
                          : Icons.note_add_rounded,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            if (course != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Course: ${course.name}",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            PremiumDropdownField<String>(
                              value: selectedCategory,
                              label: "Category",
                              hint: "Select category",
                              icon: Icons.category_rounded,
                              enabled: !isUploading,
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
                              onChanged: (v) {
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
                              StreamBuilder<List<Course>>(
                                stream: _dbService.getCoursesForDepartment(
                                  widget.departmentId,
                                ),
                                builder: (context, courseSnapshot) {
                                  final coursesList = courseSnapshot.data ?? [];
                                  return StreamBuilder<List<CourseMaterial>>(
                                    stream: isDepartment
                                        ? _dbService.getDepartmentMaterials(
                                            widget.departmentId,
                                          )
                                        : _dbService.getCourseMaterials(
                                            course!.id,
                                          ),
                                    builder: (context, snapshot) {
                                      final questions =
                                          snapshot.data
                                              ?.where(
                                                (m) =>
                                                    m.materialCategory ==
                                                    'past_question',
                                              )
                                              .toList() ??
                                          [];
                                      return PremiumDropdownField<String>(
                                        value: selectedQuestionId,
                                        label: "Link to Question",
                                        hint: "Select the question",
                                        icon: Icons.link_rounded,
                                        enabled: !isUploading,
                                        items: questions.map((q) {
                                          final c = coursesList
                                              .where((x) => x.id == q.courseId)
                                              .firstOrNull;
                                          final prefix = c != null
                                              ? "[${c.code}] "
                                              : "";
                                          return DropdownMenuItem(
                                            value: q.id,
                                            child: Text(
                                              "$prefix${q.title}",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (v) => setState(
                                          () => selectedQuestionId = v,
                                        ),
                                        validator: (v) =>
                                            selectedCategory == 'answer' &&
                                                v == null
                                            ? "Required"
                                            : null,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                            PremiumTextField(
                              controller: titleController,
                              label: "Title",
                              hint: "e.g. Exam Prep Notes",
                              icon: Icons.title_rounded,
                              enabled: !isUploading,
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Required" : null,
                            ),
                            const SizedBox(height: 16),
                            PremiumTextField(
                              controller: descriptionController,
                              label: "Description (Optional)",
                              hint: "Brief details about the resource",
                              icon: Icons.notes_rounded,
                              enabled: !isUploading,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 24),
                            // File Selection Zone
                            GestureDetector(
                              onTap: isUploading
                                  ? null
                                  : () async {
                                      final res = await FilePicker.platform
                                          .pickFiles(withData: true);
                                      if (res != null) {
                                        setState(() => result = res);
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: result != null
                                      ? Colors.green.withOpacity(
                                          isDark ? 0.1 : 0.05,
                                        )
                                      : (isDark
                                            ? Colors.white.withOpacity(0.04)
                                            : Colors.grey[50]),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: result != null
                                        ? Colors.green.withOpacity(0.3)
                                        : (isDark
                                              ? Colors.white10
                                              : Colors.black12),
                                    width: 1.5,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      result != null
                                          ? Icons.check_circle_rounded
                                          : Icons.cloud_upload_outlined,
                                      size: 32,
                                      color: result != null
                                          ? Colors.green
                                          : theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      result != null
                                          ? result!.files.single.name
                                          : "Select Resource File",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      result != null
                                          ? "Ready for upload"
                                          : "PDF, DOC, or Images only",
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: isUploading
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: PremiumSubmitButton(
                                    label: isUploading
                                        ? "Uploading..."
                                        : "Upload Resource",
                                    isLoading: isUploading,
                                    onPressed: (isUploading || result == null)
                                        ? null
                                        : () async {
                                            if (formKey.currentState!
                                                .validate()) {
                                              setState(
                                                () => isUploading = true,
                                              );
                                              try {
                                                await _uploadLogic(
                                                  title: titleController.text,
                                                  desc: descriptionController
                                                      .text,
                                                  result: result!,
                                                  isDept: isDepartment,
                                                  course: course,
                                                  category: selectedCategory,
                                                  linkedId: selectedQuestionId,
                                                );
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                }
                                              } catch (e) {
                                                setState(
                                                  () => isUploading = false,
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Error: $e",
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
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
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
        departmentId: widget.departmentId,
        courseId: isDept ? null : course!.id,
        materialCategory: category,
        isPastQuestion: category == 'past_question',
        isAnswer: category == 'answer',
        linkedMaterialId: linkedId,
        uploaderId: _dbService.uid,
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
    if (!(_userProfile?.canCreateDepartment ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only contributors and admins can add courses.')),
      );
      return;
    }
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
