import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/ComputerCourses/computersciencecourses.dart';
import 'package:neo/Screens/UI/preview/detailScreens/questions.dart';
import 'package:neo/services/course_model.dart';
import 'package:neo/services/database.dart';

class DepartmentScreen extends StatelessWidget {
  final String departmentName;
  final String departmentId;

  const DepartmentScreen({
    super.key,
    required this.departmentName,
    required this.departmentId,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      animationDuration: const Duration(milliseconds: 400),
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 10,
          title: Text(
            departmentName,
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
              stream: DatabaseService().getCoursesForDepartment(departmentId),
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
                           
                          onPressed: () {},
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
