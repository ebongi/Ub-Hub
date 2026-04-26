import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_study/services/subscription_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/profile.dart';

import 'package:go_study/Screens/UI/preview/Settings/subscription_plans_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_study/theme_provider.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final Authentication _authentication = Authentication();
  final DatabaseService _db = DatabaseService(
    uid: Authentication().currentUser?.id,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<UserModel>(
        builder: (context, user, child) {
          if (user.uid == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture Header
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.1,
                        ),
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _handleAvatarChange(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.name ?? "User",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email ?? "",
                  style: GoogleFonts.outfit(
                    color: theme.hintColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),

                // Role & Subscription Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge(
                      label: user.role.name.toUpperCase(),
                      color: _getRoleColor(user.role),
                    ),
                    if (user.subscriptionTier != SubscriptionTier.free) ...[
                      const SizedBox(width: 8),
                      _buildBadge(
                        label: user.subscriptionTier.name.toUpperCase(),
                        color: user.subscriptionTier == SubscriptionTier.yearly
                            ? Colors.amber
                            : Colors.blueGrey,
                        isPremium: true,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 32),

                // Trial Info Bar
                if (user.isTrialActive)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          "Trial Ends in: ${user.trialTimeLeft}",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Subscription Card

                // Personal Information Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.badge_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Personal Information",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          theme,
                          icon: Icons.email_rounded,
                          label: "Email Address",
                          value:
                              _authentication.currentUser?.email ?? "Not set",
                        ),
                        const Divider(height: 32, thickness: 0.5),
                        _buildInfoRow(
                          theme,
                          icon: Icons.tag_rounded,
                          label: "Matricule",
                          value: user.matricule ?? "Not provided",
                        ),
                        const Divider(height: 32, thickness: 0.5),
                        _buildInfoRow(
                          theme,
                          icon: Icons.phone_rounded,
                          label: "Phone Number",
                          value: user.phoneNumber ?? "Not provided",
                        ),
                        const Divider(height: 32, thickness: 0.5),
                        _buildInfoRow(
                          theme,
                          icon: Icons.school_rounded,
                          label: "Current Level",
                          value: user.level ?? "Not provided",
                        ),
                        const Divider(height: 32, thickness: 0.5),
                        _buildInfoRow(
                          theme,
                          icon: Icons.business_rounded,
                          label: "Department",
                          value: user.department ?? "Not set",
                        ),
                        const Divider(height: 32, thickness: 0.5),
                        _buildInfoRow(
                          theme,
                          icon: Icons.notes_rounded,
                          label: "Bio",
                          value: user.bio ?? "No bio yet",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Subscription Section
                user.role == UserRole.contributor || user.role == UserRole.admin
                    ? _buildUnlimitedBanner(theme)
                    : _buildManageSubscriptionCard(context, user, theme),

                const SizedBox(height: 32),

                // Theme Customization Section
                _buildThemeSection(context, theme),

                const SizedBox(height: 32),

                // Logout Section
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: Text(
                      "Sign Out",
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: Colors.red, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await _authentication.signUserOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.indigoAccent;
      case UserRole.contributor:
        return Colors.blueAccent;
      case UserRole.viewer:
        return Colors.green;
    }
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    bool isPremium = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildManageSubscriptionCard(
    BuildContext context,
    UserModel user,
    ThemeData theme,
  ) {
    final isContributor =
        user.role == UserRole.contributor || user.role == UserRole.admin;
    final hasMonthly = user.subscriptionTier == SubscriptionTier.monthly;
    final hasYearly = user.subscriptionTier == SubscriptionTier.yearly;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stars_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "Subscription & Access",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isContributor
                          ? "Unlimited Creator"
                          : (hasYearly
                                ? "Yearly Member"
                                : (hasMonthly
                                      ? "Monthly Member"
                                      : "Free Member")),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (user.subscriptionTier != SubscriptionTier.free &&
                        user.subscriptionExpiry != null)
                      Text(
                        "Expires: ${user.subscriptionExpiry!.day}/${user.subscriptionExpiry!.month}/${user.subscriptionExpiry!.year}",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: theme.hintColor,
                        ),
                      )
                    else if (!isContributor)
                      Text(
                        "Upgrade to unlock full features",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: theme.hintColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isContributor)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionPlansScreen(
                        userProfile: UserProfile(
                          id: user.uid ?? '',
                          name: user.name,
                          matricule: user.matricule,
                          phoneNumber: user.phoneNumber,
                          level: user.level,
                          role: user.role,
                          subscriptionTier: user.subscriptionTier,
                          avatarUrl: user.avatarUrl,
                          institutionId: user.institutionId,
                          bio: user.bio,
                          department: user.department,
                          createdAt: user.createdAt,
                        ),
                      ),
                    ),
                  ),
                  child: Text(
                    user.subscriptionTier == SubscriptionTier.free
                        ? "Upgrade"
                        : "Manage",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (user.subscriptionTier == SubscriptionTier.free &&
              !user.isTrialActive) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value:
                    user.freeDownloadCount /
                    SubscriptionService.freeTierDownloadLimit,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Free Downloads used: ${user.freeDownloadCount}/${SubscriptionService.freeTierDownloadLimit}",
              style: GoogleFonts.outfit(fontSize: 12, color: theme.hintColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnlimitedBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Unlimited Access",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "You can now upload and download everything for free.",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAvatarChange(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Change Avatar",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildSourceOption(
                context,
                icon: Icons.photo_library_rounded,
                title: "Gallery",
                color: Colors.blue,
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
              _buildSourceOption(
                context,
                icon: Icons.camera_alt_rounded,
                title: "Camera",
                color: Colors.orange,
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        }

        try {
          final bytes = await File(image.path).readAsBytes();
          final url = await _db.uploadAvatar(bytes);
          await _db.updateUserData(avatarUrl: url);
          // Provider will update automatically via AuthWrapper
          if (mounted) Navigator.pop(context); // Close loading
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error uploading avatar: $e")),
            );
          }
        }
      }
    }
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, ThemeData theme) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Color> colors = [
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.cyan,
    ];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  "App Appearance",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Accent Color",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final color = colors[index];
                  final isSelected =
                      themeProvider.accentColor.value == color.value;
                  return GestureDetector(
                    onTap: () => themeProvider.setAccentColor(color),
                    child: Container(
                      width: 45,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Dark Mode",
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (value) => themeProvider.toggleTheme(value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
