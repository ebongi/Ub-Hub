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

                        // Show payment dialog with phone number input
                        final fee = NkwaService.getDepartmentCreationFee();
                        final phoneController = TextEditingController();

                        final paymentData = await showDialog<Map<String, dynamic>>(
                          context: dialogContext,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Payment Required'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Creating a department requires a payment of $fee XAF via Mobile Money.',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    hintText: '237600000000',
                                    prefixIcon: Icon(Icons.phone),
                                    helperText: 'Format: 237XXXXXXXXX',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Phone number is required';
                                    }
                                    if (!NkwaService.isValidPhoneNumber(
                                      value,
                                    )) {
                                      return 'Invalid phone number format';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(
                                      12,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  if (NkwaService.isValidPhoneNumber(
                                    phoneController.text,
                                  )) {
                                    Navigator.pop(ctx, {
                                      'proceed': true,
                                      'phone': NkwaService.formatPhoneNumber(
                                        phoneController.text,
                                      ),
                                    });
                                  }
                                },
                                child: const Text('Proceed to Payment'),
                              ),
                            ],
                          ),
                        );

                        if (paymentData?['proceed'] != true) return;

                        setDialogState(() => isLoading = true);

                        try {
                          // Get user data
                          final userId = dbService.uid;
                          if (userId == null) {
                            throw Exception('User not authenticated');
                          }

                          final phoneNumber = paymentData!['phone'] as String;

                          // Generate payment reference
                          final paymentRef = NkwaService.generatePaymentRef();

                          // Create payment transaction record
                          final transaction = PaymentTransaction(
                            id: '',
                            userId: userId,
                            paymentRef: paymentRef,
                            amount: fee,
                            currency: NkwaService.getCurrency(),
                            status: PaymentStatus.pending,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          await dbService.createPaymentTransaction(transaction);

                          // Collect payment via Nkwa API
                          final paymentResponse =
                              await NkwaService.collectPayment(
                                amount: fee,
                                phoneNumber: phoneNumber,
                                description:
                                    'Department creation: ${departname.text}',
                              );

                          final paymentId = paymentResponse['id'] as String;

                          // Close the form dialog
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (context.mounted) {
                            // Show payment processing dialog
                            await _showNkwaPaymentDialog(
                              context,
                              dbService,
                              paymentRef,
                              paymentId,
                              departname.text,
                              schoolid.text,
                              description.text,
                              imageFile,
                              phoneNumber,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Payment initialization failed: $e',
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

/// Show a dialog to poll Nkwa payment status and create department after successful payment
Future<void> _showNkwaPaymentDialog(
  BuildContext context,
  DatabaseService dbService,
  String paymentRef,
  String paymentId,
  String departmentName,
  String schoolId,
  String description,
  XFile? imageFile,
  String phoneNumber,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _NkwaPaymentStatusDialog(
      dbService: dbService,
      paymentRef: paymentRef,
      paymentId: paymentId,
      departmentName: departmentName,
      schoolId: schoolId,
      description: description,
      imageFile: imageFile,
      phoneNumber: phoneNumber,
    ),
  );
}

class _NkwaPaymentStatusDialog extends StatefulWidget {
  final DatabaseService dbService;
  final String paymentRef;
  final String paymentId;
  final String departmentName;
  final String schoolId;
  final String description;
  final XFile? imageFile;
  final String phoneNumber;

  const _NkwaPaymentStatusDialog({
    required this.dbService,
    required this.paymentRef,
    required this.paymentId,
    required this.departmentName,
    required this.schoolId,
    required this.description,
    this.imageFile,
    required this.phoneNumber,
  });

  @override
  State<_NkwaPaymentStatusDialog> createState() =>
      _NkwaPaymentStatusDialogState();
}

class _NkwaPaymentStatusDialogState extends State<_NkwaPaymentStatusDialog> {
  String _statusMessage = '';
  bool _isChecking = true;
  bool _isSuccess = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    _statusMessage = 'Waiting for confirmation on ${widget.phoneNumber}...';
    _startPolling();
  }

  void _startPolling() async {
    int attempts = 0;
    const maxAttempts = 60; // 2 minutes

    while (attempts < maxAttempts && mounted && _isChecking) {
      try {
        final status = await NkwaService.checkPaymentStatus(widget.paymentId);

        if (status == PaymentStatus.success) {
          if (!mounted) return;
          setState(() {
            _isChecking = false;
            _isSuccess = true;
            _statusMessage = 'Payment successful! Creating department...';
          });

          await _createDepartment();
          return;
        } else if (status == PaymentStatus.failed ||
            status == PaymentStatus.cancelled) {
          if (!mounted) return;
          setState(() {
            _isChecking = false;
            _isFailed = true;
            _statusMessage = 'Payment failed or cancelled.';
          });
          return;
        }

        attempts++;
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Error polling payment status: $e');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (_isChecking && mounted) {
      setState(() {
        _isChecking = false;
        _isFailed = true;
        _statusMessage = 'Payment timeout. Please check SMS or retry.';
      });
    }
  }

  Future<void> _createDepartment() async {
    try {
      String? imageUrl;
      if (widget.imageFile != null) {
        final imageBytes = await widget.imageFile!.readAsBytes();
        imageUrl = await widget.dbService.uploadDepartmentImage(
          imageBytes,
          widget.departmentName,
        );
      }

      final newDepartment = Department(
        id: '',
        name: widget.departmentName,
        schoolId: widget.schoolId,
        description: widget.description,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      final departmentId = await widget.dbService.createDepartment(
        newDepartment,
      );

      await widget.dbService.updatePaymentStatus(
        widget.paymentRef,
        PaymentStatus.success,
        departmentId: departmentId,
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Department "${widget.departmentName}" created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DepartmentScreen(
              departmentName: widget.departmentName,
              departmentId: departmentId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSuccess = false;
          _isFailed = true;
          _statusMessage = 'Failed to create department: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isChecking) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusMessage, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Please check your phone for the authorization prompt.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ] else if (_isSuccess) ...[
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(_statusMessage, textAlign: TextAlign.center),
          ] else ...[
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_statusMessage, textAlign: TextAlign.center),
          ],
        ],
      ),
      actions: [
        if (!_isSuccess)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        if (!_isChecking && !_isSuccess)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isChecking = true;
                _isFailed = false;
                _statusMessage = 'Checking status...';
              });
              _startPolling();
            },
            child: const Text('Retry Check'),
          ),
      ],
    );
  }
}
