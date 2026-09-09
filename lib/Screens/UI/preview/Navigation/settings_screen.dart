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
import 'package:go_study/Screens/Shared/settings_section.dart';
import 'package:go_study/Screens/Shared/app_language_dialog.dart';
import 'package:go_study/theme_provider.dart';
import 'package:go_study/theme/app_text_styles.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_radius.dart';
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

    final bgColor = isDark ? colorScheme.surface : Colors.white;

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
                style: AppText.sectionTitle(context).copyWith(fontSize: 18),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileHeader(context, userModel, l10n),
                  const SizedBox(height: AppSpacing.md),
                  _buildFlatSection(
                    context,
                    label: l10n.settingsSectionAppearance,
                    rows: [
                      SettingsRow(
                        icon: Icons.dark_mode_outlined,
                        title: l10n.darkModeTitle,
                        subtitle: l10n.darkModeSubtitle,
                        tint: const Color(0xFF3F51B5),
                        trailing: Switch(
                          value: themeProvider.themeMode == ThemeMode.dark,
                          onChanged: (value) => themeProvider.toggleTheme(value),
                        ),
                      ),
                    ],
                  ),
                  _buildFlatSection(
                    context,
                    label: l10n.settingsSectionLanguage,
                    rows: [
                      SettingsRow(
                        icon: Icons.language_rounded,
                        title: l10n.appLanguageTitle,
                        subtitle: l10n.appLanguageSubtitle,
                        tint: const Color(0xFF24C1E0),
                        onTap: () => showAppLanguageDialog(context, localeProvider, l10n),
                      ),
                    ],
                  ),
                  _buildFlatSection(
                    context,
                    label: l10n.settingsSectionAccount,
                    rows: [
                      if (userModel.role == UserRole.admin)
                        SettingsRow(
                          icon: Icons.admin_panel_settings_rounded,
                          title: l10n.adminDashboardTitle,
                          subtitle: l10n.adminDashboardSubtitle,
                          tint: const Color(0xFF9334E6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminPanel(),
                            ),
                          ),
                        ),
                      SettingsRow(
                        icon: Icons.bolt_rounded,
                        title: l10n.aiCreditsPlansTitle,
                        subtitle: l10n.aiCreditsRemaining(userModel.aiCredits),
                        tint: Colors.amber[800],
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
                    ],
                  ),
                  _buildFlatSection(
                    context,
                    label: l10n.settingsSectionNotifications,
                    rows: [
                      SettingsRow(
                        icon: Icons.notifications_none_rounded,
                        title: l10n.notificationsTitle,
                        subtitle: l10n.notificationsSubtitle,
                        tint: const Color(0xFFEA4335),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Notifications(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildFlatSection(
                    context,
                    label: l10n.settingsSectionSupport,
                    rows: [
                      SettingsRow(
                        icon: Icons.volunteer_activism_rounded,
                        title: l10n.supportGoStudyTitle,
                        subtitle: l10n.supportGoStudySubtitle,
                        tint: const Color(0xFFFF6D00),
                        onTap: () => _showSupportOptions(context, userModel),
                      ),
                      SettingsRow(
                        icon: Icons.feedback_outlined,
                        title: l10n.sendFeedbackTitle,
                        subtitle: l10n.sendFeedbackSubtitle,
                        tint: const Color(0xFF34A853),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FeedbackScreen(),
                          ),
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.code_rounded,
                        title: l10n.developerInformationTitle,
                        subtitle: l10n.developerInformationSubtitle,
                        tint: Colors.blueGrey,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeveloperInfoScreen(),
                          ),
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.info_outline_rounded,
                        title: l10n.aboutTitle,
                        subtitle: l10n.aboutSubtitle,
                        tint: const Color(0xFF4285F4),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildFlatSection(
                    context,
                    label: l10n.settingsSectionLegal,
                    rows: [
                      SettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.privacyPolicyTitle,
                        subtitle: l10n.privacyPolicySubtitle,
                        tint: Colors.teal,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        ),
                      ),
                      SettingsRow(
                        icon: Icons.gavel_rounded,
                        title: l10n.termsOfServiceTitle,
                        subtitle: l10n.termsOfServiceSubtitle,
                        tint: Colors.brown,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServiceScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Center(
                    child: TextButton.icon(
                      onPressed: () => authentication.signUserOut(),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: Text(
                        l10n.logout,
                        style: GoogleFonts.outfit(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          _showDeleteAccountFlow(context, authentication, l10n),
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

  /// Tappable account-summary card at the top of Settings — avatar, name,
  /// institution, and an AI-credits pill — matching the "your account" header
  /// seen at the top of Settings in e-learning apps like Coursera/Udemy,
  /// styled after the home feed's `IntroWidget` card (tinted background,
  /// subtle border, rounded corners).
  Widget _buildProfileHeader(
    BuildContext context,
    UserModel userModel,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarUrl = userModel.avatarUrl;
    final displayName = userModel.name != null && userModel.name!.isNotEmpty
        ? userModel.name!
        : l10n.studentFallbackName;
    final subtitleText = userModel.institutionName ?? l10n.unifiedAcademicPortal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Profile()),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerLow
                  : theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Icon(
                            Icons.person_rounded,
                            color: theme.colorScheme.primary,
                            size: 30,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle(context).copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardSubtitle(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${userModel.aiCredits}",
                        style: AppText.caption(context).copyWith(color: Colors.amber[800]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A flat Settings section: a bold all-caps grey label followed by plain
  /// rows separated by thin dividers — no card background/border around
  /// the group, matching the Coursera reference.
  Widget _buildFlatSection(
    BuildContext context, {
    required String label,
    required List<Widget> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionLabel(label),
        ...List.generate(rows.length, (index) {
          return Column(
            children: [
              rows[index],
              if (index < rows.length - 1) const Divider(indent: 16, endIndent: 16),
            ],
          );
        }),
      ],
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

  // A single dialog that walks the user through a warning step and then a
  // type-DELETE-to-confirm step, rather than two separate showDialog calls
  // popping and pushing in sequence (which flickered and duplicated the
  // shape/cancel-button styling across two builders).
  void _showDeleteAccountFlow(
    BuildContext context,
    Authentication authentication,
    AppLocalizations l10n,
  ) {
    final confirmController = TextEditingController();
    var showWarningStep = true;
    const dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final cancelButton = TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.outfit(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          );

          if (showWarningStep) {
            return AlertDialog(
              shape: dialogShape,
              title: Text(
                l10n.deleteAccountWarningTitle,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Text(
                  l10n.deleteAccountWarningBody,
                  style: GoogleFonts.outfit(height: 1.5),
                ),
              ),
              actions: [
                cancelButton,
                TextButton(
                  onPressed: () =>
                      setDialogState(() => showWarningStep = false),
                  child: Text(
                    l10n.deleteAccountWarningContinueButton,
                    style: GoogleFonts.outfit(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          }

          final canConfirm =
              confirmController.text.trim().toUpperCase() == 'DELETE';
          return AlertDialog(
            shape: dialogShape,
            title: Text(
              l10n.deleteAccountDialogTitle,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
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
            ),
            actions: [
              cancelButton,
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
    ).then((_) => confirmController.dispose());
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
    final String studentName = userModel.name ?? 'a GoStudy User';
    final String messageText =
        "💖 *SUPPORT & VOLUNTEER FOR GOSTUDY* 💖\n\n"
        "Hi Developer, I love using GoStudy and would like to voluntarily support the development and growth of this platform!\n\n"
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
          "Support GoStudy",
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

