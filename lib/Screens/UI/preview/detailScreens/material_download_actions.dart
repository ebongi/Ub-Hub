import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/pdf_viewer_screen.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/course_material.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/fapshi_service.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/services/storage_service.dart';
import 'package:go_study/services/subscription_service.dart';

/// Opens a material — a PDF is shown in-app via [PDFViewerScreen], anything
/// else falls through to [handleMaterialDownload]. Shared across
/// `DepartmentScreen`, `CourseDetailScreen`, and `SubjectScreen` so the
/// (payment-gated) download flow lives in exactly one place.
Future<void> openMaterialFile({
  required BuildContext context,
  required DatabaseService dbService,
  required UserProfile? userProfile,
  required CourseMaterial material,
}) async {
  if (material.fileType.toLowerCase() == 'pdf') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PDFViewerScreen(url: material.fileUrl, title: material.title),
      ),
    );
    return;
  }
  await handleMaterialDownload(
    context: context,
    dbService: dbService,
    userProfile: userProfile,
    material: material,
  );
}

/// Downloads (or, once paid, opens) a material. Free-download-eligible
/// users go straight through; everyone else sees a Fapshi payment dialog
/// first. `UserProfile.hasUnlimitedDownloads` is currently hardcoded `true`
/// ("free community beta"), so the payment branch is effectively dormant at
/// runtime today — kept intact so it activates correctly the moment that
/// changes, rather than being silently dropped.
Future<void> handleMaterialDownload({
  required BuildContext context,
  required DatabaseService dbService,
  required UserProfile? userProfile,
  required CourseMaterial material,
}) async {
  final l10n = AppLocalizations.of(context)!;
  if (userProfile != null && SubscriptionService.canDownloadForFree(userProfile)) {
    await _secureForOffline(context: context, material: material);
    if (!userProfile.hasUnlimitedDownloads) {
      await dbService.incrementFreeDownloadCount();
    }
    final uri = Uri.parse(material.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch download link")),
        );
      }
    }
    return;
  }

  final phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isProcessing = false;

  double fee = material.price;
  if (fee <= 0) {
    fee = FapshiService.getDocumentDownloadFee();
    if (material.materialCategory == 'past_question') {
      fee = FapshiService.getPastQuestionDownloadFee();
    } else if (material.materialCategory == 'answer') {
      fee = FapshiService.getAnswerDownloadFee();
    }
  }

  await showPremiumGeneralDialog(
    context: context,
    barrierLabel: l10n.downloadTooltip,
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            surfaceTintColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumDialogHeader(
                  title: l10n.downloadMaterialTitle,
                  subtitle: l10n.secureAccessSubtitle,
                  icon: Icons.download_for_offline_rounded,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : theme.colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            l10n.downloadFeeNotice(
                              material.title,
                              material.materialCategory.replaceAll('_', ' '),
                              fee.toInt(),
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              height: 1.5,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PremiumTextField(
                          controller: phoneController,
                          label: l10n.paymentPhoneLabel,
                          hint: l10n.paymentPhoneHint,
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          enabled: !isProcessing,
                          validator: (v) =>
                              v == null || v.isEmpty ? l10n.requiredValidator : null,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed:
                                    isProcessing ? null : () => Navigator.pop(context),
                                child: Text(
                                  l10n.cancel,
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
                                label: l10n.payAndDownloadButton,
                                isLoading: isProcessing,
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setState(() => isProcessing = true);
                                  try {
                                    await _processDownloadPayment(
                                      context: context,
                                      dbService: dbService,
                                      material: material,
                                      phoneNumber: phoneController.text,
                                    );
                                    if (context.mounted) Navigator.pop(context);
                                  } catch (e) {
                                    setState(() => isProcessing = false);
                                    if (context.mounted) {
                                      ErrorHandler.showErrorSnackBar(context, e);
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
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _processDownloadPayment({
  required BuildContext context,
  required DatabaseService dbService,
  required CourseMaterial material,
  required String phoneNumber,
}) async {
  final userId = dbService.uid;
  if (userId == null) throw "User not authenticated";

  final paymentRef = FapshiService.generatePaymentRef();
  double amount = material.price;
  if (amount <= 0) {
    amount = FapshiService.getDocumentDownloadFee();
    if (material.materialCategory == 'past_question') {
      amount = FapshiService.getPastQuestionDownloadFee();
    } else if (material.materialCategory == 'answer') {
      amount = FapshiService.getAnswerDownloadFee();
    }
  }
  final formattedPhone = FapshiService.formatPhoneNumber(phoneNumber);

  final transaction = PaymentTransaction(
    id: '',
    userId: userId,
    paymentRef: paymentRef,
    amount: amount,
    currency: FapshiService.getCurrency(),
    status: PaymentStatus.pending,
    materialId: material.id,
    itemType: 'download',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await dbService.createPaymentTransaction(transaction);

  final collectResponse = await FapshiService.collectPayment(
    amount: amount,
    phoneNumber: formattedPhone,
    description: 'Download: ${material.title}',
  );

  final nkwaPaymentId = collectResponse['id'] ?? collectResponse['paymentId'];
  final redirectUrl = collectResponse['redirectUrl'];

  if (nkwaPaymentId == null) throw "Failed to initiate payment";

  await dbService.attachPaymentProviderRef(paymentRef, nkwaPaymentId.toString());

  if (redirectUrl != null) {
    final uri = Uri.parse(redirectUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not open payment link";
    }
  }

  final status = await FapshiService.waitForSuccessfulPayment(nkwaPaymentId.toString());

  if (status != PaymentStatus.success) {
    // The edge function already flips a confirmed payment to 'success'
    // server-side; only non-success outcomes need recording here.
    await dbService.updatePaymentStatus(paymentRef, status, materialId: material.id);
    throw "Payment failed or timed out.";
  }

  await _secureForOffline(context: context, material: material);
  final uri = Uri.parse(material.fileUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch download link';
  }
}

Future<void> _secureForOffline({
  required BuildContext context,
  required CourseMaterial material,
}) async {
  try {
    await StorageService().downloadAndEncrypt(
      material.fileUrl,
      material.id,
      material.fileName,
    );
    if (context.mounted) {
      ErrorHandler.showSuccessSnackBar(
        context,
        AppLocalizations.of(context)!.materialSecuredOfflineMessage,
      );
    }
  } catch (e) {
    debugPrint("Offline cache failed: $e");
  }
}
