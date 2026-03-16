import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Terms of Service", style: GoogleFonts.outfit()),
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
              "1. Introduction",
              "Welcome to GO-Study. By using our application, you agree to these terms. Please read them carefully. GO-Study is an academic companion designed specifically for University of Buea students to manage courses, materials, and study resources.",
            ),
            _buildSection(
              "2. Application Information",
              "GO-Study (v1.0.0+1) is developed to enhance student productivity. The app provides access to department-specific materials, AI-powered study assistance, and collaborative features like global chat.",
            ),
            _buildSection(
              "3. Third-Party Packages & Licenses",
              "GO-Study relies on several open-source packages to provide a rich experience. These include:\n"
                  "• Supabase (Database & Auth)\n"
                  "• Google Generative AI (Gemini)\n"
                  "• Syncfusion PDF Viewer\n"
                  "• Google Fonts & Iconsax\n"
                  "• Flutter Local Notifications\n"
                  "• Google ML Kit Text Recognition\n"
                  "• and others as listed in our software registry.",
            ),
            _buildSection(
              "4. User Responsibility",
              "Users are responsible for maintaining the confidentiality of their accounts. Any misuse of the academic materials provided, or violation of university integrity policies through the app's features, is strictly prohibited.",
            ),
            _buildSection(
              "5. Intellectual Property",
              "All uploaded materials remain the property of their respective owners. GO-Study serves as a platform for sharing and accessing these resources for educational purposes only.",
            ),
            _buildSection(
              "6. Limitation of Liability",
              "GO-Study is provided 'as is'. We do not guarantee the accuracy of AI-generated responses or the constant availability of all materials. We are not liable for any academic consequences resulting from the use or misuse of the app.",
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                "© 2026 Jovial Studio",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
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
