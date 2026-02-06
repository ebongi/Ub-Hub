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
import 'package:neo/Screens/UI/preview/Toolbox/gpa_calculator_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/task_manager_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/focus_timer_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/document_scanner_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/flashcards_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/exam_schedule_screen.dart';
import 'package:neo/Screens/UI/preview/Navigation/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient ?? Supabase.instance.client;
  }

  Stream<List<Department>> getDepartmentStream() {
    return _supabase
        .from('departments')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((e) => Department.fromSupabase(e)).toList());
  }

  final List<ToolItem> toolboxItems = [
    ToolItem(
      name: "GPA Calculator",
      icon: Icons.calculate_rounded,
      backgroundColor: Colors.transparent,
      widget: const GPACalculatorScreen(),
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
    ToolItem(
      name: "Doc Scanner",
      icon: Icons.document_scanner_rounded,
      backgroundColor: Colors.transparent,
      widget: const DocumentScannerScreen(),
    ),
    ToolItem(
      name: "Resume Builder",
      icon: Icons.description_rounded,
      backgroundColor: Colors.transparent,
      widget: const FlashcardsScreen(),
    ),
    ToolItem(
      name: "Exam Schedule",
      icon: Icons.calendar_month_rounded,
      backgroundColor: Colors.transparent,
      widget: const ExamScheduleScreen(),
    ),
  ];
  // int _notificationCount = ;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBarUser(),
                const SizedBox(height: 20), // Can be const
                IntroWidget(),
                const ViewSection(title: "Departments"),
                // DepartmentSection now consumes the stream provided above
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
              ],
            ),
          ),
        ),
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
          const SizedBox(height: 16),
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
    return SizedBox(
      height: 380,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisExtent: 150,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final tool = items[index];
          final theme = Theme.of(context);
          return FadeInSlide(
            delay: index * 0.1,
            child: ScaleButton(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => tool.widget),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: theme.cardTheme.color,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                      child: Hero(
                        tag: tool.name,
                        child: Icon(
                          tool.icon,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tool.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
}

// Helper to map department names to UI properties
class DepartmentUIData {
  final IconData icon;
  final Color color;

  DepartmentUIData({required this.icon, required this.color});

  static DepartmentUIData fromDepartmentName(String name) {
    switch (name.toLowerCase()) {
      case 'computer science':
        return DepartmentUIData(
          icon: Icons.computer_rounded,
          color: Colors.blue.shade800,
        );
      case 'mathematics':
        return DepartmentUIData(
          icon: Icons.functions_rounded,
          color: Colors.green.shade800,
        );
      case 'physics':
        return DepartmentUIData(
          icon: Icons.science_rounded,
          color: Colors.purple.shade800,
        );
      default:
        return DepartmentUIData(
          icon: Icons.account_balance_rounded,
          color: Colors.blue.shade800,
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
      height: 240,
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
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: uiData.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:
                          (department.imageUrl != null &&
                              department.imageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl: department.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  uiData.icon,
                                  size: 60,
                                  color: uiData.color.withOpacity(0.5),
                                ),
                              ),
                            )
                          : Icon(
                              uiData.icon,
                              size: 60,
                              color: uiData.color.withOpacity(0.5),
                            ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.8),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Text(
                        department.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
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
}

class IntroWidget extends StatelessWidget {
  const IntroWidget({super.key}); // Can be const

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 4.0),
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
        Container(
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
            child: Icon(
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 35,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<UserModel>(
                builder: (context, value, child) => Text(
                  "Hello, ${value.name != null && value.name!.isNotEmpty ? value.name!.toUpperCase() : 'Mate'}",
                  style: GoogleFonts.podkova(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
