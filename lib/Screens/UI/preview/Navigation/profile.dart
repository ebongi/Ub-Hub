import 'package:flutter/material.dart';
import 'package:go_study/services/subscription_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/profile.dart';

import 'package:go_study/Screens/UI/preview/Settings/subscription_plans_screen.dart';
import 'package:image_picker/image_picker.dart';

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
      body: StreamBuilder<UserProfile>(
        stream: _db.userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text("User not found"));
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
                  _authentication.currentUser?.email ?? "",
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
                        color: user.subscriptionTier == SubscriptionTier.gold
                            ? Colors.amber
                            : Colors.blueGrey,
                        isPremium: true,
                      ),
                    ],
                  ],
                ),

                if (user.isTrialActive) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "FREE TRIAL: ${user.trialTimeLeft}",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                const SizedBox(height: 32),
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
              ],
            ),
          );
        },
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
        borderRadius: BorderRadius.circular(20),
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
    UserProfile user,
    ThemeData theme,
  ) {
    final isContributor =
        user.role == UserRole.contributor || user.role == UserRole.admin;
    final hasSilver = user.subscriptionTier == SubscriptionTier.silver;
    final hasGold = user.subscriptionTier == SubscriptionTier.gold;

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
                          : (hasGold
                                ? "Gold Member"
                                : (hasSilver
                                      ? "Silver Member"
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
                      builder: (context) =>
                          SubscriptionPlansScreen(userProfile: user),
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
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value:
                    user.freeDownloadCount /
                    SubscriptionService.freeTierDownloadLimit,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final imageBytes = await pickedFile.readAsBytes();
      await _db.uploadAvatar(imageBytes);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated!")),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
      }
    }
  }
}
