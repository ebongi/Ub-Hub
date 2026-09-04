import 'package:flutter/foundation.dart' show kDebugMode;
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
import 'package:go_study/l10n/generated/app_localizations.dart';
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
  bool _isProcessingTrial = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userModel = Provider.of<UserModel>(context);
    final credits = userModel.aiCredits;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.aiCreditsPlansTitle,
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
                        l10n.currentBalanceLabel,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        l10n.creditsCountLabel(credits),
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
              l10n.topUpAiCreditsTitle,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.creditsUsageSubtitle,
              style: GoogleFonts.outfit(fontSize: 14, color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            // --- FAPSHI SANDBOX TEST MODE (100 XAF) ---
            // Debug-only: this hits Fapshi's sandbox, not a real product
            // tier. Was previously visible to production users too.
            if (kDebugMode)
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
                          l10n.fapshiTestModeLabel,
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
                      l10n.fapshiTestModeBody,
                      style: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _handlePurchaseCredits(100.0, 10, l10n.testCreditsPackTitle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.pay100XafTestButton,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Credit Packs
            _buildCreditPack(
              context,
              title: l10n.starterPackTitle,
              credits: 50,
              price: 500,
              icon: Icons.auto_awesome_outlined,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildCreditPack(
              context,
              title: l10n.studentPackTitle,
              credits: 150,
              price: 1000,
              icon: Icons.rocket_launch_outlined,
              color: Colors.purple,
              isRecommended: true,
            ),
            const SizedBox(height: 32),
            Text(
              l10n.unlimitedAiSubscriptionsTitle,
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
              title: l10n.unlimitedMonthlyTitle,
              price: SubscriptionService.aiMonthlyPrice,
              color: Colors.orange,
              isCurrent: userModel.hasUnlimitedAI,
              itemType: 'ai_subscription',
              onSuccess: (ref) => _db.purchaseAISubscription(SubscriptionTier.monthly, paymentRef: ref),
            ),
            const SizedBox(height: 16),
            _buildTierCard(
              context,
              tier: SubscriptionTier.yearly,
              title: l10n.unlimitedYearlyTitle,
              price: SubscriptionService.aiYearlyPrice,
              color: Colors.deepOrange,
              isCurrent: userModel.hasUnlimitedAI,
              itemType: 'ai_subscription',
              onSuccess: (ref) => _db.purchaseAISubscription(SubscriptionTier.yearly, paymentRef: ref),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.appPlanTitle,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appPlanSubtitle,
              style: GoogleFonts.outfit(fontSize: 14, color: theme.hintColor),
            ),
            const SizedBox(height: 16),
            _buildAppPlanCard(context, userModel),
            const SizedBox(height: 16),
            _buildAppPlanYearlyCard(context, userModel),
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
    final l10n = AppLocalizations.of(context)!;
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
                    l10n.mostPopularLabel,
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
                  l10n.creditsCountAiLabel(credits),
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
    required String itemType,
    required Future<void> Function(String paymentRef) onSuccess,
    List<String>? features,
    bool isPremium = false,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    features ??= [
      l10n.featureUnlimitedGeminiChat,
      l10n.featureUnlimitedPdfSummaries,
      l10n.featurePriorityAiResponse,
      l10n.featureAiStudyPlanGenerator,
      l10n.featureStructureQuizGenerator,
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
            tier == SubscriptionTier.yearly
                ? l10n.pricePerYearLabel(price.toInt())
                : l10n.pricePerMonthLabel(price.toInt()),
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
            onPressed: isCurrent || _isProcessing
                ? null
                : () => _handlePurchase(tier, price, itemType, onSuccess),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(isCurrent ? l10n.currentPlanButton : l10n.getUnlimitedButton),
          ),
        ],
      ),
    );
  }

  Widget _buildAppPlanCard(BuildContext context, UserModel userModel) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final price = SubscriptionService.monthlyPrice;
    final features = SubscriptionService.getTierFeatures(SubscriptionTier.monthly);

    final isPaidActive = userModel.subscriptionTier == SubscriptionTier.monthly &&
        !userModel.isTrialActive &&
        userModel.subscriptionExpiry != null &&
        userModel.subscriptionExpiry!.isAfter(DateTime.now());

    // Guards against offering a free monthly trial to someone who already
    // pays for the yearly App Plan (their trialUsed can still be false if
    // they bought yearly directly without ever touching the monthly tier).
    final isOnOtherPaidTier = userModel.subscriptionTier == SubscriptionTier.yearly &&
        userModel.subscriptionExpiry != null &&
        userModel.subscriptionExpiry!.isAfter(DateTime.now());

    String? badgeText;
    Color badgeColor = theme.colorScheme.primary;
    Widget actionButton;

    if (userModel.isTrialActive) {
      badgeText = l10n.trialActiveLeftBadge(userModel.trialTimeLeft(l10n));
      badgeColor = Colors.teal;
      actionButton = const SizedBox.shrink();
    } else if (isPaidActive) {
      badgeText = l10n.currentPlanBadge;
      actionButton = const SizedBox.shrink();
    } else if (!userModel.trialUsed && !isOnOtherPaidTier) {
      badgeText = l10n.firstMonthFreeBadge;
      badgeColor = Colors.green;
      actionButton = ElevatedButton(
        onPressed: _isProcessingTrial ? null : _handleStartTrial,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isProcessingTrial
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(l10n.startFreeTrialButton),
      );
    } else {
      actionButton = ElevatedButton(
        onPressed: _isProcessing
            ? null
            : () => _handlePurchase(
                  SubscriptionTier.monthly,
                  price,
                  'app_plan_subscription',
                  (ref) => _db.upgradeSubscription(SubscriptionTier.monthly, paymentRef: ref),
                ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(l10n.subscribeButton),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badgeText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.outfit(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            userModel.trialUsed || isPaidActive || userModel.isTrialActive
                ? l10n.pricePerMonthLabel(price.toInt())
                : l10n.freeMonthThenPriceLabel(price.toInt()),
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.aiFeaturesBilledSeparatelyShort,
            style: GoogleFonts.outfit(fontSize: 12, color: theme.hintColor),
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
          actionButton,
        ],
      ),
    );
  }

  Widget _buildAppPlanYearlyCard(BuildContext context, UserModel userModel) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final price = SubscriptionService.yearlyPrice;
    final features = SubscriptionService.getTierFeatures(SubscriptionTier.yearly);

    final isPaidActive = userModel.subscriptionTier == SubscriptionTier.yearly &&
        !userModel.isTrialActive &&
        userModel.subscriptionExpiry != null &&
        userModel.subscriptionExpiry!.isAfter(DateTime.now());

    final actionButton = isPaidActive
        ? const SizedBox.shrink()
        : ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () => _handlePurchase(
                      SubscriptionTier.yearly,
                      price,
                      'app_plan_subscription',
                      (ref) => _db.upgradeSubscription(SubscriptionTier.yearly, paymentRef: ref),
                    ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(l10n.subscribeButton),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.unlimitedYearlyTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: theme.hintColor),
          ),
          const SizedBox(height: 8),
          if (isPaidActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.currentPlanBadge,
                style: GoogleFonts.outfit(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            l10n.pricePerYearLabel(price.toInt()),
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.aiFeaturesBilledSeparatelyShort,
            style: GoogleFonts.outfit(fontSize: 12, color: theme.hintColor),
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
          actionButton,
        ],
      ),
    );
  }

  Future<void> _handleStartTrial() async {
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: l10n.startFreeTrialButton,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            surfaceTintColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PremiumDialogHeader(
                    title: l10n.startYourFreeMonthTitle,
                    subtitle: l10n.noPaymentRequiredTodaySubtitle,
                    icon: Icons.card_giftcard_rounded,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          l10n.freeTrialTermsBody(SubscriptionService.monthlyPrice.toInt()),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        PremiumSubmitButton(
                          label: l10n.startFreeTrialButton,
                          isLoading: false,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            l10n.cancel,
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

    if (proceed != true) return;

    setState(() => _isProcessingTrial = true);
    try {
      await _db.startFreeMonthlyTrial();
      if (mounted) {
        // Reflect the new trial state immediately instead of waiting on the
        // realtime profile stream, so the button disappears right away.
        Provider.of<UserModel>(context, listen: false).update(
          subscriptionTier: SubscriptionTier.monthly,
          subscriptionExpiry: DateTime.now().add(const Duration(days: 30)),
          trialUsed: true,
          isTrialSubscription: true,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.freeTrialActivatedMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessingTrial = false);
    }
  }

  Future<void> _handlePurchaseCredits(double amount, int credits, String packName) async {
    final phoneController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    final proceed = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: l10n.buyCreditsBarrierLabel,
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
                    title: l10n.buyPackTitle(packName),
                    subtitle: l10n.addCreditsToBalanceSubtitle(credits),
                    icon: Icons.bolt_rounded,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          l10n.enterMomoNumberToPayBody(amount.toInt()),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        PremiumTextField(
                          controller: phoneController,
                          label: l10n.phoneNumberLabel,
                          hint: l10n.phoneNumberHintUppercase,
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 32),
                        PremiumSubmitButton(
                          label: l10n.payNowButton,
                          isLoading: false,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel, style: GoogleFonts.outfit(color: Colors.redAccent)),
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
    final l10n = AppLocalizations.of(context)!;
    final userId = _db.uid;

    try {
      if (userId == null) throw "User not authenticated";

      final paymentRef = FapshiService.generatePaymentRef();
      await _db.createPaymentTransaction(PaymentTransaction(
        id: '',
        userId: userId,
        paymentRef: paymentRef,
        amount: amount,
        currency: FapshiService.getCurrency(),
        status: PaymentStatus.pending,
        itemType: 'ai_credits',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final response = await FapshiService.collectPayment(
        amount: amount,
        phoneNumber: FapshiService.formatPhoneNumber(phone),
        description: "AI Credit Top-up ($credits credits)",
      );

      final paymentId = response['paymentId'];
      final redirectUrl = response['redirectUrl'];
      if (paymentId == null) throw "Failed to initiate payment";

      await _db.attachPaymentProviderRef(paymentRef, paymentId.toString());

      if (redirectUrl != null) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw "Could not open payment link";
        }
      }

      final status = await FapshiService.waitForSuccessfulPayment(paymentId);

      if (status == PaymentStatus.success) {
        await _db.addAICredits(credits, paymentRef: paymentRef);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.creditsAddedSuccessfullyMessage(credits))),
          );
        }
      } else {
        // The edge function already flips a confirmed payment to 'success'
        // server-side; only non-success outcomes need recording here.
        await _db.updatePaymentStatus(paymentRef, status);
        throw "Payment was not successful";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handlePurchase(
    SubscriptionTier tier,
    double amount,
    String itemType,
    Future<void> Function(String paymentRef) onSuccess,
  ) async {
    final phoneController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    final proceed = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: l10n.subscribeButton,
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
                    title: l10n.subscribeToTierTitle(SubscriptionService.getTierName(tier)),
                    subtitle: l10n.unlockPremiumToolsSubtitle,
                    icon: Icons.workspace_premium_rounded,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          l10n.enterMomoForDaysBody(amount.toInt(), tier == SubscriptionTier.monthly ? 30 : 365),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PremiumTextField(
                          controller: phoneController,
                          label: l10n.phoneNumberLabel,
                          hint: l10n.phoneNumberHintUppercase,
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 32),
                        PremiumSubmitButton(
                          label: l10n.payNowButton,
                          isLoading: false,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            l10n.cancel,
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
      _processPayment(tier, amount, itemType, phoneController.text.trim(), onSuccess);
    }
  }

  Future<void> _processPayment(
    SubscriptionTier tier,
    double amount,
    String itemType,
    String phone,
    Future<void> Function(String paymentRef) onSuccess,
  ) async {
    setState(() {
      _isProcessing = true;
      _processingTier = tier;
    });
    final l10n = AppLocalizations.of(context)!;
    final userId = _db.uid;

    try {
      if (userId == null) throw "User not authenticated";

      final paymentRef = FapshiService.generatePaymentRef();
      await _db.createPaymentTransaction(PaymentTransaction(
        id: '',
        userId: userId,
        paymentRef: paymentRef,
        amount: amount,
        currency: FapshiService.getCurrency(),
        status: PaymentStatus.pending,
        itemType: itemType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final response = await FapshiService.collectPayment(
        amount: amount,
        phoneNumber: FapshiService.formatPhoneNumber(phone),
        description: "${SubscriptionService.getTierName(tier)} Subscription",
      );

      final paymentId = response['paymentId'] ?? response['id'];
      final redirectUrl = response['redirectUrl'];
      if (paymentId == null) throw "Failed to initiate payment";

      await _db.attachPaymentProviderRef(paymentRef, paymentId.toString());

      if (redirectUrl != null) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw "Could not open payment link";
        }
      }

      final status = await FapshiService.waitForSuccessfulPayment(paymentId);

      if (status == PaymentStatus.success) {
        await onSuccess(paymentRef);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.subscriptionActivatedMessage)),
          );
          Navigator.pop(context);
        }
      } else {
        // The edge function already flips a confirmed payment to 'success'
        // server-side; only non-success outcomes need recording here.
        await _db.updatePaymentStatus(paymentRef, status);
        if (status == PaymentStatus.cancelled) {
          throw "Payment was cancelled";
        }
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
        });
      }
    }
  }

}
