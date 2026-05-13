import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "GO-Study",
      applicationVersion: "v$_version ($_buildNumber)",
      applicationIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SvgPicture.asset(
          'assets/images/logoicon.svg',
          width: 48,
          height: 48,
        ),
      ),
      applicationLegalese: "© 2026 Jovial Studio",
      children: [
        const SizedBox(height: 16),
        Text(
          "GO-Study is an all-in-one academic platform built specifically for students at the University of Buea. Our mission is to digitize the campus experience, making academic resources, collaboration, and planning accessible from anywhere.",
          style: GoogleFonts.outfit(fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "About App",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // App Logo
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: SvgPicture.asset('assets/images/logoicon.svg'),
            ),
            const SizedBox(height: 24),
            Text(
              "GO-Study",
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              "Version $_version",
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            
            // App Description
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark 
                    ? theme.colorScheme.surfaceContainerLow 
                    : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Empowering Academic Excellence",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "GO-Study is specifically designed to meet the technical and academic needs of University of Buea students. We provide a centralized hub for course materials, AI-powered study assistance, real-time exam tracking, and a collaborative global chat to ensure you stay ahead in your studies.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Dialog trigger
            ListTile(
              onTap: () => _showAboutDialog(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              tileColor: isDark 
                  ? theme.colorScheme.surfaceContainerLow 
                  : Colors.white,
              leading: Icon(
                Iconsax.info_circle,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                "Licenses & Legal",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "Open source libraries and legal information",
                style: GoogleFonts.outfit(fontSize: 12),
              ),
              trailing: const Icon(Iconsax.arrow_right_3, size: 18),
            ),
            
            const SizedBox(height: 60),
            Text(
              "Built with ❤️ for UB Students",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "© 2026 Jovial Studio",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
