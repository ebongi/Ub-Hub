import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/Shared/animations.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "About",
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // App Logo Section
            ScaleButton(
              onTap: () {},
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Ub Studies",
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              "Version $_version ($_buildNumber)",
              style: GoogleFonts.outfit(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            // Features Section
            _buildCategoryHeader(context, "Academic Excellence"),
            _buildFeatureTile(
              context,
              icon: Icons.calculate_rounded,
              title: "GPA Calculator",
              description:
                  "Easily track and project your academic performance.",
            ),
            _buildFeatureTile(
              context,
              icon: Icons.library_books_rounded,
              title: "Resource Hub",
              description:
                  "Access department materials, past questions, and more.",
            ),
            _buildFeatureTile(
              context,
              icon: Icons.class_rounded,
              title: "Course Management",
              description:
                  "Stay organized with your department-specific courses.",
            ),

            const SizedBox(height: 30),
            _buildCategoryHeader(context, "Productivity & Focus"),
            _buildFeatureTile(
              context,
              icon: Icons
                  .hourglass_bottom_rounded, // Changed from Icons.timer_3d_rounded
              title: "3D Study Timer",
              description:
                  "Boost focus with our visually immersive study companion.",
            ),
            _buildFeatureTile(
              context,
              icon: Icons.checklist_rounded,
              title: "Task To-Do List",
              description: "Plan your studies and never miss a deadline.",
            ),

            const SizedBox(height: 30),
            _buildCategoryHeader(context, "Collaboration & AI"),
            _buildFeatureTile(
              context,
              icon: Icons.forum_rounded,
              title: "Global Chat",
              description:
                  "Connect and discuss with peers from across the university.",
            ),
            _buildFeatureTile(
              context,
              icon: Icons.psychology_rounded,
              title: "AI Study Assistant",
              description:
                  "Get instant answers and explanations for your courses.",
            ),

            const SizedBox(height: 30),
            _buildCategoryHeader(context, "Stay Informed"),
            _buildFeatureTile(
              context,
              icon: Icons.event_note_rounded,
              title: "Exam Schedules",
              description: "Track your upcoming exams and venues in real-time.",
            ),
            _buildFeatureTile(
              context,
              icon: Icons.notifications_active_rounded,
              title: "Smart Notifications",
              description: "Get reminded about tasks, exams, and key updates.",
            ),

            const SizedBox(height: 50),
            Text(
              "Ub Studies is dedicated to empowering students at the University of Buea with modern technical tools for academic success.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "© ${DateTime.now().year} Ub-Hub Team",
              style: GoogleFonts.outfit(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.cyanAccent, // Keep accent color or use Theme primary
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.cyanAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
