import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/Navigation/profile.dart';
import 'package:neo/Screens/UI/preview/Settings/notifications.dart';
import 'package:neo/Screens/UI/preview/Settings/about.dart';
import 'package:neo/Screens/UI/preview/Settings/developer_info.dart';
import 'package:neo/services/auth.dart' show Authentication;
import 'package:neo/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:neo/Screens/UI/preview/Settings/support_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String buildnumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersionDetails();
  }

  Future<void> _loadVersionDetails() async {
    final appinfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = appinfo.version;
      buildnumber = appinfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final Authentication authentication = Authentication();

    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: GoogleFonts.outfit())),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Profile()),
              ),
              leading: const Icon(Icons.person),
              title: Text(
                "Profile",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Notifications()),
              ),
              leading: const Icon(Icons.notifications),
              title: Text(
                "Notifications",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeveloperInfoScreen(),
                ),
              ),
              leading: const Icon(Icons.code),
              title: Text(
                "Developer",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () => showSupportDialog(context),
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: Text(
                "Support the developer",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              ),
              leading: const Icon(Icons.description),
              title: Text(
                "About",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: Text(
                'Dark Mode',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  final provider = Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  );
                  provider.toggleTheme(value);
                },
              ),
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              title: Text(
                'Logout',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
              leading: const Icon(Icons.logout),
              onTap: () async {
                await authentication.signUserOut();
              },
            ),
          ),
          const SizedBox(height: 30),
          Column(
            children: [
              Text(
                "Ub-Studies",
                style: GoogleFonts.outfit().copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.3,
                ),
              ),
              Text(
                "Version $_version+$buildnumber",
                style: GoogleFonts.outfit(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
