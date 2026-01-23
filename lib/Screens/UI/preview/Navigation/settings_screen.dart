import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/UI/preview/Settings/accountdetails.dart';
import 'package:neo/Screens/UI/preview/Settings/notifications.dart';
import 'package:neo/services/auth.dart' show Authentication;
import 'package:neo/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

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
    // final DatabaseService _database =   DatabaseService();

    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: GoogleFonts.outfit())),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Accountdetails()),
              ),
              leading: const Icon(Icons.person),
              title: Text(
                "Account",
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
              onTap: () async {},
              leading: const Icon(Icons.person_add),
              title: Text(
                "Invite friends",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () async {},
              leading: const Icon(Icons.star),
              title: Text(
                "Rating",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () async {},
              leading: const Icon(Icons.feedback),
              title: Text(
                "Feedback",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () async {},
              leading: const Icon(Icons.description),
              title: Text(
                "About",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Divider(),
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
          Divider(),
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
          Divider(),
          SizedBox(height: 30),
          Column(
            children: [
              Text(
                "Go-Study",
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
