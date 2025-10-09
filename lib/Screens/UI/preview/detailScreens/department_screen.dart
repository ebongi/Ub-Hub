import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/ComputerCourses/add_course_dialog.dart' show showAddCourseDialog;
import 'package:neo/Screens/UI/preview/ComputerCourses/course_view.dart';
import 'package:neo/services/course_model.dart';
import 'package:neo/services/database.dart';
 

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
      length: 2,
      animationDuration: const Duration(milliseconds: 400),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          scrolledUnderElevation: 10,
          title: Text(
            widget.departmentName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.poppins( // Consider moving this to your theme data
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 16),
            indicatorAnimation: TabIndicatorAnimation.elastic,
            indicatorColor: Colors.blue,
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: false,
            tabs: const [
              Tab(text: "About"),
              Tab(text: "Courses"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const Center(child: Text("Department Details goes here")),
            StreamBuilder<List<Course>>(
              stream: _dbService.getCoursesForDepartment(widget.departmentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "No course Found!",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _addCourse,
                          label: const Text(
                            "Add Course",
                            // style: GoogleFonts.poppins().copyWith(
                            //   fontWeight: FontWeight.bold,
                            //   color: Colors.blue,
                            // ),
                          ),
                          icon: const Icon(Icons.add, color: Colors.blue),
                        ),
                      ],
                    ),
                  );
                }

                final courses = snapshot.data!;
                return CourseList(courses: courses, addcourse: _addCourse);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addCourse() {
    showAddCourseDialog(context, widget.departmentId);
  }
}
