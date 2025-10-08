import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/ComputerCourses/course_view.dart';
import 'package:neo/Screens/UI/preview/detailScreens/questions.dart';
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
  void _addCourse() {
    final dbService = DatabaseService();
    final courseNameController = TextEditingController();
    final courseCodeController = TextEditingController();
    final addCourseKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Course", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Form(
            key: addCourseKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: courseNameController,
                  decoration: const InputDecoration(labelText: "Course Name"),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a course name' : null,
                ),
                TextFormField(
                  controller: courseCodeController,
                  decoration: const InputDecoration(labelText: "Course Code"),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a course code' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (addCourseKey.currentState!.validate()) {
                  final newCourse = Course(
                     
                    name: courseNameController.text,
                    code: courseCodeController.text,
                    departmentId: widget.departmentId,
                  );
                  try {
                    await dbService.createCourse(newCourse);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Course "${newCourse.name}" added!')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.pop(context); // It's generally safe to pop, but good practice to check.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add course: $e')),
                    );
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      animationDuration: const Duration(milliseconds: 400),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop(),),
          scrolledUnderElevation: 10,
          title: Text(
            widget.departmentName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 16),
            indicatorAnimation: TabIndicatorAnimation.elastic,
            indicatorColor: Colors.blue,
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: false,
            tabs: const [
              Tab(text: "Courses"),
              Tab(text: "Tutorials"),
              Tab(text: "Questions"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<List<Course>>(
              stream: DatabaseService().getCoursesForDepartment(widget.departmentId),
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
                          Text("No course Found!",style: GoogleFonts.poppins().copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red
                          ),),
                        const SizedBox(height: 10,),
                        ElevatedButton.icon(
                           
                          onPressed: _addCourse,
                          label:   Text("Add Course",style: GoogleFonts.poppins().copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue
                          ),),
                          icon: Icon(Icons.add,color: Colors.blue,),
                        ),
                      ],
                    ),
                  );
                }

                final courses = snapshot.data!;
                return CourseList(courses: courses);
              },
            ),
            const Center(child: Text("Tab 2")),
            const Questions(),
          ],
        ),
      ),
    );
  }
}
