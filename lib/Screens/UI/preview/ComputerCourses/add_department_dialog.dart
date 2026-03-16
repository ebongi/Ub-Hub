import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';
import 'package:go_study/services/nkwa_service.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

Future<void> showAddDepartmentDialog(
  BuildContext context, {
  String? defaultSchoolId,
}) async {
  XFile? imageFile;
  final currentUser = Supabase.instance.client.auth.currentUser;
  final dbService = DatabaseService(uid: currentUser?.id);
  final departname = TextEditingController();
  final schoolid = TextEditingController(text: defaultSchoolId);
  final description = TextEditingController();
  final phoneController = TextEditingController();
  final adddepartmentKey = GlobalKey<FormState>();

  bool isLoading = false;

  await showPremiumGeneralDialog(
    context: context,
    barrierLabel: "Add Department",
    child: StatefulBuilder(
      builder: (context, setDialogState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        Future<void> pickImage() async {
          if (isLoading) return;
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
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Phone required' : null,
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
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pop(context),
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
                        isLoading: isLoading,
                        onPressed: () async {
                          if (!adddepartmentKey.currentState!.validate()) {
                            return;
                          }
                          if (imageFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please upload an image'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);
                          try {
                            final userId = dbService.uid;
                            if (userId == null) throw Exception('Auth Error');

                            final imageBytes = await imageFile!.readAsBytes();
                            final imageUrl = await dbService
                                .uploadDepartmentImage(
                                  imageBytes,
                                  departname.text,
                                );

                            final paymentRef = NkwaService.generatePaymentRef();
                            final amount =
                                NkwaService.getDepartmentCreationFee();
                            final formattedPhone =
                                NkwaService.formatPhoneNumber(
                                  phoneController.text,
                                );

                            await dbService.createPaymentTransaction(
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

                            final collectResponse =
                                await NkwaService.collectPayment(
                                  amount: amount,
                                  phoneNumber: formattedPhone,
                                  description: 'Dept: ${departname.text}',
                                );

                            final nkwaId =
                                collectResponse['id'] ??
                                collectResponse['paymentId'];

                            PaymentStatus status = PaymentStatus.pending;
                            int attempts = 0;
                            while (status == PaymentStatus.pending &&
                                attempts < 60) {
                              await Future.delayed(const Duration(seconds: 3));
                              status = await NkwaService.checkPaymentStatus(
                                nkwaId.toString(),
                              );
                              attempts++;
                            }

                            await dbService.updatePaymentStatus(
                              paymentRef,
                              status,
                            );
                            if (status != PaymentStatus.success) {
                              throw Exception('Payment Incomplete');
                            }

                            final deptId = await dbService.createDepartment(
                              Department(
                                id: '',
                                name: departname.text,
                                schoolId: schoolid.text,
                                description: description.text,
                                imageUrl: imageUrl,
                                createdAt: DateTime.now(),
                              ),
                            );

                            await dbService.updatePaymentStatus(
                              paymentRef,
                              status,
                              departmentId: deptId,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DepartmentScreen(
                                    departmentName: departname.text,
                                    departmentId: deptId,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
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
