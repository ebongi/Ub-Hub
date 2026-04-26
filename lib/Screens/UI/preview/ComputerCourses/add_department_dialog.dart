import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:go_study/services/nkwa_service.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:provider/provider.dart';
import 'package:go_study/core/error_handler.dart';

import 'package:go_study/services/profile.dart';
import 'package:go_study/Screens/Shared/constanst.dart';



Future<void> showAddDepartmentDialog(
  BuildContext context, {
  String? defaultSchoolId,
  void Function(Department)? onOptimisticCreate,
}) async {
  XFile? imageFile;
  final departname = TextEditingController();
  final schoolid = TextEditingController(text: defaultSchoolId);
  final description = TextEditingController();
  final phoneController = TextEditingController();
  final adddepartmentKey = GlobalKey<FormState>();


  await showPremiumGeneralDialog(
    context: context,
    barrierLabel: "Add Department",
    child: StatefulBuilder(
      builder: (context, setDialogState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        Future<void> pickImage() async {
          final picker = ImagePicker();
          final pickedFile = await picker.pickImage(
            source: ImageSource.gallery,
          );
          if (pickedFile != null) {
            setDialogState(() => imageFile = pickedFile);
          }
        }

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
                title: "New Department",
                subtitle: "Expand your academic ecosystem",
                icon: Icons.add_business_rounded,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Form(
                    key: adddepartmentKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PremiumTextField(
                          controller: departname,
                          label: "Department Name",
                          hint: "e.g. Computer Science",
                          icon: Icons.title_rounded,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Name required' : null,
                        ),
                        const SizedBox(height: 18),
                        PremiumTextField(
                          controller: schoolid,
                          label: "School ID",
                          hint: "Identify the parent school",
                          icon: Icons.school_rounded,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'School ID required' : null,
                        ),
                        const SizedBox(height: 18),
                        PremiumTextField(
                          controller: description,
                          label: "Description",
                          hint: "What makes this department unique?",
                          icon: Icons.description_outlined,
                          maxLines: 3,
                          validator: (v) => v?.isEmpty ?? true
                              ? 'Description required'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        PremiumTextField(
                          controller: phoneController,
                          label: "Payment Number",
                          hint: "Mobile Money Number",
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            final userModel = Provider.of<UserModel>(context, listen: false);
                            if (userModel.role == UserRole.admin) return null;
                            return v?.isEmpty ?? true ? 'Phone required' : null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Department Identity",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 140,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black12,
                                width: 1,
                              ),
                            ),
                            child: imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: FutureBuilder<Uint8List>(
                                      future: imageFile!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.5),
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Upload cover photo",
                                        style: GoogleFonts.outfit(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
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
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.outfit(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PremiumSubmitButton(
                        label: "Create Department",
                        isLoading: false,
                        onPressed: () async {
                          if (!(adddepartmentKey.currentState?.validate() ?? false)) return;
                          // 1. Capture data and show optimistic UI
                          final name = departname.text.trim();
                          final descriptionText = description.text.trim();
                          final schoolIdText = schoolid.text.trim();
                          final userModel = Provider.of<UserModel>(context, listen: false);
                          final userId = userModel.uid;
                          final isAdmin = userModel.role == UserRole.admin;

                          if (userId == null) {
                            ErrorHandler.showErrorSnackBar(
                                context, 'User not authenticated');
                            return;
                          }


                          // Construct optimistic department
                          final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
                          final tempDept = Department(
                            id: tempId,
                            name: name,
                            schoolId: schoolIdText,
                            description: descriptionText,
                            imageUrl: null, 
                            adminId: userId,
                            createdAt: DateTime.now(),
                          );

                          // 2. Capture all needed data before popping context
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final backgroundDbService = DatabaseService(uid: userId);

                          // Trigger optimistic update and close dialog
                          onOptimisticCreate?.call(tempDept);
                          Navigator.pop(context);


                          try {
                            String? imageUrl;
                            if (imageFile != null) {
                              final imageBytes = await imageFile!.readAsBytes();
                              imageUrl = await backgroundDbService.uploadDepartmentImage(
                                imageBytes,
                                name,
                              );
                            }

                            String? paymentRef;
                            PaymentStatus status = PaymentStatus.pending;

                            if (!isAdmin) {
                              paymentRef = NkwaService.generatePaymentRef();
                              final amount = NkwaService.getDepartmentCreationFee(role: userModel.role);
                              final formattedPhone = NkwaService.formatPhoneNumber(
                                phoneController.text,
                              );

                              await backgroundDbService.createPaymentTransaction(
                                PaymentTransaction(
                                  id: '',
                                  userId: userId,
                                  paymentRef: paymentRef,
                                  amount: amount,
                                  currency: NkwaService.getCurrency(),
                                  status: PaymentStatus.pending,
                                  itemType: 'department',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                              );

                              final collectResponse = await NkwaService.collectPayment(
                                amount: amount,
                                phoneNumber: formattedPhone,
                                description: 'Dept: $name',
                              );

                              final nkwaId = collectResponse['id'] ?? collectResponse['paymentId'];

                              status = PaymentStatus.pending;
                              int attempts = 0;
                              while (status == PaymentStatus.pending && attempts < 60) {
                                await Future.delayed(const Duration(seconds: 3));
                                status = await NkwaService.checkPaymentStatus(nkwaId.toString());
                                attempts++;
                              }

                              await backgroundDbService.updatePaymentStatus(paymentRef, status);
                              if (status != PaymentStatus.success) {
                                throw Exception('Payment Incomplete');
                              }
                            }

                            final deptId = await backgroundDbService.createDepartment(
                              Department(
                                id: '',
                                name: name,
                                schoolId: schoolIdText,
                                description: descriptionText,
                                imageUrl: imageUrl,
                                adminId: userId,
                                createdAt: DateTime.now(),
                              ),
                            );

                            if (!isAdmin && paymentRef != null) {
                              await backgroundDbService.updatePaymentStatus(
                                paymentRef,
                                status,
                                departmentId: deptId,
                              );
                            }

                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(ErrorHandler.getFriendlyMessage(e)),
                                backgroundColor: const Color(0xFF991B1B),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                            debugPrint("Background Dept Creation Error: $e");
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
