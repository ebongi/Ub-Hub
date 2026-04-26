import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/services/subscription_service.dart';
import 'package:go_study/services/nkwa_service.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  final UserProfile? userProfile;
  const SubscriptionPlansScreen({super.key, this.userProfile});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final DatabaseService _db = DatabaseService(
    uid: Authentication().currentUser?.id,
  );
  bool _isProcessing = false;
  SubscriptionTier? _processingTier;
  bool _isProcessingContributor = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTier =
        widget.userProfile?.subscriptionTier ?? SubscriptionTier.free;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Subscription Plans",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upgrade your experience",
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Choose the plan that suits your academic needs.",
              style: GoogleFonts.outfit(fontSize: 16, color: theme.hintColor),
            ),
            const SizedBox(height: 32),
            _buildTierCard(
              context,
              tier: SubscriptionTier.monthly,
              title: "Monthly Plan",
              price: SubscriptionService.monthlyPrice,
              color: Colors.blueGrey,
              isCurrent: currentTier == SubscriptionTier.monthly,
            ),
            const SizedBox(height: 20),
            _buildTierCard(
              context,
              tier: SubscriptionTier.yearly,
              title: "Yearly Plan",
              price: SubscriptionService.yearlyPrice,
              color: const Color(0xFFFFD700),
              isCurrent: currentTier == SubscriptionTier.yearly,
              isPremium: true,
            ),
            const SizedBox(height: 20),
            _buildContributorCard(context, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required SubscriptionTier tier,
    required String title,
    required double price,
    required Color color,
    required bool isCurrent,
    bool isPremium = false,
  }) {
    final theme = Theme.of(context);
    final features = SubscriptionService.getTierFeatures(tier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPremium
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium
              ? theme.colorScheme.primary.withOpacity(0.5)
              : theme.colorScheme.outlineVariant,
          width: 2,
        ),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (isCurrent)
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${price.toInt()} XAF",
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                tier == SubscriptionTier.monthly ? "/ month" : "/ year",
                style: GoogleFonts.outfit(fontSize: 16, color: theme.hintColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.done_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isCurrent || _isProcessing || widget.userProfile?.role == UserRole.admin
                ? null
                : () => _handlePurchase(tier, price),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrent
                  ? Colors.transparent
                  : (isPremium
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface),
              foregroundColor: isCurrent
                  ? theme.colorScheme.primary
                  : (isPremium
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.surface),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              side: isCurrent
                  ? BorderSide(color: theme.colorScheme.primary)
                  : null,
            ),
            child: _processingTier == tier
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  )
                : Text(
                    widget.userProfile?.role == UserRole.admin 
                        ? "Admin Access"
                        : (isCurrent ? "Current Plan" : "Upgrade Now"),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorCard(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.secondary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "CONTRIBUTOR",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Be a Creator",
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload your own materials, earn from downloads, and unlock everything forever.",
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.userProfile?.role == UserRole.contributor || widget.userProfile?.role == UserRole.admin
                ? null
                : () => _handleContributorUpgrade(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.secondary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isProcessingContributor
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                  color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  )
                : Text(
                    widget.userProfile?.role == UserRole.contributor || widget.userProfile?.role == UserRole.admin
                        ? "Included with Admin/Contributor"
                        : "One-time Payment 5000 XAF",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(SubscriptionTier tier, double amount) async {
    final phoneController = TextEditingController();

    final proceed = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: "Subscribe",
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            surfaceTintColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   PremiumDialogHeader(
                    title: "Subscribe to ${SubscriptionService.getTierName(tier)}",
                    subtitle: "Unlock premium academic tools",
                    icon: Icons.workspace_premium_rounded,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          "Enter your Mobile Money number to pay ${amount.toInt()} XAF for ${tier == SubscriptionTier.monthly ? '30' : '365'} days of access.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PremiumTextField(
                          controller: phoneController,
                          label: "Phone Number",
                          hint: "6XXXXXXXX",
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 32),
                        PremiumSubmitButton(
                          label: "Pay Now",
                          isLoading: false,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.outfit(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (proceed == true && phoneController.text.isNotEmpty) {
      _processPayment(tier, amount, phoneController.text.trim());
    }
  }

  Future<void> _processPayment(
    SubscriptionTier tier,
    double amount,
    String phone,
  ) async {
    setState(() {
      _isProcessing = true;
      _processingTier = tier;
    });

    try {
      final response = await NkwaService.collectPayment(
        amount: amount,
        phoneNumber: NkwaService.formatPhoneNumber(phone),
        description: "${SubscriptionService.getTierName(tier)} Subscription",
      );

      final paymentId = response['paymentId'] ?? response['id'];

      setState(() => _statusMessage = "Check your phone to approve...");

      final status = await NkwaService.waitForSuccessfulPayment(paymentId);

      if (status == PaymentStatus.success) {
        await _db.upgradeSubscription(tier);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subscription activated!")),
          );
          Navigator.pop(context);
        }
      } else if (status == PaymentStatus.cancelled) {
        throw "Payment was cancelled";
      } else {
        throw "Payment timed out or failed. Please try again.";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingTier = null;
          _statusMessage = null;
        });
      }
    }
  }

  Future<void> _handleContributorUpgrade() async {
    final phoneController = TextEditingController();

    final proceed = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: "Upgrade to Contributor",
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            surfaceTintColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PremiumDialogHeader(
                    title: "Upgrade to Contributor",
                    subtitle: "Unlock everything forever",
                    icon: Icons.stars_rounded,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          "Pay 5000 XAF once to unlock unlimited downloads, uploads, and all premium features forever.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PremiumTextField(
                          controller: phoneController,
                          label: "Momo/OM Number",
                          hint: "6XXXXXXXX",
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 32),
                        PremiumSubmitButton(
                          label: "Pay Now",
                          isLoading: false,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.outfit(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (proceed == true && phoneController.text.isNotEmpty) {
      _processContributorPayment(phoneController.text.trim());
    }
  }

  Future<void> _processContributorPayment(String phone) async {
    setState(() {
      _isProcessing = true;
      _isProcessingContributor = true;
    });
    try {
      final response = await NkwaService.collectPayment(
        amount: 5000.0,
        phoneNumber: NkwaService.formatPhoneNumber(phone),
        description: "Contributor Upgrade",
      );

      final paymentId = response['paymentId'] ?? response['id'];

      setState(() => _statusMessage = "Check your phone to approve...");

      final status = await NkwaService.waitForSuccessfulPayment(paymentId);

      if (status == PaymentStatus.success) {
        await _db.upgradeUserToContributor();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You are now a Contributor!")),
          );
          Navigator.pop(context);
        }
      } else if (status == PaymentStatus.cancelled) {
        throw "Payment was cancelled";
      } else {
        throw "Payment timed out or failed. Please try again.";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isProcessingContributor = false;
          _statusMessage = null;
        });
      }
    }
  }
}
