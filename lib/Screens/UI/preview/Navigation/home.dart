// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/ComputerCourses/add_department_dialog.dart'
    show showAddDepartmentDialog;
import 'package:neo/Screens/UI/preview/Settings/notifications.dart';
import 'package:neo/Screens/UI/preview/detailScreens/all_departments_screen.dart';

import 'package:neo/services/department.dart';
import 'package:neo/Screens/UI/preview/Toolbox/gpa_calculator_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/task_manager_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/focus_timer_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/document_scanner_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/flashcards_screen.dart';
import 'package:neo/Screens/UI/preview/Toolbox/exam_schedule_screen.dart';

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
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardHeader(),
              const SizedBox(height: 20),

              // Main Action Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildDashboardCard(
                      context,
                      title: "Academic Structure",
                      icon: Icons.account_balance_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AllDepartmentsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: "Course Registration",
                      icon: Icons.app_registration_rounded,
                      onTap: () {
                        // TODO: Link to Course Registration
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: "Form B",
                      icon: Icons.description_outlined,
                      onTap: () {
                        // TODO: Link to Form B
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: "Pay Fees",
                      icon: Icons.payments_outlined,
                      onTap: () {
                        // TODO: Link to Pay Fees
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: "CA Results",
                      icon: Icons.assignment_outlined,
                      onTap: () {
                        // TODO: Link to CA Results
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: "Final Results",
                      icon: Icons.grade_outlined,
                      onTap: () {
                        // TODO: Link to Final Results
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const ViewSection(title: "Student Toolbox"),
              ToolboxSection(items: toolboxItems),
              const SizedBox(height: 100), // Bottom padding for FAB/Nav
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Quick Action",
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => showAddDepartmentDialog(context),
        child: Icon(
          Icons.add_rounded,
          color: theme.colorScheme.onPrimary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF1E88E5)),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1E88E5), // Primary Blue
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Go-Student",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      "University of Buea",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Notifications()),
                  ); // Keep notifications
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Consumer<UserModel>(
            builder: (context, user, _) {
              return Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: const AssetImage(
                      'assets/images/student_profile.png',
                    ), // Placeholder or network image if avail
                    child: user.name == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name?.toUpperCase() ?? "STUDENT NAME",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "SC23A569 • B.Sc Computer Science", // Placeholder or fetch from user model if available
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          "2025/2026 • First Semester",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true, // Important for nesting in SingleChildScrollView
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final tool = items[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => tool.widget),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), // Light slate bg
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tool.icon,
                      size: 24,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tool.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
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
}

class ViewSection extends StatelessWidget {
  const ViewSection({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }
}

// Keeping DepartmentSection if needed for other screens, but removing it from Home body as requested by "Redesign Main Navigation & Dashboard" to match reference.
// The reference doesn't show the horizontal list.
// I'll keep the class definition in case it is used elsewhere or required later, but the Home body doesn't use it anymore.

class DepartmentSection extends StatelessWidget {
  const DepartmentSection({super.key, required this.departments});
  final List<Department> departments;
  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder or original implementation if needed
  }
}
