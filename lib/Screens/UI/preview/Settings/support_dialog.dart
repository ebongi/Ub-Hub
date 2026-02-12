// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/nkwa_service.dart';
import 'package:neo/services/payment_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showSupportDialog(BuildContext context) async {
  final amountController = TextEditingController();
  final phoneController = TextEditingController();
  final supportKey = GlobalKey<FormState>();

  // Get current user details
  final currentUser = Supabase.instance.client.auth.currentUser;
  final dbService = DatabaseService(uid: currentUser?.id);

  bool isLoading = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            title: Column(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: Colors.red.shade400,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  "Support the Developer",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            content: Form(
              key: supportKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Your support helps keep the project alive and growing. Choose any amount to contribute.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: amountController,
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
                      decoration: InputDecoration(
                        labelText: "Amount (XAF)",
                        hintText: "e.g. 500",
                        prefixIcon: const Icon(Icons.money_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
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
                      decoration: InputDecoration(
                        labelText: "Payment Phone",
                        hintText: "6xxxxxxxx",
                        prefixIcon: const Icon(Icons.phone_android_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: "Payment via Nkwa (Mobile Money)",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
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

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (context.mounted) {
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
                            if (context.mounted) {
                              setDialogState(() => isLoading = false);
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Support",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
