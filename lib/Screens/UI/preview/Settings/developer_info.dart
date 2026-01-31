import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // App's background color
      appBar: AppBar(
        title: Text(
          "Developer",
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Profile Image Placeholder / Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.cyanAccent, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.code_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Ebong Sume",
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                "Mobile & Software Developer",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Buea, Cameroon",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Bio Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  "BSc Computer Science student at the University of Buea with a track record of award-winning coding projects. Highly proficient in Flutter (Dart), React Native with a strong foundation in Data Structures and Algorithm Design. Committed to building efficient, scalable mobile and web applications.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.9),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Social Links
              _buildSocialTile(
                context,
                icon: FontAwesomeIcons.github,
                title: "GitHub",
                subtitle: "github.com/ebongi",
                onTap: () => _launchURL("https://github.com/ebongi"),
              ),
              const SizedBox(height: 12),
              _buildSocialTile(
                context,
                icon: Icons.alternate_email_rounded,
                title: "Email",
                subtitle: "sumeebong7@gmail.com",
                onTap: () => _launchURL("mailto:sumeebong7@gmail.com"),
              ),
              const SizedBox(height: 12),
              _buildSocialTile(
                context,
                icon: FontAwesomeIcons.linkedin,
                title: "LinkedIn",
                subtitle: "linkedin.com/in/ebong-sume-4b0816298",
                onTap: () => _launchURL(
                  "https://www.linkedin.com/in/ebong-sume-4b0816298",
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
