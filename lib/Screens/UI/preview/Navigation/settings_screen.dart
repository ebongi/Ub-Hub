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
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsSection(context, "General", [
            _buildSettingsTile(
              context,
              icon: Icons.person_outline_rounded,
              title: "Account",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Accountdetails()),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.notifications_outlined,
              title: "Notifications",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Notifications()),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.dark_mode_outlined,
              title: "Dark Mode",
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) => themeProvider.toggleTheme(value),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSettingsSection(context, "Support", [
            _buildSettingsTile(
              context,
              icon: Icons.share_outlined,
              title: "Invite Friends",
              onTap: () {},
            ),
            _buildSettingsTile(
              context,
              icon: Icons.star_outline_rounded,
              title: "Rate App",
              onTap: () {},
            ),
            _buildSettingsTile(
              context,
              icon: Icons.feedback_outlined,
              title: "Feedback",
              onTap: () {},
            ),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline_rounded,
              title: "About",
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),
          _buildSettingsTile(
            context,
            icon: Icons.logout_rounded,
            title: "Logout",
            onTap: () async => await authentication.signUserOut(),
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Text(
                  "Go-Student",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Version $_version (Build $buildnumber)",
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color:
            iconColor ??
            Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
