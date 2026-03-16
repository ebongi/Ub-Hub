import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/nkwa_service.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

Future<void> showSupportDialog(BuildContext context) async {
  final amountController = TextEditingController();
  final phoneController = TextEditingController();
  final supportKey = GlobalKey<FormState>();

  // Get current user details
  final currentUser = Supabase.instance.client.auth.currentUser;
  final dbService = DatabaseService(uid: currentUser?.id);

  bool isLoading = false;

  await showPremiumGeneralDialog(
    context: context,
    barrierLabel: "Support Developer",
    child: StatefulBuilder(
      builder: (context, setDialogState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          surfaceTintColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PremiumDialogHeader(
                title: "Support the Developer",
                subtitle: "Help keep the project alive and growing",
                icon: Icons.favorite_rounded,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Form(
                    key: supportKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Your support helps us maintain the infrastructure and add new features. Any amount is appreciated! ❤️",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PremiumTextField(
                          controller: amountController,
                          label: "Amount (XAF)",
                          hint: "e.g. 500",
                          icon: Icons.money_rounded,
                          keyboardType: TextInputType.number,
                          enabled: !isLoading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        PremiumTextField(
                          controller: phoneController,
                          label: "Payment Phone",
                          hint: "6xxxxxxxx",
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          enabled: !isLoading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Phone number required';
                            }
                            if (!NkwaService.isValidPhoneNumber(value)) {
                              return 'Enter a valid Cameroon phone number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        child: Text("Cancel",
                            style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PremiumSubmitButton(
                        label: "Support",
                        isLoading: isLoading,
                        onPressed: () async {
                          if (!supportKey.currentState!.validate()) return;

                          setDialogState(() => isLoading = true);

                          try {
                            final userId = currentUser?.id;
                            if (userId == null) {
                              throw Exception('User not authenticated');
                            }

                            final amount = double.parse(amountController.text);
                            final paymentRef = NkwaService.generatePaymentRef();
                            final formattedPhone =
                                NkwaService.formatPhoneNumber(
                                  phoneController.text,
                                );

                            // 1. Log pending donation
                            await dbService.createPaymentTransaction(
                              PaymentTransaction(
                                id: '',
                                userId: userId,
                                paymentRef: paymentRef,
                                amount: amount,
                                currency: NkwaService.getCurrency(),
                                status: PaymentStatus.pending,
                                itemType: 'donation',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            );

                            // 2. Initiate Payment
                            final collectResponse =
                                await NkwaService.collectPayment(
                                  amount: amount,
                                  phoneNumber: formattedPhone,
                                  description: 'Developer Support Donation',
                                );

                            final nkwaPaymentId =
                                collectResponse['id'] ??
                                collectResponse['paymentId'];
                            if (nkwaPaymentId == null) {
                              throw Exception('Payment initiation failed');
                            }

                            // 3. Poll for status
                            PaymentStatus status = PaymentStatus.pending;
                            int attempts = 0;
                            while (status == PaymentStatus.pending &&
                                attempts < 40) {
                              await Future.delayed(const Duration(seconds: 3));
                              status = await NkwaService.checkPaymentStatus(
                                nkwaPaymentId.toString(),
                              );
                              attempts++;
                            }

                            // 4. Update status
                            await dbService.updatePaymentStatus(
                              paymentRef,
                              status,
                            );

                            if (status != PaymentStatus.success) {
                              throw Exception(
                                'Payment was not successful (Status: ${status.name})',
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Thank you for your generous support! ❤️',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e
                                        .toString()
                                        .replaceAll('Exception:', '')
                                        .trim(),
                                  ),
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
              ),
            ],
          ),
        );
      },
    ),
  );
}
