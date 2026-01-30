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
      appBar: AppBar(
        title: Text("About", style: GoogleFonts.outfit()),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 50,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _appName,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Version $_version ($_buildNumber)",
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Text(
                "Go-Study helps students organize their academic life, find resources, and collaborate with peers.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 16),
              ),
              const Spacer(),
              Text(
                "© ${DateTime.now().year} Ub-Hub Team",
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
