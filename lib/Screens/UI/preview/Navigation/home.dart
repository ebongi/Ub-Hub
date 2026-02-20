// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:neo/Screens/Shared/animations.dart';
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/ComputerCourses/add_department_dialog.dart'
    show showAddDepartmentDialog;
import 'package:neo/Screens/UI/preview/Settings/notifications.dart';

import 'package:neo/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:neo/services/department.dart';
import 'package:neo/Screens/UI/preview/Toolbox/task_manager_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/focus_timer_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/exam_schedule_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/ai_study_plan_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/marketplace_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/news_feed_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/offline_library_screen.dart';
import 'package:neo/Screens/UI/preview/Navigation/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/profile.dart';
import 'package:neo/services/message_provider.dart';
import 'package:provider/provider.dart';

class ToolItem {
  final String name;
  final IconData icon;
  final Color backgroundColor;
  final Widget widget;

  ToolItem({
    required this.name,
    required this.icon,
    required this.backgroundColor,
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

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient ?? Supabase.instance.client;

    final db = DatabaseService(uid: _supabase.auth.currentUser?.id);
    db.userProfile.listen((profile) {
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    });
  }

  Stream<List<Department>> getDepartmentStream() {
    return _supabase
        .from('departments')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((e) => Department.fromSupabase(e)).toList());
  }

  final List<ToolItem> toolboxItems = [
    ToolItem(
      name: "AI Study",
      icon: Icons.auto_awesome_rounded,
      backgroundColor: Colors.transparent,
      widget: const AIStudyPlanScreen(),
    ),
    ToolItem(
      name: "Exam Schedule",
      icon: Icons.calendar_month_rounded,
      backgroundColor: Colors.transparent,
      widget: const ExamScheduleScreen(),
    ),
    ToolItem(
      name: "Library",
      icon: Icons.local_library_rounded,
      backgroundColor: Colors.transparent,
      widget: const OfflineLibraryScreen(),
    ),
    ToolItem(
      name: "News",
      icon: Icons.newspaper_rounded,
      backgroundColor: Colors.transparent,
      widget: const NewsFeedScreen(),
    ),
    ToolItem(
      name: "Marketplace",
      icon: Icons.storefront_rounded,
      backgroundColor: Colors.transparent,
      widget: const MarketplaceScreen(),
    ),
    ToolItem(
      name: "Task Manager",
      icon: Icons.checklist_rounded,
      backgroundColor: Colors.transparent,
      widget: const TaskManagerScreen(),
    ),
    ToolItem(
      name: "Focus Timer",
      icon: Icons.timer_rounded,
      backgroundColor: Colors.transparent,
      widget: const FocusTimerScreen(),
    ),
  ];
  // int _notificationCount = ;

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
                const IntroWidget(),
                const ViewSection(title: "Departments"),
                Consumer<List<Department>?>(
                  builder: (context, departments, child) {
                    if (departments == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (departments.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No departments available yet."),
                        ),
                      );
                    }
                    final allowedNames = [
                      "physics",
                      "mathematics",
                      "computer science",
                    ];
                    final filteredDepartments = departments
                        .where(
                          (d) => allowedNames.contains(
                            d.name.trim().toLowerCase(),
                          ),
                        )
                        .toList();
                    return DepartmentSection(departments: filteredDepartments);
                  },
                ),
                const ViewSection(title: "Toolbox"),
                ToolboxSection(items: toolboxItems),
                const SizedBox(height: 25), // Padding for FAB
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Consumer<MessageProvider>(
            builder: (context, messageProvider, child) {
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
          const SizedBox(height: 10),
          if (_userProfile?.canUpload ?? false)
            FloatingActionButton(
              heroTag: "addDeptFAB",
              tooltip: "Add Department",
              backgroundColor: theme.colorScheme.primary,
              onPressed: () => showAddDepartmentDialog(context),
              child: Icon(
                Icons.add,
                color: theme.colorScheme.onPrimary,
                size: 30,
              ),
            ),
        ],
      ),
    );
  }
}

class ToolboxSection extends StatelessWidget {
  const ToolboxSection({super.key, required this.items});

  final List<ToolItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisExtent: 110, // Compact height
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final tool = items[index];
        final theme = Theme.of(context);
        return FadeInSlide(
          delay: index * 0.05,
          child: ScaleButton(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => tool.widget),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.cardTheme.color,
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      tool.icon,
                      size: 28, // Smaller icon
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tool.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13, // Compact text
                      fontWeight: FontWeight.w600,
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
  const DepartmentSection({super.key, required this.departments});

  final List<Department> departments;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
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
              width: 280,
              margin: const EdgeInsets.only(right: 20),
              child: ScaleButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DepartmentScreen(
                      departmentName: department.name,
                      departmentId: department.id,
                    ),
                  ),
                ),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  shadowColor: uiData.primaryColor.withOpacity(0.2),
                  child: Stack(
                    children: [
                      // Background Image or Gradient
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
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        uiData.primaryColor,
                                        uiData.secondaryColor,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Icon(
                                    uiData.icon,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      uiData.primaryColor,
                                      uiData.secondaryColor,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(
                                  uiData.icon,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                      ),
                      // Gradient Overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.8),
                              ],
                              stops: const [0.5, 0.7, 1.0],
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                uiData.icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const Spacer(),
                            // Department Name
                            Text(
                              department.name,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Action Label
                            Row(
                              children: [
                                Text(
                                  "Explore Resources",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.7),
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

class IntroWidget extends StatelessWidget {
  const IntroWidget({super.key}); // Can be const

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What will you learn today?",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Explore courses, resources,\nWelcome to your digital library.",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.rocket_launch_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
        ],
      ),
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
        StreamBuilder<UserProfile>(
          stream: DatabaseService(
            uid: Supabase.instance.client.auth.currentUser?.id,
          ).userProfile,
          builder: (context, snapshot) {
            final avatarUrl = snapshot.data?.avatarUrl;
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
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
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
                      : 'Mate',
                  style: GoogleFonts.podkova(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "Welcome! We're glad you're here",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
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
