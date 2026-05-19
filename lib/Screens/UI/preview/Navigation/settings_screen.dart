import 'package:flutter/material.dart';
import 'package:go_study/Screens/UI/preview/Navigation/profile.dart';
import 'package:go_study/Screens/UI/preview/Settings/developer_info_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/privacy_policy_screen.dart';
// import 'package:go_study/Screens/UI/preview/Settings/about_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:go_study/Screens/authentication/authenticate.dart';
import 'package:go_study/services/profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_study/theme_provider.dart';

import '../../../../services/auth.dart';
import '../Settings/about.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final userModel = Provider.of<UserModel>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final Authentication authentication = Authentication();

    final bgColor = isDark ? colorScheme.surface : const Color(0xFFF8F9FA);
    final cardColor = isDark ? colorScheme.surfaceContainerLow : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: bgColor,
              elevation: 0,
              pinned: true,
              centerTitle: true,
              title: Text(
                "Settings",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Account Section
                  _buildGoogleSettingsCard(context, [
                    _GoogleSettingsTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: Colors.blue,
                      title: "Account Profile",
                      subtitle: "View and edit your personal information",
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Profile(),
                        ),
                      ),
                    ),
                  ], cardColor: cardColor),
                  const SizedBox(height: 16),

                  // App Preferences
                  _buildGoogleSettingsCard(context, [
                    _GoogleSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      iconColor: Colors.orange,
                      title: "Notifications",
                      subtitle: "Manage your alerts and message preferences",
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Notifications(),
                        ),
                      ),
                    ),

                    _GoogleSettingsTile(
                      icon: Icons.dark_mode_outlined,
                      iconColor: Colors.indigo,
                      title: "Dark Mode",
                      subtitle: "Switch between light and dark themes",
                      isDark: isDark,
                      trailing: Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) => themeProvider.toggleTheme(value),
                      ),
                    ),
                  ], cardColor: cardColor),
                  const SizedBox(height: 16),

                  // Legal Section
                  _buildGoogleSettingsCard(context, [
                    _GoogleSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: Colors.purple,
                      title: "Privacy Policy",
                      subtitle: "How we protect and use your data",
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                  ], cardColor: cardColor),
                  const SizedBox(height: 16),

                  // Support Section
                  _buildGoogleSettingsCard(context, [
                    _GoogleSettingsTile(
                      icon: Icons.volunteer_activism_rounded,
                      iconColor: Colors.redAccent,
                      title: "Support Go Study",
                      subtitle: "Sponsor development or volunteer to help",
                      isDark: isDark,
                      onTap: () => _supportPlatformViaWhatsApp(context, userModel),
                    ),
                    _GoogleSettingsTile(
                      icon: Icons.code_rounded,
                      iconColor: Colors.blueGrey,
                      title: "Developer Information",
                      subtitle: "App version, build, and engineering details",
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DeveloperInfoScreen(),
                        ),
                      ),
                    ),
                    _GoogleSettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.teal,
                      title: "About",
                      subtitle: "Learn more about the application ",
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      ),
                    ),
                  ], cardColor: cardColor),
                  const SizedBox(height: 32),

                  TextButton.icon(
                    onPressed: () => authentication.signUserOut(),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      "Logout",
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "Version $_version ($buildnumber)\n© 2026 Jovial Studio",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSettingsCard(
    BuildContext context,
    List<Widget> tiles, {
    required Color cardColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: List.generate(tiles.length, (index) {
          return Column(
            children: [
              tiles[index],
              if (index < tiles.length - 1)
                const Divider(height: 1, indent: 70, endIndent: 20),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _supportPlatformViaWhatsApp(BuildContext context, UserModel userModel) async {
    final String studentName = userModel.name ?? 'a Go Study User';
    final String messageText = "💖 *SUPPORT & VOLUNTEER FOR GO STUDY* 💖\n\n"
        "Hi Developer, I love using Go Study and would like to voluntarily support the development and growth of this platform!\n\n"
        "Please let me know how I can contribute or help.\n\n"
        "Best regards,\n"
        "$studentName";

    final String whatsappNumber = "237682397481"; // Support contact from developer_info_screen
    final String url = "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(messageText)}";
    final Uri uri = Uri.parse(url);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Support Go Study",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Thank you for your generosity! We will open WhatsApp so you can send a message directly to the developer to discuss how to support or volunteer.",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Direct launch bypasses canLaunchUrl package visibility constraints
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                try {
                  await launchUrl(uri);
                } catch (e2) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Could not open WhatsApp. Please ensure WhatsApp is installed."),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              "Open WhatsApp",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isDark;
  final VoidCallback? onTap;

  const _GoogleSettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: isDark ? Colors.white30 : Colors.grey[400],
      ),
    );
  }
}
