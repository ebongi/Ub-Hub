import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/course_material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_study/Screens/Shared/shimmer_loading.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/services/nkwa_service.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:go_study/services/profile.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late final DatabaseService _dbService;
  final _currentUser = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _currentUser?.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view your marketplace.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Marketplace",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _dbService = DatabaseService(uid: _currentUser.id);
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEarningsCard(colorScheme),
              const SizedBox(height: 30),
              Text(
                "Your Contributions",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildMaterialsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsCard(ColorScheme colorScheme) {
    return StreamBuilder<double>(
      stream: _dbService.getEarningsForUploader(_currentUser!.id),
      builder: (context, snapshot) {
        final earnings = snapshot.data ?? 0.0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Available Balance",
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${earnings.toInt()} XAF",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: earnings >= 100 ? () => _showWithdrawDialog(earnings) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  earnings >= 100 ? "Withdraw Earnings" : "Min. 100 XAF to withdraw",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaterialsList() {
    return StreamBuilder<List<CourseMaterial>>(
      stream: _dbService.getUserUploadedMaterials(_currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialListShimmer();
        }
        final materials = snapshot.data ?? [];
        if (materials.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file_rounded,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "You haven't uploaded any materials yet.",
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: materials.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final material = materials[index];
            return FadeInSlide(
              delay: index * 0.05,
              child: ScaleButton(
                onTap: () {
                  // Handle tap if needed, or maybe it's just for effect
                },
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      material.title,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Uploaded: ${DateFormat('MMM d, yyyy').format(material.uploadedAt)}",
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    trailing: Text(
                      material.materialCategory
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showWithdrawDialog(double amount) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isProcessing = false;

    // First fetch user profile to get phone number
    late UserProfile profile;
    try {
      profile = await _dbService.userProfile.first;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching profile: $e")),
        );
      }
      return;
    }

    if (profile.phoneNumber == null || profile.phoneNumber!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please add a phone number to your profile first."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    await showPremiumGeneralDialog(
      context: context,
      barrierLabel: "Withdrawal",
      child: StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          surfaceTintColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PremiumDialogHeader(
                title: "Withdraw Earnings",
                subtitle: "Automated direct payout",
                icon: Icons.account_balance_wallet_rounded,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "You are about to withdraw",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${amount.toInt()} XAF",
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_android_rounded,
                                size: 16,
                                color:
                                    isDark ? Colors.white54 : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Recipient: ${profile.phoneNumber}",
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Funds will be sent automatically via Nkwa Pay to your registered mobile money account.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed:
                                isProcessing ? null : () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.outfit(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PremiumSubmitButton(
                            label: "Confirm & Payout",
                            isLoading: isProcessing,
                            onPressed: () async {
                              setState(() => isProcessing = true);
                              try {
                                await _processPayout(
                                    amount, profile.phoneNumber!);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Payout successful! 🎉"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => isProcessing = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Payout failed: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayout(double amount, String phoneNumber) async {
    final userId = _currentUser?.id;
    if (userId == null) throw "User not authenticated";

    final paymentRef = 'PO_${DateTime.now().millisecondsSinceEpoch}';
    final formattedPhone = NkwaService.formatPhoneNumber(phoneNumber);

    // 1. Create pending transaction record
    final transaction = PaymentTransaction(
      id: '',
      userId: userId,
      paymentRef: paymentRef,
      amount: amount,
      currency: NkwaService.getCurrency(),
      status: PaymentStatus.pending,
      itemType: 'payout',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _dbService.createPaymentTransaction(transaction);

    // 2. Initiate Disburse
    final disburseResponse = await NkwaService.disbursePayment(
      amount: amount,
      phoneNumber: formattedPhone,
      description: 'Earnings Withdrawal: $userId',
    );

    final nkwaPaymentId = disburseResponse['id'];

    if (nkwaPaymentId == null) {
      throw "Failed to initiate payout: No payment ID returned.";
    }

    // 3. Poll for status (Disbursements are usually quick but could be pending)
    PaymentStatus status = PaymentStatus.pending;
    int attempts = 0;
    while (status == PaymentStatus.pending && attempts < 20) {
      await Future.delayed(const Duration(seconds: 3));
      status = await NkwaService.checkPaymentStatus(nkwaPaymentId.toString());
      attempts++;
    }

    // 4. Update the record
    await _dbService.updatePaymentStatus(paymentRef, status);

    if (status != PaymentStatus.success) {
      throw "Payout failed or is still processing. Status: ${status.name}";
    }
  }
}
