// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/Screens/UI/preview/Navigation/chat_screen.dart';
import 'package:go_study/Screens/UI/preview/Navigation/portalScreen.dart';
import 'package:go_study/Screens/UI/preview/Settings/notifications.dart';
import 'package:go_study/Screens/UI/preview/Settings/subscription_plans_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/TranscriptScreen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/ai_study_plan_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/exam_schedule_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/focus_timer_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/marketplace_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/news_feed_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/offline_library_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/task_manager_screen.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:go_study/services/message_provider.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/services/quote_service.dart';
import 'package:go_study/services/recent_activity_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/core/responsive.dart';

class ToolItem {
  final String name;
  final IconData icon;
  final Color backgroundColor;
  final Color brandColor;
  final Widget widget;

  ToolItem({
    required this.name,
    required this.icon,
    required this.backgroundColor,
    required this.brandColor,
    required this.widget,
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

    _loadRecentActivity();

    final db = DatabaseService(uid: _supabase.auth.currentUser?.id);
    db.userProfile.listen((profile) async {
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });

        // Fetch institution name if available
        String? institutionName;
        if (profile.institutionId != null) {
          final inst = await db.getInstitution(profile.institutionId!);
          institutionName = inst?.name;
        }

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

  final List<ToolItem> toolboxItems = [
    ToolItem(
      name: "AI Study",
      icon: Icons.auto_awesome_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF4285F4),
      // Google Blue
      widget: const AIStudyPlanScreen(),
    ),
    ToolItem(
      name: "Exam Schedule",
      icon: Icons.calendar_month_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFFEA4335),
      // Google Red
      widget: const ExamScheduleScreen(),
    ),
    ToolItem(
      name: "Library",
      icon: Icons.local_library_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF34A853),
      // Google Green
      widget: const OfflineLibraryScreen(),
    ),
    ToolItem(
      name: "News",
      icon: Icons.newspaper_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFFFBBC05),
      // Google Yellow
      widget: const NewsFeedScreen(),
    ),
    ToolItem(
      name: "Marketplace",
      icon: Icons.storefront_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF9334E6),
      // Google Purple
      widget: const MarketplaceScreen(),
    ),
    ToolItem(
      name: "Task Manager",
      icon: Icons.checklist_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF24C1E0),
      // Google Cyan
      widget: const TaskManagerScreen(),
    ),
    ToolItem(
      name: "Focus Timer",
      icon: Icons.timer_rounded,
      backgroundColor: Colors.transparent,
      brandColor: const Color(0xFF3F51B5),
      // Google Indigo
      widget: const FocusTimerScreen(),
    ),
    ToolItem(
      name: "Transcripts",
      icon: Icons.description_rounded,
      backgroundColor:   Colors.transparent,
      brandColor:  const Color(0xFFE53935),
      widget:  const Transcriptscreen(),
    ),
    ToolItem(
      name:"PORTAL",
      icon: Icons.school_rounded,
      backgroundColor:  Colors.transparent,
      brandColor: const Color(0xFA308BAF),
      widget: const Portalscreen(),
    )
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Consumer<List<Department>?>(
                  builder: (context, departments, child) {
                    return IntroWidget(
                      userProfile: _userProfile,
                      recentActivity: _recentActivity,
                      departments: departments,
                      onDepartmentDeleted: _loadRecentActivity,
                    );
                  },
                ),
                const ViewSection(title: "Departments & Faculties"),
                Consumer<List<Department>?>(
                  builder: (context, departments, child) {
                    if (departments == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (departments.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("No departments available yet."),
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
                const ViewSection(title: "Other Services"),
                ToolboxSection(
                  items: toolboxItems.where((item) {
                    if (item.name == "Marketplace") {
                      return _userProfile?.role == UserRole.contributor ||
                          _userProfile?.role == UserRole.admin;
                    }
                    return true;
                  }).toList(),
                  userProfile: _userProfile,
                ),
                const SizedBox(height: 25), // Padding for FAB
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
                  tooltip: "Global Chat",
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
    final crossAxisCount = context.isMobile ? 3 : (context.isTablet ? 4 : 6);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisExtent: context.isMobile ? 110 : 130, // Proportional height
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final tool = items[index];
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final isRestricted =
            (tool.name == "AI Study" || tool.name == "Library") &&
            userProfile?.role == UserRole.viewer &&
            !(userProfile?.isTrialActive ?? false);

        return FadeInSlide(
          delay: index * 0.05,
          child: ScaleButton(
            onTap: () {
              if (isRestricted) {
                _showUpgradePrompt(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => tool.widget),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
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
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tool.brandColor.withOpacity(
                              isDark ? 0.15 : 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            tool.icon,
                            size: 28,
                            color: tool.brandColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            tool.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isRestricted)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: Colors.grey.withOpacity(0.6),
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

  void _showUpgradePrompt(BuildContext context) {
    showPremiumGeneralDialog(
      context: context,
      barrierLabel: "Premium",
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PremiumDialogHeader(
              title: "Premium Feature",
              subtitle: "Expand your academic horizons",
              icon: Icons.stars_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Text(
                    "The AI Study Plan is a premium feature. Upgrade to Silver or Gold to unlock it!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Later",
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
                          label: "Upgrade Now",
                          isLoading: false,
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubscriptionPlansScreen(
                                  userProfile: userProfile!,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper to map department names to UI properties
// Helper to map department names to UI properties
class DepartmentUIData {
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  DepartmentUIData({
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });

  static DepartmentUIData fromDepartmentName(String name) {
    switch (name.toLowerCase().trim()) {
      case 'computer science':
        return DepartmentUIData(
          icon: Icons.computer_rounded,
          primaryColor: const Color(0xFF2563EB), // Blue 600
          secondaryColor: const Color(0xFF60A5FA), // Blue 400
        );
      case 'mathematics':
        return DepartmentUIData(
          icon: Icons.functions_rounded,
          primaryColor: const Color(0xFF059669), // Emerald 600
          secondaryColor: const Color(0xFF34D399), // Emerald 400
        );
      case 'physics':
        return DepartmentUIData(
          icon: Icons.science_rounded,
          primaryColor: const Color(0xFF7C3AED), // Violet 600
          secondaryColor: const Color(0xFFA78BFA), // Violet 400
        );
      default:
        return DepartmentUIData(
          icon: Icons.account_balance_rounded,
          primaryColor: const Color(0xFF475569), // Slate 600
          secondaryColor: const Color(0xFF94A3B8), // Slate 400
        );
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardWidth = context.isMobile ? 280.0 : 320.0;

    return Container(
      height: context.isMobile ? 240 : 280,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
              margin: const EdgeInsets.only(right: 16),
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
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
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
                      // Background Image or subtle placeholder
                      Positioned.fill(
                        child:
                            (department.imageUrl != null &&
                                department.imageUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: department.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: uiData.primaryColor.withOpacity(0.1),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: uiData.primaryColor.withOpacity(0.05),
                                ),
                              )
                            : Container(
                                color: uiData.primaryColor.withOpacity(0.05),
                              ),
                      ),
                      // Gradient Overlay for text readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.05),
                                Colors.black.withOpacity(0.6),
                              ],
                              stops: const [0.4, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon Badge
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/department.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                width: 24,
                                height: 24,
                              ),
                            ),
                            const Spacer(),
                            // Department Name
                            Text(
                              department.name,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Action Label
                            Row(
                              children: [
                                Text(
                                  "Explore Resources",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ],
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trialActive = widget.userProfile?.isTrialActive ?? false;
    final trialTime = widget.userProfile?.trialTimeLeft ?? "";
    final firstName = widget.userProfile?.name?.split(' ').first ?? "Scholar";

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
                      "${_getGreeting()}, $firstName",
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
                              "Trial: $trialTime",
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
            bool showRecentActivity = false;
            if (widget.recentActivity != null) {
              if (widget.departments == null) {
                showRecentActivity = true;
              } else {
                showRecentActivity = widget.departments!.any(
                  (d) => d.id == widget.recentActivity!.id,
                );
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
                                  "Resume Learning",
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

class ViewSection extends StatelessWidget {
  const ViewSection({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
      ),
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
                      : 'Student',
                  style: GoogleFonts.podkova(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Consumer<UserModel>(
                builder: (context, value, child) => Text(
                  value.institutionName ?? "Unified Academic Portal",
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
        Stack(
          children: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Notifications()),
              ),
              icon: const Icon(Icons.notifications_outlined),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
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
              "No Connection",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your internet and try again.",
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
                    const Text("Retry"),
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
