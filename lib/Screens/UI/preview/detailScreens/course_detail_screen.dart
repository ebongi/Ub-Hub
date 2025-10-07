import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/services/course_model.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   title: Text(course.code, style: GoogleFonts.poppins()),
        // ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Course ID: ${course.id}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              const Divider(height: 32),
              _buildDetailSection(
                context,
                icon: Icons.info_outline,
                title: 'About this course',
                content: 'Details about this course will be available here soon.',
              ),
              const SizedBox(height: 16),
              _buildDetailSection(
                context,
                icon: Icons.book_outlined,
                title: 'Ebooks & Resources',
                content: 'Related ebooks and resources will be listed here.',
              ),
            ],
          ),
        ),
         
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context,
      {required IconData icon, required String title, required String content})
  {
    return Card(
      child: ListTile(
        onTap: () {
          
        },
        leading: Icon(icon, color: Colors.blue),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text(content, style: GoogleFonts.poppins()),
      ),
    );
  }
}