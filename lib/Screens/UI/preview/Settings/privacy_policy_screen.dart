import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy Policy", style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last Updated: March 2026",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              "1. Data We Collect",
              "GO-Study collects information you provide directly, such as your user profile details, academic department, course selections, and study materials you upload. We also store your chat history and exam schedules to provide cloud-sync functionality.",
            ),
            _buildSection(
              "2. How We Use Your Data",
              "Your information is used to personalize your academic experience, synchronize your data across devices via Supabase, and enable collaborative features like the global student chat. We do not use your data for advertising purposes.",
            ),
            _buildSection(
              "3. Data Storage & Security",
              "We use Supabase for secure cloud storage. Your data is protected using industry-standard Row Level Security (RLS), ensuring that only authorized users can access specific pieces of information.",
            ),
            _buildSection(
              "4. Third-Party Services",
              "We utilize trusted third-party services such as Google Generative AI for our study assistant. While these services process data to generate responses, they operate under strict privacy guidelines to protect your information.",
            ),
            _buildSection(
              "5. Data Retention",
              "You remain in control of your data. You can delete your chat sessions, materials, and account at any time. We retain data only as long as your account is active or needed to provide you with the app's services.",
            ),
            _buildSection(
              "6. Changes to This Policy",
              "We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the 'Last Updated' date.",
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                "Your privacy is our priority.",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
