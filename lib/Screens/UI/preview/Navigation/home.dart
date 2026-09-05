// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/Screens/Shared/content_media_card.dart';
import 'package:go_study/Screens/Shared/department_ui_data.dart';
import 'package:go_study/Screens/Shared/section_header.dart';
import 'package:go_study/Screens/UI/preview/Navigation/chat_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/portalScreen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/weekly_progress_card.dart';
import 'package:go_study/Screens/UI/preview/Settings/notifications.dart';
import 'package:go_study/Screens/UI/preview/Settings/rating.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/TranscriptScreen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/ai_study_plan_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/exam_schedule_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/focus_timer_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/marketplace_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/news_feed_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/offline_library_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/performance_tracker_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/task_manager_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/all_departments_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/subscription_plans_screen.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:go_study/services/departments_provider.dart';
import 'package:go_study/services/institution.dart';
import 'package:go_study/services/message_provider.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/services/quote_service.dart';
import 'package:go_study/services/recent_activity_service.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/knowledge_bot_chat_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/gemma_chat_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_study/core/responsive.dart';

import '../../../../services/notification_service.dart';

class ToolItem {
  final String name;
  final IconData icon;
  final Color backgroundColor;
  final Color brandColor;
  final Widget widget;
  final bool comingSoon;

  ToolItem({
    required this.name,
    required this.icon,
    required this.backgroundColor,
    required this.brandColor,
    required this.widget,
    this.comingSoon = false,
  });
}

class Home extends StatefulWidget {
  final SupabaseClient? supabaseClient;

  const Home({super.key, this.supabaseClient});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final SupabaseClient _supabase;

  UserProfile? _userProfile;
  RecentActivity? _recentActivity;

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient ?? Supabase.instance.client;
    _maybeShowRatingPrompt();

    _loadRecentActivity();

    final db = DatabaseService(uid: _supabase.auth.currentUser?.id);
    db.userProfile.listen((profile) async {
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });

        // Fetch institution name — falls back to the default institution
        // (kDefaultInstitutionId) so a user who hasn't picked one yet still
        // sees a real name here instead of the generic portal label.
        final inst = await db.getInstitution(
          profile.institutionId ?? kDefaultInstitutionId,
        );
        final institutionName = inst?.name;

