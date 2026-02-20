import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/services/auth.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/profile.dart';
import 'package:neo/services/nkwa_service.dart';
import 'package:neo/services/payment_models.dart';
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

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getRoleColor(user.role).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    user.role.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

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

                // Access Tier Info / Upgrade Card
                if (user.role == UserRole.viewer)
                  _buildUpgradeCard(context, theme)
                else
                  _buildContributorBadge(theme),

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

  Widget _buildUpgradeCard(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          Text(
            "Upgrade Access",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Unlock unlimited downloads and material upload capabilities.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _handleUpgrade(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              "Upgrade for ${NkwaService.getContributorUpgradeFee().toInt()} XAF",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorBadge(ThemeData theme) {
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

  Widget _buildActionItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: color),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color.withOpacity(0.5),
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

  Future<void> _handleUpgrade(BuildContext context) async {
    // Show confirmation or payment dialog
    final phoneNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Upgrade to Contributor",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Pay 5000 XAF to upgrade your account. This unlocks unlimited downloads and the ability to upload materials.",
              style: GoogleFonts.outfit(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneNumberController,
              decoration: const InputDecoration(
                labelText: "Momo/OM Number",
                hintText: "6XXXXXXXX",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneNumberController.text.trim();
              if (phone.isEmpty) return;

              Navigator.pop(context);
              _processUpgradePayment(context, phone);
            },
            child: const Text("Pay Now"),
          ),
        ],
      ),
    );
  }

  Future<void> _processUpgradePayment(
    BuildContext context,
    String phone,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await NkwaService.collectPayment(
        amount: NkwaService.getContributorUpgradeFee(),
        phoneNumber: NkwaService.formatPhoneNumber(phone),
        description: "Contributor Role Upgrade",
      );

      final paymentId = response['paymentId'] ?? response['id'];

      // Wait for status to be success (simple polling or just success check)
      // In a real app, we'd use a more robust polling or callback mechanism
      final status = await NkwaService.checkPaymentStatus(paymentId);

      Navigator.pop(context); // Remove progress indicator

      if (status == PaymentStatus.success) {
        await _db.upgradeUserToContributor();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account upgraded successfully!")),
          );
        }
      } else {
        throw Exception("Payment was not successful (Status: $status)");
      }
    } catch (e) {
      if (mounted) {
        // Navigator.pop(context); // Already popped in success but good for error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upgrade Failed: ${e.toString()}")),
        );
      }
    }
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
