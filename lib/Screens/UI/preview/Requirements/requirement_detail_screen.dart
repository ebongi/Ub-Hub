import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RequirementDetailScreen extends StatelessWidget {
  const RequirementDetailScreen({
    super.key,
    required this.title,
    required this.imageUrl,
  });

  final String title;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: title,
              child: Image.asset(
                imageUrl,
                height: 280,
                width: MediaQuery.sizeOf(context).width,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'General University Requirement',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const Divider(height: 32),
                  _buildDetailSection(
                    context,
                    icon: Icons.info_outline,
                    title: 'About this Requirement',
                    content:
                        'Information about this university requirement will be available here soon.',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailSection(
                    context,
                    icon: Icons.book_outlined,
                    title: 'Resources',
                    content:
                        'Related materials and resources for this requirement will be listed here.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context,
      {required IconData icon, required String title, required String content})
  {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text(content, style: GoogleFonts.poppins()),
      ),
    );
  }
}