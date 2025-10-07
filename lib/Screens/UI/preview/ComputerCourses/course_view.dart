import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/detailScreens/course_detail_screen.dart';
import 'package:neo/services/course_model.dart';

class CourseList extends StatefulWidget {
  const CourseList({super.key, required this.courses});
  final List<Course> courses;
  @override
  CourseListState createState() => CourseListState();
}

class CourseListState extends State<CourseList> {
  String searchQuery = '';
  List<Course> filteredCourses = [];
  @override
  void initState() {
    super.initState();
    filteredCourses = widget.courses;
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredCourses = widget.courses
          .where(
            (course) => course.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: updateSearch,
              decoration: InputDecoration(
                hintText: 'Search Courses...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: filteredCourses.length,
              itemBuilder: (context, index) {
                final course = filteredCourses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.blue),
                    title: Text(
                      course.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(course.code, style: GoogleFonts.poppins()),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(course: course),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
