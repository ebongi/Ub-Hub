import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/Shared/compact_list_row.dart';
import 'package:go_study/Screens/UI/preview/ComputerCourses/add_course_dialog.dart'
    show showAddCourseDialog;
import 'package:go_study/Screens/UI/preview/detailScreens/course_detail_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/material_download_actions.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/flashcard_actions.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/flashcard_study_screen.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/course_material.dart';
import 'package:go_study/services/flashcard_model.dart';

import 'package:go_study/services/course_model.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:go_study/services/fapshi_service.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/Screens/UI/preview/Navigation/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/Screens/Shared/shimmer_loading.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/services/recent_activity_service.dart';
import 'package:go_study/core/responsive.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_text_styles.dart';

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
  Department? _department;

  late final Stream<List<Course>> _courseStream;
  late final Stream<List<CourseMaterial>> _materialStream;
  final List<Course> _optimisticCourses = [];
  final List<CourseMaterial> _optimisticMaterials = [];

  @override
  void initState() {
    super.initState();
    final currentUser = Supabase.instance.client.auth.currentUser;
    _dbService = DatabaseService(uid: currentUser?.id);
    _tabController = TabController(length: 5, vsync: this);

    _courseStream = _dbService.getCoursesForDepartment(widget.departmentId);
    _materialStream = _dbService.getDepartmentMaterials(widget.departmentId);
    _loadDepartment();

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

    // Track recent activity
    RecentActivityService().saveRecentDepartment(
      id: widget.departmentId,
      name: widget.departmentName,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartment() async {
    final dept = await _dbService.getDepartment(widget.departmentId);
    if (mounted) {
      setState(() {
        _department = dept;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: context.dynamicSize(120),
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (_department?.adminId ==
                    Supabase.instance.client.auth.currentUser?.id)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.deleteDepartmentDialogTitle),
                            content: Text(
                              l10n.confirmDeleteDepartmentBody(
                                widget.departmentName,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  l10n.deleteButton,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await _dbService.deleteDepartment(
                            widget.departmentId,
                          );
                          if (mounted) {
                            Navigator.pop(context, true);
                            ErrorHandler.showSuccessSnackBar(
                              context,
                              l10n.departmentDeletedMessage,
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.deleteDepartmentMenuItem,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 56,
                  bottom: 16,
                ),
                title: Text(
                  widget.departmentName,
                  style: GoogleFonts.outfit(
                    fontSize: context.dynamicText(22),
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
                    fontSize: context.dynamicText(13),
                  ),
                  unselectedLabelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontSize: context.dynamicText(13),
                  ),
                  tabs: [
                    Tab(
                      text: l10n.aboutTabLabel,
                      icon: const Icon(Icons.info_rounded, size: 20),
                    ),
                    Tab(
                      text: l10n.coursesTabLabel,
                      icon: const Icon(Icons.school_rounded, size: 20),
                    ),
                    Tab(
                      text: l10n.docsTabLabel,
                      icon: const Icon(Icons.description_rounded, size: 20),
                    ),
                    Tab(
                      text: l10n.pqBadge,
                      icon: const Icon(Icons.history_edu_rounded, size: 20),
                    ),
                    Tab(
                      text: l10n.chatTabLabel,
                      icon: const Icon(Icons.forum_rounded, size: 20),
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
              title: l10n.departmentGroupTitle(widget.departmentName),
              subtitle: l10n.departmentalStudyGroupSubtitle,
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
              label: Text(l10n.uploadButton),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            )
          : null,
    );
  }

  Widget _buildAboutTab() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final departmentDescription = _department?.description;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerLow
                  : colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? Colors.white70 : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aboutDepartmentHeader,
                        style: AppText.cardTitle(context).copyWith(
                          fontSize: 16,
                          color: isDark ? Colors.white : colorScheme.primary,
                        ),
                      ),
                      Text(
                        widget.departmentName,
                        style: AppText.body(context).copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.descriptionHeader,
            style: AppText.sectionTitle(
              context,
            ).copyWith(fontSize: 18, color: colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if ((departmentDescription ?? '').isNotEmpty)
            MarkdownBody(
              data: departmentDescription!,
              styleSheet: MarkdownStyleSheet(
                h1: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                h2: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                p: AppText.body(context).copyWith(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                listBullet: AppText.body(
                  context,
                ).copyWith(fontSize: 15, color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            Text(
              l10n.departmentDescriptionPlaceholder,
              style: AppText.body(context).copyWith(
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
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Course>>(
      stream: _courseStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _optimisticCourses.isEmpty) {
          return const CourseListShimmer();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(l10n.errorLoadingMessages(snapshot.error.toString())),
          );
        }

        final serverCourses = snapshot.data ?? [];
        _optimisticCourses.removeWhere(
          (optimistic) =>
              serverCourses.any((server) => server.name == optimistic.name),
        );

        final allCourses = [..._optimisticCourses, ...serverCourses];

        if (allCourses.isEmpty) {
          return _buildEmptyState(l10n.noCoursesFoundMessage, _addCourse);
        }

        final distinctLevels =
            allCourses
                .map((c) => c.level)
                .whereType<String>()
                .where((l) => l.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        final others = allCourses
            .where((c) => c.level == null || c.level!.isEmpty)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (final level in distinctLevels) ...[
              if (level != distinctLevels.first)
                const SizedBox(height: AppSpacing.lg),
              _buildLevelHeader(_sectionHeaderFor(level, l10n)),
              ...ListTile.divideTiles(
                context: context,
                tiles: allCourses
                    .where((c) => c.level == level)
                    .toList()
                    .asMap()
                    .entries
                    .map((e) => _buildCourseTile(e.value, delay: e.key * 0.05)),
              ),
            ],
            if (others.isNotEmpty) ...[
              if (distinctLevels.isNotEmpty)
                const SizedBox(height: AppSpacing.lg),
              _buildLevelHeader(l10n.otherCoursesHeader),
              ...ListTile.divideTiles(
                context: context,
                tiles: others.asMap().entries.map(
                  (e) => _buildCourseTile(e.value, delay: e.key * 0.05),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _sectionHeaderFor(String level, AppLocalizations l10n) {
    final isNumericOnly = RegExp(r'^\d+$').hasMatch(level);
    return isNumericOnly ? l10n.levelHeader(level) : level;
  }

  Widget _buildLevelHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        bottom: AppSpacing.md,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppText.settingsSectionLabel(
          context,
        ).copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildCourseTile(Course course, {double delay = 0}) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isPending = course.id.startsWith('temp_');
    final isAdmin =
        _department?.adminId == Supabase.instance.client.auth.currentUser?.id;

    return FadeInSlide(
      delay: delay,
      child: CompactListRow(
        title: course.name,
        subtitle: course.code,
        icon: Icons.school_outlined,
        tint: colorScheme.primary,
        isPending: isPending,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
        ),
        trailing: isAdmin
            ? PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.deleteCourseDialogTitle),
                        content: Text(
                          l10n.confirmDeleteMaterialBody(course.name),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              l10n.deleteButton,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _dbService.deleteCourse(course.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.courseDeletedMessage)),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n.deleteCourseMenuItem,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildResourcesTab() {
    return StreamBuilder<List<CourseMaterial>>(
      stream: _materialStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _optimisticMaterials.isEmpty) {
          return const MaterialListShimmer();
        }

        final serverMaterials = snapshot.data ?? [];
        _optimisticMaterials.removeWhere(
          (optimistic) =>
              serverMaterials.any((server) => server.title == optimistic.title),
        );

        final allMaterials = [..._optimisticMaterials, ...serverMaterials];
        final materials = allMaterials
            .where((m) => m.materialCategory == 'regular')
            .toList();

        if (materials.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            children: [
              _buildDecksSection(),
              _buildEmptyState(
                AppLocalizations.of(context)!.noResourcesAvailableMessage,
                () {},
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          children: [
            _buildDecksSection(),
            for (int i = 0; i < materials.length; i++) ...[
              FadeInSlide(
                delay: i * 0.05,
                child: _buildMaterialTile(materials[i]),
              ),
              if (i != materials.length - 1) const Divider(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDecksSection() {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<FlashcardDeck>>(
      stream: _dbService.getDecksForDepartment(widget.departmentId),
      builder: (context, snapshot) {
        final decks = snapshot.data ?? const <FlashcardDeck>[];
        if (decks.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Text(
                l10n.flashcardsTitle.toUpperCase(),
                style: AppText.settingsSectionLabel(context),
              ),
            ),
            for (int i = 0; i < decks.length; i++) ...[
              _buildDeckTile(decks[i]),
              if (i != decks.length - 1) const Divider(),
            ],
            SizedBox(height: AppSpacing.sectionGap),
          ],
        );
      },
    );
  }

  Widget _buildDeckTile(FlashcardDeck deck) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return CompactListRow(
      title: deck.title,
      subtitle: l10n.deckCardCountLabel(deck.cardCount),
      icon: Icons.style_rounded,
      tint: Colors.deepPurple,
      onTap: () async {
        try {
          final cards = await _dbService.getCards(deck.id);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlashcardStudyScreen(deck: deck, cards: cards),
            ),
          );
        } catch (e) {
          if (mounted) ErrorHandler.showErrorSnackBar(context, e);
        }
      },
      trailing: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onSelected: (value) async {
          if (value == 'delete') {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.deleteDeckDialogTitle),
                content: Text(l10n.confirmDeleteDeckBody(deck.title)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      l10n.deleteButton,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await _dbService.deleteDeck(deck.id);
            }
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.deleteButton,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastQuestionsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<CourseMaterial>>(
      stream: _materialStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _optimisticMaterials.isEmpty) {
          return const MaterialListShimmer();
        }

        final serverMaterials = snapshot.data ?? [];
        _optimisticMaterials.removeWhere(
          (optimistic) =>
              serverMaterials.any((server) => server.title == optimistic.title),
        );

        final allMaterials = [..._optimisticMaterials, ...serverMaterials];
        final questions = allMaterials
            .where((m) => m.materialCategory == 'past_question')
            .toList();

        if (questions.isEmpty) {
          return _buildEmptyState(
            AppLocalizations.of(context)!.noPastQuestionsAvailableMessage,
            () {},
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final q = questions[index];
            final relatedAnswers = allMaterials
                .where(
                  (m) =>
                      m.materialCategory == 'answer' &&
                      m.linkedMaterialId == q.id,
                )
                .toList();

            return StreamBuilder<List<Course>>(
              stream: _courseStream,
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
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.card),
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
                        padding: const EdgeInsets.all(AppSpacing.md),
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
                        style: AppText.cardTitle(context).copyWith(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(
                          context,
                        )!.pastQuestionAnswersCountSubtitle(
                          relatedAnswers.length,
                        ),
                        style: AppText.cardSubtitle(context),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.download_rounded,
                          color: isDark ? Colors.white70 : colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => handleMaterialDownload(
                          context: context,
                          dbService: _dbService,
                          userProfile: _userProfile,
                          material: q,
                        ),
                      ),
                      children: [
                        if (relatedAnswers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.noAnswersUploadedYet,
                              style: AppText.body(context).copyWith(
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
                                style: AppText.body(context).copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                AppLocalizations.of(
                                  context,
                                )!.verifiedAnswerFeeSubtitle(
                                  FapshiService.getAnswerDownloadFee().toInt(),
                                ),
                                style: AppText.caption(context),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.download_rounded,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () => handleMaterialDownload(
                                  context: context,
                                  dbService: _dbService,
                                  userProfile: _userProfile,
                                  material: a,
                                ),
                              ),
                              onTap: () => openMaterialFile(
                                context: context,
                                dbService: _dbService,
                                userProfile: _userProfile,
                                material: a,
                              ),
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
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;
    switch (category) {
      case 'past_question':
        color = Colors.orange;
        label = l10n.pqBadge;
        break;
      case 'answer':
        color = Colors.green;
        label = l10n.ansBadge;
        break;
      default:
        color = Colors.blue;
        label = l10n.docBadge;
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isPdf = material.fileType.toLowerCase() == 'pdf';
    final isPending = material.id.isEmpty || material.id.startsWith('temp_');
    final canManage =
        material.uploaderId == _dbService.uid ||
        _department?.adminId == _dbService.uid;

    return CompactListRow(
      title: material.title,
      subtitle: material.description != null && material.description!.isNotEmpty
          ? material.description
          : null,
      icon: isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
      tint: isPdf ? Colors.red[400]! : Colors.blue[400]!,
      iconBackgroundColor: (isPdf ? Colors.red : Colors.blue).withOpacity(0.1),
      isPending: isPending,
      onTap: () => openMaterialFile(
        context: context,
        dbService: _dbService,
        userProfile: _userProfile,
        material: material,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCategoryBadge(material.materialCategory),
          const SizedBox(width: AppSpacing.sm),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: isPending ? Colors.grey : colorScheme.primary,
            ),
            enabled: !isPending,
            onSelected: (value) async {
              if (value == 'flashcards') {
                await generateFlashcardsForMaterial(
                  context: context,
                  dbService: _dbService,
                  userProfile: _userProfile,
                  material: material,
                );
              } else if (value == 'download') {
                handleMaterialDownload(
                  context: context,
                  dbService: _dbService,
                  userProfile: _userProfile,
                  material: material,
                );
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.deleteMaterialDialogTitle),
                    content: Text(
                      l10n.confirmDeleteMaterialBody(material.title),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          l10n.deleteButton,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _dbService.deleteMaterial(material.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.materialDeletedMessage)),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              if (isPdf)
                PopupMenuItem(
                  value: 'flashcards',
                  child: Row(
                    children: [
                      const Icon(Icons.style_rounded, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.generateFlashcardsButton),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    const Icon(Icons.download_rounded, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.downloadMenuItem),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n.deleteButton,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, VoidCallback onAction) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
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
            const SizedBox(height: AppSpacing.xxl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.sectionTitle(
                context,
              ).copyWith(fontSize: 18, color: colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.beFirstToContributeMessage,
              textAlign: TextAlign.center,
              style: AppText.body(
                context,
              ).copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (_userProfile?.canUploadMaterial ?? false)
              const SizedBox(height: AppSpacing.xxl),
            if (_userProfile?.canUploadMaterial ?? false)
              FilledButton.icon(
                onPressed: _showUploadSelection,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addNewButton),
              ),
          ],
        ),
      ),
    );
  }

  void _showUploadSelection() {
    final l10n = AppLocalizations.of(context)!;
    if (!(_userProfile?.canUploadMaterial ?? false)) {
      ErrorHandler.showErrorSnackBar(
        context,
        l10n.onlyContributorsCanUploadMessage,
      );
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.sm,
                  ),
                  child: _buildUgcGuidelinesCard(Theme.of(context)),
                ),
                if (_userProfile?.role == UserRole.admin)
                  ListTile(
                    leading: Icon(
                      Icons.school_rounded,
                      color: colorScheme.primary,
                    ),
                    title: Text(l10n.addNewCourseMenuItem),
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
                  title: Text(l10n.uploadDepartmentResourceMenuItem),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddMaterialDialog(isDepartment: true);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.note_add_rounded,
                    color: colorScheme.primary,
                  ),
                  title: Text(l10n.uploadCourseMaterialMenuItem),
                  onTap: () async {
                    Navigator.pop(context);
                    final courses = await _dbService
                        .getCoursesForDepartment(widget.departmentId)
                        .first;
                    if (courses.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.addCourseFirstMessage)),
                      );
                      return;
                    }
                    _showCourseSelectionForUpload(courses);
                  },
                ),
                const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                ListTile(
                  leading: const Icon(
                    Icons.history_edu_rounded,
                    color: Colors.orange,
                  ),
                  title: Text(l10n.uploadPastQuestionMenuItem),
                  onTap: () async {
                    Navigator.pop(context);
                    final courses = await _dbService
                        .getCoursesForDepartment(widget.departmentId)
                        .first;
                    if (courses.isEmpty) {
                      _showAddMaterialDialog(
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
                  title: Text(l10n.uploadAnswerMenuItem),
                  onTap: () async {
                    Navigator.pop(context);
                    final courses = await _dbService
                        .getCoursesForDepartment(widget.departmentId)
                        .first;
                    if (courses.isEmpty) {
                      _showAddMaterialDialog(
                        isDepartment: true,
                        initialCategory: 'answer',
                      );
                    } else {
                      _showCourseSelectionForUpload(
                        courses,
                        category: 'answer',
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCourseSelectionForUpload(
    List<Course> courses, {
    String? category,
    String? linkedId,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showPremiumGeneralDialog(
      context: context,
      barrierLabel: l10n.selectCourseTitle,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sheet),
            ),
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            surfaceTintColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PremiumDialogHeader(
                    title: l10n.selectCourseTitle,
                    subtitle: l10n.whichCourseSubtitle,
                    icon: Icons.book_rounded,
                  ),
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shrinkWrap: true,

                      itemCount: courses.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          tileColor: isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.grey[50],
                          leading: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
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
                            style: AppText.cardTitle(
                              context,
                            ).copyWith(fontSize: 14),
                          ),
                          subtitle: Text(
                            l10n.courseLevelCodeSubtitle(
                              course.level ?? '',
                              course.code,
                            ),
                            style: AppText.cardSubtitle(context),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showAddMaterialDialog(
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      0,
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.outfit(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
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

  void _showAddMaterialDialog({
    required bool isDepartment,
    Course? course,
    String? initialCategory,
    String? initialQuestionId,
  }) {
    if (!(_userProfile?.canUploadMaterial ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = initialCategory ?? 'regular';
    String? selectedQuestionId = initialQuestionId;
    FilePickerResult? result;

    showPremiumGeneralDialog(
      context: context,
      barrierLabel: l10n.addMaterialTitle,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sheet),
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
                      title: isDepartment
                          ? l10n.deptResourceTitle
                          : l10n.addMaterialTitle,
                      subtitle: isDepartment
                          ? l10n.shareFacultyWideDocsSubtitle
                          : l10n.addResourcesForCourseSubtitle(
                              course?.name ?? l10n.courseFallback,
                            ),
                      icon: isDepartment
                          ? Icons.folder_shared_rounded
                          : Icons.note_add_rounded,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            if (course != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.lg,
                                ),
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
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        l10n.courseLabelPrefix(course.name),
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
                              label: l10n.categoryLabel,
                              hint: l10n.selectCategoryHint,
                              icon: Icons.category_rounded,
                              items: [
                                DropdownMenuItem(
                                  value: 'regular',
                                  child: Text(l10n.generalOption),
                                ),
                                DropdownMenuItem(
                                  value: 'past_question',
                                  child: Text(l10n.pastQuestionOption),
                                ),
                                DropdownMenuItem(
                                  value: 'answer',
                                  child: Text(l10n.answerOption),
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
                              const SizedBox(height: AppSpacing.lg),
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
                                        label: l10n.linkToQuestionLabel,
                                        hint: l10n.selectTheQuestionHint,
                                        icon: Icons.link_rounded,
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
                                            ? l10n.requiredValidator
                                            : null,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            PremiumTextField(
                              controller: titleController,
                              label: l10n.titleLabel,
                              hint: l10n.resourceTitleHintExample,
                              icon: Icons.title_rounded,
                              validator: (v) => v == null || v.isEmpty
                                  ? l10n.requiredValidator
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            PremiumTextField(
                              controller: descriptionController,
                              label: l10n.descriptionOptionalLabel,
                              hint: l10n.briefResourceDetailsHint,
                              icon: Icons.notes_rounded,
                              maxLines: 2,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            GestureDetector(
                              onTap: () async {
                                final res = await FilePicker.platform.pickFiles(
                                  withData: true,
                                );
                                if (res != null) {
                                  setState(() => result = res);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: result != null
                                      ? Colors.green.withOpacity(
                                          isDark ? 0.1 : 0.05,
                                        )
                                      : (isDark
                                            ? Colors.white.withOpacity(0.04)
                                            : Colors.grey[50]),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.card,
                                  ),
                                  border: Border.all(
                                    color: result != null
                                        ? Colors.green.withOpacity(0.3)
                                        : (isDark
                                              ? Colors.white10
                                              : Colors.black12),
                                    width: 1.5,
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
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      result != null
                                          ? result!.files.single.name
                                          : l10n.selectResourceFileLabel,
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
                                          ? l10n.readyForUploadLabel
                                          : l10n.pdfDocImagesOnlyHint,
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
                                        vertical: AppSpacing.lg,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      l10n.cancel,
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  flex: 2,
                                  child: PremiumSubmitButton(
                                    label: l10n.uploadResourceButton,
                                    isLoading: false,
                                    onPressed: result == null
                                        ? null
                                        : () {
                                            if (formKey.currentState!
                                                .validate()) {
                                              final tempMaterial = CourseMaterial(
                                                id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                                                title: titleController.text,
                                                description:
                                                    descriptionController.text,
                                                fileUrl: '',
                                                fileName:
                                                    result!.files.single.name,
                                                fileType:
                                                    result!
                                                        .files
                                                        .single
                                                        .extension ??
                                                    'file',
                                                uploadedAt: DateTime.now(),
                                                departmentId:
                                                    widget.departmentId,
                                                courseId: isDepartment
                                                    ? null
                                                    : course!.id,
                                                materialCategory:
                                                    selectedCategory,
                                                isPastQuestion:
                                                    selectedCategory ==
                                                    'past_question',
                                                isAnswer:
                                                    selectedCategory ==
                                                    'answer',
                                                linkedMaterialId:
                                                    selectedQuestionId,
                                                uploaderId: _dbService.uid,
                                              );

                                              setState(() {
                                                _optimisticMaterials.add(
                                                  tempMaterial,
                                                );
                                              });
                                              Navigator.pop(context);

                                              _uploadLogic(
                                                title: titleController.text,
                                                desc:
                                                    descriptionController.text,
                                                result: result!,
                                                isDept: isDepartment,
                                                course: course,
                                                category: selectedCategory,
                                                linkedId: selectedQuestionId,
                                              );
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
        ErrorHandler.showSuccessSnackBar(
          context,
          AppLocalizations.of(context)!.uploadSuccessfulMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  void _addCourse() {
    if (_userProfile?.role != UserRole.admin) {
      ErrorHandler.showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.onlyAdminsCanAddCoursesMessage,
      );
      return;
    }

    showAddCourseDialog(
      context,
      widget.departmentId,
      onOptimisticCreate: (course) {
        setState(() {
          _optimisticCourses.add(course);
        });
      },
    );
  }

  Widget _buildUgcGuidelinesCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: primaryColor.withOpacity(isDark ? 0.2 : 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volunteer_activism_rounded,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.communityContributionCodeTitle,
                style: AppText.cardTitle(
                  context,
                ).copyWith(fontSize: 14, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGuidelineItem(
            Icons.done_all_rounded,
            l10n.guidelineReadableContent,
            theme,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGuidelineItem(
            Icons.find_in_page_rounded,
            l10n.guidelineCheckDuplicate,
            theme,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGuidelineItem(
            Icons.school_rounded,
            l10n.guidelineAcademicOnly,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.black54),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppText.body(context).copyWith(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
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
