// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/ComputerCourses/add_department_dialog.dart' show showAddDepartmentDialog;
// import 'package:neo/Screens/UI/dialogs/add_department_dialog.dart';
import 'package:neo/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neo/services/department.dart';
import 'package:neo/Screens/UI/preview/Requirements/requirement_detail_screen.dart';

import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Requirement> requirements = [
    Requirement(name: "English", imageUrl: "assets/images/language.png"),
    Requirement(name: "French", imageUrl: "assets/images/Learning-bro.png"),
    Requirement(name: "Law", imageUrl: "assets/images/law.png"),
    Requirement(name: "CVE", imageUrl: "assets/images/cve.png"),
    Requirement(name: "CST", imageUrl: "assets/images/cst.png"),
    Requirement(name: "Sports", imageUrl: "assets/images/sports.png"),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final user = Provider.of<User?>(context);

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
                    final recentDepartments = departments.take(3).toList();
                    return DepartmentSection(departments: recentDepartments);
                  },
                ),
                const ViewSection(title: "Requirements"),
                RequirementSection(requirements: requirements),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Department",
        backgroundColor: Colors.blue,
        onPressed: () => showAddDepartmentDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class Requirement {
  final String name;
  final String imageUrl;
  final Widget? widget;

  Requirement({required this.name, required this.imageUrl, this.widget});
}

class RequirementSection extends StatelessWidget {
  const RequirementSection({super.key, required this.requirements});

  final List<Requirement> requirements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 380,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 7,
          mainAxisExtent: 180,
          mainAxisSpacing: 7,
        ),
        itemCount: requirements.length,
        itemBuilder: (context, index) {
          final requirement = requirements[index];
          return Container(
            // padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15), 
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],

              // border: Border.all(),
            ),
            child: GestureDetector(
              ///Implement code to navigate to the requirement scren
              onTap: () => Navigator.push( 
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      requirement.widget ??
                      RequirementDetailScreen(
                        title: requirement.name,
                        imageUrl: requirement.imageUrl,
                      ),
                ),
              ),
              child: Column(
                children: [ 
                  Hero(
                    tag: requirement.name,
                    child: Image.asset(requirement.imageUrl),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      requirement.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
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
}

// Helper to map department names to UI properties
class DepartmentUIData {
  final String imageUrl;
  final Color color;

  DepartmentUIData({required this.imageUrl, required this.color});

  static DepartmentUIData fromDepartmentName(String name) {
    switch (name.toLowerCase()) {
      case 'computer science':
        return DepartmentUIData(
          imageUrl: 'assets/images/code.png',
          color: Colors.blue.shade800,
        );
      // Add other departments here
      default:
        return DepartmentUIData(
          imageUrl: 'assets/images/departmentdefault.jpg',
          color: Colors.grey.shade800,
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
          return GestureDetector(
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
                    decoration: BoxDecoration(
                      // Use NetworkImage if imageUrl is present
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image:
                            (department.imageUrl != null &&
                                department.imageUrl!.isNotEmpty)
                            ? NetworkImage(department.imageUrl!)
                            : AssetImage(uiData.imageUrl) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.7),
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
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
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
}

class IntroWidget extends StatelessWidget {
  const IntroWidget({super.key}); // Can be const

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What will you learn today?",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                  Text(
                  "Explore courses, resources, and collaborate with peers.", // This can be const
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
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
        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AppBarUser extends StatelessWidget {
  const AppBarUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<UserModel>(
                  builder: (context, value, child) =>   Text(
                    "Hello, ${value.name!.isNotEmpty ? value.name!.toUpperCase() : 'Mate'}",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                  Text(
                  "What do you want to study today?",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: Colors.blue,
            size: 32,
          ),
        ),
      ],
    );
  }
}
