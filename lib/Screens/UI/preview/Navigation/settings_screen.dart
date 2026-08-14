import 'package:flutter/material.dart';
import 'package:go_study/Screens/UI/preview/Navigation/profile.dart';
import 'package:go_study/Screens/UI/preview/Navigation/admin_panel.dart';
import 'package:go_study/Screens/UI/preview/Settings/developer_info_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/privacy_policy_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/terms_of_service_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/notifications.dart';
import 'package:go_study/Screens/UI/preview/Settings/feedback.dart';
import 'package:go_study/Screens/UI/preview/Settings/support_dialog.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/locale_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/theme_provider.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/Screens/UI/preview/Settings/subscription_plans_screen.dart';

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
    final localeProvider = Provider.of<LocaleProvider>(context);
    final Authentication authentication = Authentication();
    final l10n = AppLocalizations.of(context)!;

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
                l10n.settingsTitle,
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
                      title: l10n.accountProfileTitle,
                      subtitle: l10n.accountProfileSubtitle,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Profile(),
                        ),
                      ),
                    ),
                    if (userModel.role == UserRole.admin)
                      _GoogleSettingsTile(
                        icon: Icons.admin_panel_settings_rounded,
                        iconColor: Colors.indigo,
                        title: l10n.adminDashboardTitle,
                        subtitle: l10n.adminDashboardSubtitle,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPanel(),
                          ),
                        ),
                      ),
                  ], cardColor: cardColor),
                  const SizedBox(height: 16),

                  // App Preferences
                  _buildGoogleSettingsCard(context, [
                    _GoogleSettingsTile(
                      icon: Icons.bolt_rounded,
                      iconColor: Colors.amber,
                      title: l10n.aiCreditsPlansTitle,
                      subtitle: l10n.aiCreditsRemaining(userModel.aiCredits),
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionPlansScreen(
                            userProfile: UserProfile(
                              id: userModel.uid ?? '',
                              name: userModel.name,
                              aiCredits: userModel.aiCredits,
                              subscriptionTier: userModel.subscriptionTier,
                              subscriptionExpiry: userModel.subscriptionExpiry,
                              role: userModel.role,
                            ),
                          ),
                        ),
                      ),
                    ),

                    _GoogleSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      iconColor: Colors.orange,
                      title: l10n.notificationsTitle,
                      subtitle: l10n.notificationsSubtitle,
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
                      title: l10n.darkModeTitle,
                      subtitle: l10n.darkModeSubtitle,
                      isDark: isDark,
                      trailing: Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) => themeProvider.toggleTheme(value),
                      ),
                    ),

                    _GoogleSettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: Colors.teal,
                      title: l10n.appLanguageTitle,
                      subtitle: l10n.appLanguageSubtitle,
                      isDark: isDark,
                      onTap: () => _showLanguagePicker(
                        context,
                        localeProvider,
                        l10n,
                      ),
                    ),
                  ], cardColor: cardColor),
                  const SizedBox(height: 16),

                  // Legal Section
                  _buildGoogleSettingsCard(context, [
                    _GoogleSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: Colors.purple,
                      title: l10n.privacyPolicyTitle,
                      subtitle: l10n.privacyPolicySubtitle,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                    _GoogleSettingsTile(
                      icon: Icons.gavel_rounded,
                      iconColor: Colors.indigo,
                      title: l10n.termsOfServiceTitle,
                      subtitle: l10n.termsOfServiceSubtitle,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfServiceScreen(),
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
                      title: l10n.supportGoStudyTitle,
                      subtitle: l10n.supportGoStudySubtitle,
                      isDark: isDark,
                      onTap: () => _showSupportOptions(context, userModel),
                    ),
                    _GoogleSettingsTile(
                      icon: Icons.feedback_outlined,
                      iconColor: Colors.orange,
                      title: l10n.sendFeedbackTitle,
                      subtitle: l10n.sendFeedbackSubtitle,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackScreen(),
                        ),
                      ),
                    ),
                    _GoogleSettingsTile(
                      icon: Icons.code_rounded,
                      iconColor: Colors.blueGrey,
                      title: l10n.developerInformationTitle,
                      subtitle: l10n.developerInformationSubtitle,
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
                      title: l10n.aboutTitle,
                      subtitle: l10n.aboutSubtitle,
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
                      l10n.logout,
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          _confirmDeleteAccount(context, authentication, l10n),
                      child: Text(
                        l10n.deleteAccountButton,
                        style: GoogleFonts.outfit(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "Version $_version ($buildnumber)\n© 2026 Jovial Labs",
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

  void _showLanguagePicker(
    BuildContext context,
    LocaleProvider localeProvider,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.appLanguageTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale?>(
              title: Text(l10n.languageSystemDefault),
              value: null,
              groupValue: localeProvider.locale,
              onChanged: (value) {
                localeProvider.setLocale(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale?>(
              title: Text(l10n.languageEnglish),
              value: const Locale('en'),
              groupValue: localeProvider.locale,
              onChanged: (value) {
                localeProvider.setLocale(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale?>(
              title: Text(l10n.languageFrench),
              value: const Locale('fr'),
              groupValue: localeProvider.locale,
              onChanged: (value) {
                localeProvider.setLocale(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportOptions(BuildContext context, UserModel userModel) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.supportGoStudyTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.supportOptionsDialogBody,
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _supportPlatformViaWhatsApp(context, userModel);
            },
            child: Text(
              l10n.chatOnWhatsAppButton,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showSupportDialog(context);
            },
            child: Text(
              l10n.donateViaAppButton,
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

  void _confirmDeleteAccount(
    BuildContext context,
    Authentication authentication,
    AppLocalizations l10n,
  ) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final canConfirm =
              confirmController.text.trim().toUpperCase() == 'DELETE';
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              l10n.deleteAccountDialogTitle,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deleteAccountDialogBody,
                  style: GoogleFonts.outfit(),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.deleteAccountTypeToConfirm,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  l10n.cancel,
                  style: GoogleFonts.outfit(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: canConfirm
                    ? () async {
                        Navigator.pop(dialogContext);
                        await _performAccountDeletion(
                          context,
                          authentication,
                          l10n,
                        );
                      }
                    : null,
                child: Text(
                  l10n.deleteAccountConfirmButton,
                  style: GoogleFonts.outfit(
                    color: canConfirm ? Colors.red : Colors.grey.shade400,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performAccountDeletion(
    BuildContext context,
    Authentication authentication,
    AppLocalizations l10n,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      await authentication.deleteAccount();
      // No further navigation needed here — AuthWrapper's auth-state
      // listener reacts to the resulting signed-out session and switches
      // to the sign-in screen on its own. Just dismiss the spinner.
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deleteAccountFailed(e.toString())),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _supportPlatformViaWhatsApp(
    BuildContext context,
    UserModel userModel,
  ) async {
    final String studentName = userModel.name ?? 'a Go Study User';
    final String messageText =
        "💖 *SUPPORT & VOLUNTEER FOR GO STUDY* 💖\n\n"
        "Hi Developer, I love using Go Study and would like to voluntarily support the development and growth of this platform!\n\n"
        "Please let me know how I can contribute or help.\n\n"
        "Best regards,\n"
        "$studentName";

    final String whatsappNumber =
        "237682397481"; // Support contact from developer_info_screen
    final String url =
        "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(messageText)}";
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
                        content: Text(
                          "Could not open WhatsApp. Please ensure WhatsApp is installed.",
                        ),
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
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: isDark ? Colors.white30 : Colors.grey[400],
          ),
    );
  }
}
