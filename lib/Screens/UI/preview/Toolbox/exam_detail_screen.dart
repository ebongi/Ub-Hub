import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/exam_event.dart';
import 'package:neo/Screens/UI/preview/Toolbox/create_exam_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExamDetailScreen extends StatelessWidget {
  final ExamEvent exam;
  const ExamDetailScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final startStr = DateFormat('dd-MMM-yyyy HH:mm:ss').format(exam.startTime);
    final endStr = DateFormat('dd-MMM-yyyy HH:mm:ss').format(exam.endTime);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Events Calendar",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateExamScreen(exam: exam)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem("Event ID", exam.id.substring(0, 8).toUpperCase()),
            _buildDetailItem("Event Name", exam.name),
            _buildDetailItem("Event Category", exam.category),
            _buildDetailItem(
              "Description",
              exam.description ?? "No description provided.",
            ),
            _buildDetailItem("Venue", exam.venue ?? "TBD"),
            _buildDetailItem("Event Start Time", startStr),
            _buildDetailItem("Event End Time", endStr),
            _buildDetailItem(
              "Event Status",
              exam.status.toUpperCase(),
              color: Colors.green,
            ),

            if (exam.imageUrl != null) ...[
              const SizedBox(height: 24),
              Text(
                "Event Image",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: exam.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ],

            const SizedBox(height: 40),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  "Add Comment",
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Event",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete this event?",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                await DatabaseService(uid: user.id).deleteExam(exam.id);
                if (context.mounted) {
                  Navigator.pop(context); // Pop dialog
                  Navigator.pop(context); // Pop detail screen
                }
              }
            },
            child: Text("Delete", style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
