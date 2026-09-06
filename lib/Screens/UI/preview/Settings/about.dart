import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_study/core/app_assets.dart';
import 'package:go_study/core/app_wordmark.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  String _appName = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appName = info.appName;
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  void _showPlatformAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: "GoStudy",
      applicationVersion: "v$_version ($_buildNumber)",
      applicationIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          AppAssets.logo,
          width: 48,
          height: 48,
          cacheWidth: 100,
        ),
      ),
      applicationLegalese: l10n.appLegaleseCopyright,
      children: [
        const SizedBox(height: 20),
        Text(
          l10n.aboutDialogDescription,
          style: GoogleFonts.outfit(fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.aboutAppTitle,
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
              child: Image.asset(
                AppAssets.logo,
                cacheWidth: 150,
              ),
            ),
            const SizedBox(height: 24),
            const AppWordmark(fontSize: 32),
            Text(
              l10n.versionLabel(_version),
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            
            // App Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                    ? theme.colorScheme.surfaceContainerLow 
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Text(
                l10n.appDescriptionBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  height: 1.6,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Standard About Dialog Trigger
            ListTile(
              onTap: _showPlatformAboutDialog,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                l10n.licensesLegalTitle,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                l10n.openSourceLibrariesSubtitle,
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
              l10n.appLegaleseCopyright,
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
