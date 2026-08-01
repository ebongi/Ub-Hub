import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/services/subscription_service.dart';
import 'package:go_study/services/fapshi_service.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:provider/provider.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final userModel = Provider.of<UserModel>(context);
    
    final currentTier = userModel.subscriptionTier;
    final credits = userModel.aiCredits;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "AI Credits & Plans",
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
            // Credits Balance Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Current Balance",
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        "$credits Credits",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Top up AI Credits",
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Credits are used for Gemini AI interactions. Core academic tools remain free for everyone.",
              style: GoogleFonts.outfit(fontSize: 14, color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            // --- FAPSHI SANDBOX TEST MODE (100 XAF) ---
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "FAPSHI TEST MODE",
                        style: GoogleFonts.outfit(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Icon(Icons.bug_report_outlined, color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Test payment integration with the Fapshi Sandbox (100 XAF). Adds 10 test credits.",
                    style: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _handlePurchaseCredits(100.0, 10, "Test Credits"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Pay 100 XAF (Test)",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            // Credit Packs
            _buildCreditPack(
              context,
              title: "Starter Pack",
              credits: 50,
              price: 500,
              icon: Icons.auto_awesome_outlined,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildCreditPack(
              context,
              title: "Student Pack",
              credits: 150,
              price: 1000,
              icon: Icons.rocket_launch_outlined,
              color: Colors.purple,
              isRecommended: true,
            ),
            const SizedBox(height: 32),
            Text(
              "Unlimited AI Subscriptions",
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildTierCard(
              context,
              tier: SubscriptionTier.monthly,
              title: "Unlimited Monthly",
              price: 2500,
              color: Colors.orange,
              isCurrent: currentTier == SubscriptionTier.monthly,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditPack(
    BuildContext context, {
    required String title,
    required int credits,
    required double price,
    required IconData icon,
    required Color color,
    bool isRecommended = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecommended ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRecommended)
                  Text(
                    "MOST POPULAR",
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  "$credits AI Credits",
                  style: GoogleFonts.outfit(color: theme.hintColor, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isProcessing ? null : () => _handlePurchaseCredits(price, credits, title),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecommended ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              foregroundColor: isRecommended ? theme.colorScheme.onPrimary : theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("${price.toInt()} XAF"),
          ),
        ],
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
    final features = [
      "Unlimited Gemini AI Chat",
      "Unlimited PDF Summaries",
      "Priority AI Response",
      "AI Study Plan Generator",
      "Structure Quiz Generator",
    ];

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              if (isCurrent)
                Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "${price.toInt()} XAF / month",
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(f, style: GoogleFonts.outfit(fontSize: 14)),
              ],
            ),
          )),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isCurrent || _isProcessing ? null : () => _handlePurchase(tier, price),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(isCurrent ? "Current Plan" : "Get Unlimited"),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchaseCredits(double amount, int credits, String packName) async {
    final phoneController = TextEditingController();

    final proceed = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: "Buy Credits",
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PremiumDialogHeader(
                    title: "Buy $packName",
                    subtitle: "Add $credits credits to your balance",
                    icon: Icons.bolt_rounded,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          "Enter your MoMo/OM number to pay ${amount.toInt()} XAF.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 14),
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
                          child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.redAccent)),
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
      _processCreditPurchase(amount, credits, phoneController.text.trim());
    }
  }

  Future<void> _processCreditPurchase(double amount, int credits, String phone) async {
    setState(() => _isProcessing = true);

    try {
      final response = await FapshiService.collectPayment(
        amount: amount,
        phoneNumber: FapshiService.formatPhoneNumber(phone),
        description: "AI Credit Top-up ($credits credits)",
      );

      final paymentId = response['paymentId'];
      final redirectUrl = response['redirectUrl'];

      if (redirectUrl != null) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          setState(() => _statusMessage = "Complete payment in browser...");
        } else {
          throw "Could not open payment link";
        }
      } else {
        setState(() => _statusMessage = "Waiting for approval...");
      }

      final status = await FapshiService.waitForSuccessfulPayment(
        paymentId,
        onStatusUpdate: (msg) => setState(() => _statusMessage = msg),
      );

      if (status == PaymentStatus.success) {
        await _db.addAICredits(credits);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$credits credits added successfully!")),
          );
        }
      } else {
        throw "Payment was not successful";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
      }
    }
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
      final response = await FapshiService.collectPayment(
        amount: amount,
        phoneNumber: FapshiService.formatPhoneNumber(phone),
        description: "${SubscriptionService.getTierName(tier)} Subscription",
      );

      final paymentId = response['paymentId'] ?? response['id'];
      final redirectUrl = response['redirectUrl'];

      if (redirectUrl != null) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          setState(() => _statusMessage = "Complete payment in the browser window.\n\nTip: Stay on the Fapshi page until the USSD prompt appears on your phone.");
        } else {
          throw "Could not open payment link";
        }
      } else {
        setState(() => _statusMessage = "Check your phone for a MoMo prompt.\n\nMTN: Keep screen unlocked.\nOrange: Dial #150*50# if prompted for an OTP.");
      }

      final status = await FapshiService.waitForSuccessfulPayment(
        paymentId,
        onStatusUpdate: (msg) => setState(() => _statusMessage = msg),
      );

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
      final response = await FapshiService.collectPayment(
        amount: 5000.0,
        phoneNumber: FapshiService.formatPhoneNumber(phone),
        description: "Contributor Upgrade",
      );

      final paymentId = response['paymentId'] ?? response['id'];
      final redirectUrl = response['redirectUrl'];

      if (redirectUrl != null) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          setState(() => _statusMessage = "Complete payment in the browser window.\n\nTip: Stay on the Fapshi page until the USSD prompt appears on your phone.");
        } else {
          throw "Could not open payment link";
        }
      } else {
        setState(() => _statusMessage = "Check your phone for a MoMo prompt.\n\nMTN: Keep screen unlocked.\nOrange: Dial #150*50# if prompted for an OTP.");
      }

      final status = await FapshiService.waitForSuccessfulPayment(
        paymentId,
        onStatusUpdate: (msg) => setState(() => _statusMessage = msg),
      );

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
