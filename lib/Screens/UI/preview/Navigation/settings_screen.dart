import 'package:flutter/material.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/UI/preview/Navigation/profile.dart';
import 'package:go_study/Screens/UI/preview/Settings/notifications.dart';
import 'package:go_study/Screens/UI/preview/Settings/about.dart';

import 'package:go_study/Screens/UI/preview/Settings/subscription_plans_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/privacy_policy_screen.dart';

import 'package:go_study/services/auth.dart' show Authentication;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
                      icon: Icons.payment_rounded,
                      iconColor: Colors.green,
                      title: "Subscription Plans",
                      subtitle: "View your current plan and billing details",
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionPlansScreen(),
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
                    // _GoogleSettingsTile(
                    //   icon: Icons.help_outline_rounded,
                    //   iconColor: Colors.cyan,
                    //   title: "Support",
                    //   subtitle: "Get help or report an issue",
                    //   isDark: isDark,
                    //   onTap: () => showSupportDialog(context),
                    // ),
                    // _GoogleSettingsTile(
                    //   icon: Icons.code_rounded,
                    //   iconColor: Colors.blueGrey,
                    //   title: "Developer Information",
                    //   subtitle: "App version, build, and engineering details",
                    //   isDark: isDark,
                    //   onTap: () => Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (context) => const DeveloperInfoScreen(),
                    //     ),
                    //   ),
                    // ),
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

  Widget _buildProfileHeader(UserModel userModel, bool isDark) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundImage: userModel.avatarUrl != null
                    ? CachedNetworkImageProvider(userModel.avatarUrl!)
                    : null,
                child: userModel.avatarUrl == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF303134) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userModel.name ?? "User Name",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userModel.email ?? "user@email.com",
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
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

  Widget _buildBottomButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w400),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white70 : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey),
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
  final VoidCallback? onTap;
  final bool isDark;

  const _GoogleSettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.2,
          ),
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.white38 : Colors.grey,
          ),
    );
  }
}