        // Sync with global UserModel provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final userModel = Provider.of<UserModel>(context, listen: false);
            userModel.update(
              name: profile.name,
              matricule: profile.matricule,
              phoneNumber: profile.phoneNumber,
              institutionId: profile.institutionId,
              institutionName: institutionName,
            );
          }
        });
      }
    });
  }

  // No longer needed, using Provider instead

  List<ToolItem> _toolboxItems(AppLocalizations l10n) => [
    ToolItem(
      name: l10n.homeToolAiStudy,
      icon: Icons.auto_awesome_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF4285F4),
      // Google Blue
      widget: const AIStudyPlanScreen(),
    ),
    ToolItem(
      name: l10n.homeToolExamSchedule,
      icon: Icons.calendar_month_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFFEA4335),
      // Google Red
      widget: const ExamScheduleScreen(),
    ),
    ToolItem(
      name: l10n.homeToolPerformance,
      icon: Icons.bar_chart_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFFFF6D00),
      // Deep Orange
      widget: const PerformanceTrackerScreen(),
    ),
    ToolItem(
      name: l10n.homeToolLibrary,
      icon: Icons.local_library_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF34A853),
      // Google Green
      widget: const OfflineLibraryScreen(),
    ),
    ToolItem(
      name: l10n.homeToolNews,
      icon: Icons.newspaper_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFFFBBC05),
      // Google Yellow
      widget: const NewsFeedScreen(),
    ),
    ToolItem(
      name: l10n.homeToolMarketplace,
      icon: Icons.storefront_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF9334E6),
      // Google Purple
      widget: const MarketplaceScreen(),
    ),
    ToolItem(
      name: l10n.homeToolTaskManager,
      icon: Icons.checklist_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF24C1E0),
      // Google Cyan
      widget: const TaskManagerScreen(),
    ),
    ToolItem(
      name: l10n.homeToolFocusTimer,
      icon: Icons.timer_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF3F51B5),
      // Google Indigo
      widget: const FocusTimerScreen(),
    ),
    ToolItem(
      name: l10n.homeToolTranscripts,
      icon: Icons.description_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFFE53935),
      widget: const TranscriptScreen(),
    ),
    ToolItem(
      name: l10n.homeToolPortal,
      icon: Icons.school_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFA308BAF),
      widget: const Portalscreen(),
    ),

    ToolItem(
      name: l10n.homeToolSupportBot,
      icon: Icons.psychology_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFFEA4335),
      widget: const KnowledgeBotChatScreen(),
    ),
    ToolItem(
      name: l10n.homeToolOfflineAi,
      icon: Icons.download_for_offline_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF34A853),
      // Google Green
      widget: const GemmaChatScreen(),
    ),
  ];

  // int _notificationCount = ;

  Future<void> _loadRecentActivity() async {
    final activity = await RecentActivityService().getRecentDepartment();
    if (mounted) {
      setState(() {
        _recentActivity = activity;
      });
    }
  }

  static const int _kRatingPromptAppOpenThreshold = 5;

  Future<void> _maybeShowRatingPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('rating_prompt_shown') ?? false) return;

    final openCount = (prefs.getInt('app_open_count') ?? 0) + 1;
    await prefs.setInt('app_open_count', openCount);

    if (openCount >= _kRatingPromptAppOpenThreshold && mounted) {
      await prefs.setBool('rating_prompt_shown', true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showRatingDialog(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 90.0,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: false,
            automaticallyImplyLeading: false,
            title: const AppBarUser(),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 5),
                Consumer2<DepartmentsProvider, UserModel>(
                  builder: (context, departmentsProvider, userModel, child) {
                    return IntroWidget(
                      userProfile: _userProfile,
                      recentActivity: _recentActivity,
                      departments: departmentsProvider.departments,
                      onDepartmentDeleted: _loadRecentActivity,
                    );
                  },
                ),
                FadeInSlide(
                  child: WeeklyProgressCard(supabaseClient: _supabase),
                ),
                SectionHeader(
                  title: l10n.sectionDepartmentsFaculties,
                  trailing: TextButton(
                    onPressed: () {
                      final deptProvider = context.read<DepartmentsProvider>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider<DepartmentsProvider>.value(
                            value: deptProvider,
                            child: const AllDepartmentsScreen(),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      l10n.seeAllButton,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                Consumer2<DepartmentsProvider, UserModel>(
                  builder: (context, departmentsProvider, userModel, child) {
                    final departments = departmentsProvider.departments;

                    if (departments == null) {
                      if (departmentsProvider.hasError) {
                        return NoInternetWidget(
                          onRetry: departmentsProvider.retry,
                        );
                      }
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (departments.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(l10n.noDepartmentsAvailable),
                        ),
                      );
                    }

                    // Prioritize user's department
                    final userDeptName = _userProfile?.department
                        ?.trim()
                        .toLowerCase();

                    List<Department> resultDepartments = [];

                    // 1. Find and add user's department first with robust matching
                    Department? userDept;
                    if (userDeptName != null && userDeptName.isNotEmpty) {
                      try {
                        userDept = departments.firstWhere(
                          (d) => d.name.trim().toLowerCase() == userDeptName,
                        );
                        resultDepartments.add(userDept);
                      } catch (_) {
                        // Attempt fallback match (partial or normalized)
                        try {
                          userDept = departments.firstWhere(
                            (d) =>
                                d.name.toLowerCase().contains(userDeptName) ||
                                userDeptName.contains(d.name.toLowerCase()),
                          );
                          resultDepartments.add(userDept);
                        } catch (_) {}
                      }
                    }

                    // 2. Get other departments and shuffle them
                    final otherDepartments = departments
                        .where((d) => d != userDept)
                        .toList();
                    otherDepartments.shuffle();

                    // 3. Add some random departments
                    resultDepartments.addAll(otherDepartments.take(4));

                    return DepartmentSection(
                      departments: resultDepartments,
                      onDepartmentDeleted: _loadRecentActivity,
                    );
                  },
                ),
                SectionHeader(
                  title: l10n.sectionTools,
                  trailing: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllToolsScreen(
                          items: _toolboxItems(l10n),
                          userProfile: _userProfile,
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.seeAllButton,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                ToolboxRow(items: _toolboxItems(l10n)),
                const SizedBox(height: 20), // Padding for FAB
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          final theme = Theme.of(context);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: FloatingActionButton(
                  heroTag: "chatFAB",
                  tooltip: l10n.globalChatTooltip,
                  backgroundColor: theme.colorScheme.secondary,
                  onPressed: () {
                    messageProvider.setChatOpen(true);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    ).then((_) {
                      messageProvider.setChatOpen(false);
                    });
                  },
                  child: Icon(
                    Icons.chat_rounded,
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
              if (messageProvider.unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      messageProvider.unreadCount > 99
                          ? '99+'
                          : messageProvider.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ToolboxSection extends StatelessWidget {
  const ToolboxSection({super.key, required this.items, this.userProfile});

  final List<ToolItem> items;
  final UserProfile? userProfile;

  @override
  Widget build(BuildContext context) {
    // More columns than before so each cell is smaller, and childAspectRatio
    // (not a fixed mainAxisExtent) so cell height scales with the cell's
    // own computed width — i.e. with actual screen width — instead of
    // every phone in a bucket getting the same fixed-height cell.
    final crossAxisCount = context.isMobile ? 4 : (context.isTablet ? 5 : 7);
    final childAspectRatio = context.isMobile
        ? 0.92
        : (context.isTablet ? 0.95 : 1.0);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final tool = items[index];
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return FadeInSlide(
          delay: index * 0.05,
          child: ScaleButton(
            onTap: () {
              if (tool.comingSoon) {
                _showComingSoonDialog(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => tool.widget),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isDark
                    ? theme.colorScheme.surfaceContainerLow
                    : Colors.white,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.15),
                ),
              ),
              child: Stack(
                children: [
                  if (tool.comingSoon)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            color: Colors.white.withOpacity(isDark ? 0.05 : 0.14),
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: tool.brandColor.withOpacity(
                              isDark ? 0.15 : 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            tool.icon,
                            size: 20,
                            color: tool.brandColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text(
                            tool.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tool.comingSoon
                                  ? (isDark ? Colors.white54 : Colors.black45)
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tool.comingSoon)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.lock_clock_rounded,
                        size: 12,
                        color: Colors.grey.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showComingSoonDialog(BuildContext context) => showToolComingSoonDialog(context);
}

void showToolComingSoonDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : Colors.white,
      title: Text(
        "Feature in development",
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: Text(
        "UB Support is being developed and will be available soon.",
        style: GoogleFonts.outfit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "OK",
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// Compact horizontal row of tool tiles, shown on the home screen instead
/// of the full [ToolboxSection] grid — a single scrollable row instead of
/// several rows of static grid, so the Tools section takes up much less
/// vertical space. The full grid lives on [AllToolsScreen], reachable via
/// the "See all" link next to the section header.
class ToolboxRow extends StatelessWidget {
  const ToolboxRow({super.key, required this.items});

  final List<ToolItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final tool = items[index];
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FadeInSlide(
              delay: index * 0.03,
              child: ScaleButton(
                onTap: () {
                  if (tool.comingSoon) {
                    showToolComingSoonDialog(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => tool.widget),
                    );
                  }
                },
                child: SizedBox(
                  width: 76,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.colorScheme.surfaceContainerLow
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.withOpacity(0.15),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: tool.brandColor.withOpacity(isDark ? 0.15 : 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(tool.icon, size: 18, color: tool.brandColor),
                              ),
                            ),
                          ),
                          if (tool.comingSoon)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Icon(
                                Icons.lock_clock_rounded,
                                size: 14,
                                color: Colors.grey.withOpacity(0.8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tool.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: tool.comingSoon
                              ? (isDark ? Colors.white54 : Colors.black45)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dedicated screen showing every tool, as the full grid — reached via the
/// "See all" link next to the Tools section header on the home screen.
class AllToolsScreen extends StatelessWidget {
  const AllToolsScreen({super.key, required this.items, this.userProfile});

  final List<ToolItem> items;
  final UserProfile? userProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.allToolsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ToolboxSection(items: items, userProfile: userProfile),
      ),
    );
  }
}

class DepartmentSection extends StatelessWidget {
  const DepartmentSection({
    super.key,
    required this.departments,
    this.onDepartmentDeleted,
  });

  final List<Department> departments;
  final VoidCallback? onDepartmentDeleted;

  @override
  Widget build(BuildContext context) {
    // Proportional to actual screen width (not just a mobile/tablet flag),
    // so a small phone gets a noticeably smaller card than a large one
    // instead of the same fixed size — with a per-bucket clamp so tablet
    // and desktop don't scale the card up indefinitely.
    final cardWidth = context.isMobile
        ? context.widthPct(58).clamp(160.0, 220.0)
        : context.isTablet
        ? context.widthPct(32).clamp(220.0, 260.0)
        : 260.0;
    // Image (16:10) plus the title/action text block below it.
    final cardHeight = cardWidth / 1.6 + 100;

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final department = departments[index];
          final uiData = DepartmentUIData.fromDepartmentName(department.name);
          return FadeInSlide(
            delay: index * 0.1,
            child: Container(
              width: cardWidth,
              margin: const EdgeInsets.only(right: 12),
              child: ScaleButton(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DepartmentScreen(
                        departmentName: department.name,
                        departmentId: department.id,
                      ),
                    ),
                  );
                  if (result == true) {
                    onDepartmentDeleted?.call();
                  }
                },
                child: ContentMediaCard(
                  title: department.name,
                  subtitle: department.description,
                  actionLabel: AppLocalizations.of(context)!.exploreResources,
                  imageUrl: department.imageUrl,
                  icon: uiData.icon,
                  primaryColor: uiData.primaryColor,
                  secondaryColor: uiData.secondaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class IntroWidget extends StatefulWidget {
  final UserProfile? userProfile;
  final RecentActivity? recentActivity;
  final List<Department>? departments;
  final VoidCallback? onDepartmentDeleted;

  const IntroWidget({
    super.key,
    this.userProfile,
    this.recentActivity,
    this.departments,
    this.onDepartmentDeleted,
  });

  @override
  State<IntroWidget> createState() => _IntroWidgetState();
}

class _IntroWidgetState extends State<IntroWidget> {
  late Quote _quote;

  @override
  void initState() {
    super.initState();
    _quote = QuoteService.getRandomQuote();
  }

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final trialActive = widget.userProfile?.isTrialActive ?? false;
    final trialTime = widget.userProfile?.trialTimeLeft(l10n) ?? "";
    final firstName = widget.userProfile?.name?.split(' ').first ?? l10n.scholarFallbackName;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerLow
                : theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_getGreeting(l10n)}, $firstName",
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "“${_quote.text}”",
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          TextSpan(
                            text: " — ${_quote.author}",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w500,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trialActive) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: isDark
                                  ? Colors.white70
                                  : theme.colorScheme.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.homeTrialLabel(trialTime),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white70
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.school_rounded,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ],
          ),
        ),
        Builder(
          builder: (context) {
            Department? matchedDepartment;
            bool showRecentActivity = false;
            if (widget.recentActivity != null) {
              if (widget.departments == null) {
                showRecentActivity = true;
              } else {
                matchedDepartment = widget.departments!
                    .where((d) => d.id == widget.recentActivity!.id)
                    .firstOrNull;
                showRecentActivity = matchedDepartment != null;
              }
            }

            if (!showRecentActivity) return const SizedBox.shrink();

            return Column(
              children: [
                const SizedBox(height: 16),
                FadeInSlide(
                  duration: const Duration(milliseconds: 500),
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DepartmentScreen(
                            departmentName: widget.recentActivity!.name,
                            departmentId: widget.recentActivity!.id,
                          ),
                        ),
                      );
                      if (result == true) {
                        widget.onDepartmentDeleted?.call();
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  theme.colorScheme.surfaceContainerLow,
                                  theme.colorScheme.surfaceContainerLow
                                      .withOpacity(0.8),
                                ]
                              : [
                                  theme.colorScheme.primary.withOpacity(0.1),
                                  theme.colorScheme.primary.withOpacity(0.05),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(
                                0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.resumeLearningLabel,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  widget.recentActivity!.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class AppBarUser extends StatelessWidget {
  const AppBarUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Consumer<UserModel>(
          builder: (context, value, child) {
            final avatarUrl = value.avatarUrl;
            return Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Icon(
                        Icons.person_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 35,
                      )
                    : null,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<UserModel>(
                builder: (context, value, child) => Text(
                  value.name != null && value.name!.isNotEmpty
                      ? value.name!.toUpperCase()
                      : AppLocalizations.of(context)!.studentFallbackName,
                  style: GoogleFonts.podkova(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Consumer<UserModel>(
                builder: (context, value, child) => Text(
                  value.institutionName ?? AppLocalizations.of(context)!.unifiedAcademicPortal,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Consumer<UserModel>(
          builder: (context, user, child) => GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SubscriptionPlansScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${user.aiCredits}",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Stack(
          children: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Notifications()),
              ),
              icon: const Icon(Icons.notifications_outlined),
            ),
            StreamBuilder<int>(
              stream: NotificationService().unreadCountStream,
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                if (unreadCount == 0) return const SizedBox.shrink();

                return Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class NoInternetWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerLow
              : theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : theme.colorScheme.primary.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noConnectionTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noConnectionBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 140, // Fixed width for smaller button
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.retryButton),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
