import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/fapshi_service.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showSupportDialog(BuildContext context) async {
  final amountController = TextEditingController();
  final phoneController = TextEditingController();
  final supportKey = GlobalKey<FormState>();

  // Get current user details
  final currentUser = Supabase.instance.client.auth.currentUser;
  final dbService = DatabaseService(uid: currentUser?.id);

  bool isLoading = false;
  final l10n = AppLocalizations.of(context)!;

  await showPremiumGeneralDialog(
    context: context,
    barrierLabel: l10n.supportDeveloperBarrierLabel,
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
              PremiumDialogHeader(
                title: l10n.supportTheDeveloperTitle,
                subtitle: l10n.helpKeepProjectAliveSubtitle,
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
                          l10n.supportDialogBody,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PremiumTextField(
                          controller: amountController,
                          label: l10n.amountXafLabel,
                          hint: l10n.amountHintExample,
                          icon: Icons.money_rounded,
                          keyboardType: TextInputType.number,
                          enabled: !isLoading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterAmount;
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return l10n.pleaseEnterValidAmount;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        PremiumTextField(
                          controller: phoneController,
                          label: l10n.paymentPhoneLabel,
                          hint: l10n.phoneNumberHintPlain,
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          enabled: !isLoading,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.phoneNumberRequired;
                            }
                            if (!FapshiService.isValidPhoneNumber(value)) {
                              return l10n.enterValidCameroonPhone;
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
                        child: Text(l10n.cancel,
                            style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PremiumSubmitButton(
                        label: l10n.supportButton,
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
                            final paymentRef = FapshiService.generatePaymentRef();
                            final formattedPhone =
                                FapshiService.formatPhoneNumber(
                                  phoneController.text,
                                );

                            // 1. Log pending donation
                            await dbService.createPaymentTransaction(
                              PaymentTransaction(
                                id: '',
                                userId: userId,
                                paymentRef: paymentRef,
                                amount: amount,
                                currency: FapshiService.getCurrency(),
                                status: PaymentStatus.pending,
                                itemType: 'donation',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            );

                            // 2. Initiate Payment
                            final collectResponse =
                                await FapshiService.collectPayment(
                                  amount: amount,
                                  phoneNumber: formattedPhone,
                                  description: 'Developer Support Donation',
                                );

                            final nkwaPaymentId =
                                collectResponse['id'] ??
                                collectResponse['paymentId'];
                            final redirectUrl = collectResponse['redirectUrl'];
                            
                            if (nkwaPaymentId == null) {
                              throw Exception('Payment initiation failed');
                            }

                            await dbService.attachPaymentProviderRef(
                              paymentRef,
                              nkwaPaymentId.toString(),
                            );

                            if (redirectUrl != null) {
                              final uri = Uri.parse(redirectUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                setDialogState(() => isLoading = true);
                              } else {
                                throw Exception("Could not open payment link");
                              }
                            }

                            // 3. Poll for status
                            final status = await FapshiService.waitForSuccessfulPayment(
                              nkwaPaymentId.toString(),
                              onStatusUpdate: (msg) {
                                // Potentially update dialog UI if needed, 
                                // but for now just log/debug
                                if (kDebugMode) print(msg);
                              },
                            );

                            if (status != PaymentStatus.success) {
                              // The edge function already flips a confirmed
                              // payment to 'success' server-side; only
                              // non-success outcomes need recording here.
                              await dbService.updatePaymentStatus(
                                paymentRef,
                                status,
                              );
                              throw Exception(
                                'Payment was not successful (Status: ${status.name})',
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.thankYouForSupportMessage,
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
