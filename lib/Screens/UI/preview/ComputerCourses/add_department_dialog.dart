// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neo/Screens/UI/preview/detailScreens/department_screen.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/department.dart';
import 'package:neo/services/nkwa_service.dart';
import 'package:neo/services/payment_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showAddDepartmentDialog(BuildContext context) async {
  XFile? imageFile;
  // Get current user ID from Supabase
  final currentUser = Supabase.instance.client.auth.currentUser;
  final dbService = DatabaseService(uid: currentUser?.id);
  final departname = TextEditingController();
  final schoolid = TextEditingController();
  final description = TextEditingController();
  final phoneController = TextEditingController();
  final adddepartmentKey = GlobalKey<FormState>();

  bool isLoading = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickImage() async {
            if (isLoading) return;
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(
              source: ImageSource.gallery,
            );
            if (pickedFile != null) {
              setDialogState(() {
                imageFile = pickedFile;
              });
            }
          }

          return AlertDialog(
            backgroundColor:
                theme.scaffoldBackgroundColor == const Color(0xFF121212)
                ? const Color(0xFF121212)
                : const Color(0xFFF7F8FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 5,
            ),
            contentTextStyle: GoogleFonts.outfit(),
            title: Center(
              child: Text(
                "Add Department",
                style: GoogleFonts.outfit().copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            content: Form(
              key: adddepartmentKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: departname,
                      autofocus: true,
                      enabled: !isLoading,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Department name cannot be empty'
                          : null,
                      decoration: const InputDecoration(
                        hintText: "Deparment name",
                        icon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: schoolid,
                      enabled: !isLoading,
                      validator: (value) => value == null || value.isEmpty
                          ? 'School ID cannot be empty'
                          : null,
                      decoration: const InputDecoration(
                        hintText: "School ID",
                        icon: Icon(Icons.school),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      maxLength: 250,
                      maxLines: 2,
                      expands: false,
                      enabled: !isLoading,
                      controller: description,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Description cannot be empty'
                          : null,
                      decoration: const InputDecoration(
                        hintText:
                            "Enter the description of your department here",
                        icon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required for payment';
                        }
                        // Simple check, service has more robust formatting
                        if (value.length < 9) {
                          return 'Enter a valid Cameroon phone number';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: "Payment Phone (e.g. 6xxxxxxxx)",
                        icon: Icon(Icons.phone_android),
                        helperText: "Fee: 1000 XAF",
                      ),
                    ),
                    const SizedBox(height: 15),
                    imageFile == null
                        ? OutlinedButton.icon(
                            onPressed: isLoading ? null : pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Select Image'),
                          )
                        : Column(
                            children: [
                              FutureBuilder<Uint8List>(
                                future: imageFile!.readAsBytes(),
                                builder: (context, snapshot) => snapshot.hasData
                                    ? Image.memory(
                                        snapshot.data!,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : const SizedBox(
                                        height: 100,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                              ),
                              TextButton(
                                onPressed: isLoading ? null : pickImage,
                                child: const Text('Change Image'),
                              ),
                            ],
                          ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!adddepartmentKey.currentState!.validate()) return;

                        if (imageFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a department image'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isLoading = true);

                        try {
                          // Get user data
                          final userId = dbService.uid;
                          if (userId == null) {
                            throw Exception('User not authenticated');
                          }

                          String? imageUrl;
                          if (imageFile != null) {
                            final imageBytes = await imageFile!.readAsBytes();
                            imageUrl = await dbService.uploadDepartmentImage(
                              imageBytes,
                              departname.text,
                            );
                          }

                          // --- PAYMENT FLOW ---
                          setDialogState(() => isLoading = true);

                          final paymentRef = NkwaService.generatePaymentRef();
                          final amount = NkwaService.getDepartmentCreationFee();
                          final formattedPhone = NkwaService.formatPhoneNumber(
                            phoneController.text,
                          );

                          // 1. Create pending transaction in Supabase
                          final transaction = PaymentTransaction(
                            id: '',
                            userId: userId,
                            paymentRef: paymentRef,
                            amount: amount,
                            currency: NkwaService.getCurrency(),
                            status: PaymentStatus.pending,
                            departmentId: null, // No ID yet
                            itemType: 'department',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          await dbService.createPaymentTransaction(transaction);

                          // 2. Initiate Nkwa Payment
                          final collectResponse =
                              await NkwaService.collectPayment(
                                amount: amount,
                                phoneNumber: formattedPhone,
                                description:
                                    'Payment for Department: ${departname.text}',
                              );

                          final nkwaPaymentId =
                              collectResponse['id'] ??
                              collectResponse['paymentId'];
                          if (nkwaPaymentId == null) {
                            throw Exception(
                              'Failed to get payment ID from Nkwa',
                            );
                          }

                          // 3. Poll for status
                          PaymentStatus status = PaymentStatus.pending;
                          int attempts = 0;
                          while (status == PaymentStatus.pending &&
                              attempts < 60) {
                            print(
                              'Polling department payment attempt ${attempts + 1}/60...',
                            );
                            await Future.delayed(const Duration(seconds: 3));
                            status = await NkwaService.checkPaymentStatus(
                              nkwaPaymentId.toString(),
                            );
                            attempts++;
                          }

                          // 4. Update status in Supabase (initial update, departmentId still null)
                          await dbService.updatePaymentStatus(
                            paymentRef,
                            status,
                            departmentId: null,
                          );

                          if (status != PaymentStatus.success) {
                            throw Exception(
                              'Payment failed or timed out. Please try again.',
                            );
                          }

                          // 5. SUCCESS! Now create the department
                          final newDepartment = Department(
                            id: '',
                            name: departname.text,
                            schoolId: schoolid.text,
                            description: description.text,
                            imageUrl: imageUrl,
                            createdAt: DateTime.now(),
                          );

                          final departmentId = await dbService.createDepartment(
                            newDepartment,
                          );

                          // 6. Final link update: Update the transaction with the new departmentId
                          await dbService.updatePaymentStatus(
                            paymentRef,
                            status,
                            departmentId: departmentId,
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext); // Close dialog
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Department "${departname.text}" created successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DepartmentScreen(
                                  departmentName: departname.text,
                                  departmentId: departmentId,
                                ),
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
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Add"),
              ),
            ],
          );
        },
      );
    },
  );
}
