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
  String _appName = 'Ub-Hub';

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
      _appName = info.appName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030E22),
      appBar: AppBar(
        title: Text("About", style: GoogleFonts.outfit()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                color: Colors.white,
              ),
            ),
            Text(
              "Version $_version ($_buildNumber)",
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Features Section
            _buildCategoryHeader("Academic Excellence"),
            _buildFeatureTile(
              icon: Icons.calculate_rounded,
              title: "GPA Calculator",
              description:
                  "Easily track and project your academic performance.",
            ),
            _buildFeatureTile(
              icon: Icons.library_books_rounded,
              title: "Resource Hub",
              description:
                  "Access department materials, past questions, and more.",
            ),
            _buildFeatureTile(
              icon: Icons.class_rounded,
              title: "Course Management",
              description:
                  "Stay organized with your department-specific courses.",
            ),

            const SizedBox(height: 30),
            _buildCategoryHeader("Productivity & Focus"),
            _buildFeatureTile(
              icon: Icons.timer_3d_rounded,
              title: "3D Study Timer",
              description:
                  "Boost focus with our visually immersive study companion.",
            ),
            _buildFeatureTile(
              icon: Icons.checklist_rounded,
              title: "Task To-Do List",
              description: "Plan your studies and never miss a deadline.",
            ),

            const SizedBox(height: 30),
            _buildCategoryHeader("Collaboration & AI"),
            _buildFeatureTile(
              icon: Icons.forum_rounded,
              title: "Global Chat",
              description:
                  "Connect and discuss with peers from across the university.",
            ),
            _buildFeatureTile(
              icon: Icons.psychology_rounded,
              title: "AI Study Assistant",
              description:
                  "Get instant answers and explanations for your courses.",
            ),

            const SizedBox(height: 30),
            _buildCategoryHeader("Stay Informed"),
            _buildFeatureTile(
              icon: Icons.event_note_rounded,
              title: "Exam Schedules",
              description: "Track your upcoming exams and venues in real-time.",
            ),
            _buildFeatureTile(
              icon: Icons.notifications_active_rounded,
              title: "Smart Notifications",
              description: "Get reminded about tasks, exams, and key updates.",
            ),

            const SizedBox(height: 50),
            Text(
              "Ub Studies is dedicated to empowering students at the University of Buea with modern technical tools for academic success.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "© ${DateTime.now().year} Ub-Hub Team",
              style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.cyanAccent,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white60,
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
