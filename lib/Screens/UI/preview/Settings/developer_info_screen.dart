import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperInfoScreen extends StatefulWidget {
  const DeveloperInfoScreen({super.key});

  @override
  State<DeveloperInfoScreen> createState() => _DeveloperInfoScreenState();
}

class _DeveloperInfoScreenState extends State<DeveloperInfoScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.developerInfoTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left_2,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Section
            Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/developerImage.jpg",
                        fit: BoxFit.cover,
                        width: 160,
                        height: 160,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 160,
                            height: 160,
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Iconsax.user,
                              size: 60,
                              color: theme.colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Ebong Sume",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.leadDeveloperAtJovialLaps,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Engineering Details
            _buildSection(context, l10n.engineeringDetailsSection, [
              _buildInfoTile(
                context,
                Iconsax.info_circle,
                l10n.appVersionLabel,
                _version,
              ),
              _buildInfoTile(
                context,
                Iconsax.code,
                l10n.buildNumberLabel,
                _buildNumber,
              ),
              _buildInfoTile(context, Iconsax.box, l10n.frameworkLabel, "Flutter 3.4"),
            ]),
            const SizedBox(height: 24),

            // Connect Section
            _buildSection(context, l10n.connectSection, [
              _buildLinkTile(
                context,
                Iconsax.global,
                l10n.githubLabel,
                "ebongi",
                () => _launchURL("https://github.com/ebongi"),
              ),
              _buildLinkTile(
                context,
                Iconsax.link,
                l10n.linkedinLabel,
                l10n.professionalProfileSubtitle,
                () => _launchURL(
                  "https://www.linkedin.com/in/ebong-sume-4b0816298",
                ),
              ),
              _buildLinkTile(
                context,
                Iconsax.message_text,
                l10n.contactEmailLabel,
                "sumeebong7@gmail.com",
                () => _launchURL("mailto:sumeebong7@gmail.com"),
              ),
              _buildLinkTile(
                context,
                Iconsax.call,
                l10n.directLineLabel,
                "+237 682397481",
                () => _launchURL("tel:682397481"),
              ),
            ]),

            const SizedBox(height: 56),
            Text(
              l10n.builtWithLoveForUbStudents,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surfaceContainerLow : Colors.white,
            borderRadius: BorderRadius.circular(28),
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.outfit(
          fontSize: 15,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context,
    IconData icon,
    String label,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
      ),
      trailing: Icon(
        Iconsax.arrow_right_3,
        size: 16,
        color: Colors.grey.withOpacity(0.5),
      ),
    );
  }
}
