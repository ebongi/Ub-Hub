import 'package:flutter/material.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:go_study/services/fapshi_service.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/payment_models.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

class TranscriptScreen extends StatefulWidget {
  const TranscriptScreen({super.key});

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _matriculeController;
  late TextEditingController _otherFacultyController;
  late TextEditingController _departmentController;

  String _modeOfApplication = '';
  String _status = '';
  String _faculty = '';

  final DatabaseService _db = DatabaseService(uid: Authentication().currentUser?.id);
  bool _isProcessing = false;
  static const List<double> _modePrices = [1200.0, 2500.0, 3500.0]; // positional match with _modes(l10n)

  // Official Faculties & Schools per ubuea.cm/index.php/faculties-schools —
  // kept as fixed English names (not localized) since this is what gets
  // relayed verbatim to the transcript office, regardless of app locale.
  static const List<String> _facultyOptions = [
    'Faculty of Arts',
    'Faculty of Science',
    'Faculty of Education',
    'Faculty of Health Sciences',
    'Faculty of Engineering and Technology (FET)',
    'Faculty of Laws and Political Science',
    'Faculty of Social and Management Sciences',
    'Faculty of Agriculture and Veterinary Medicine',
    'College of Technology (COT)',
    'Advanced School of Translators and Interpreters (ASTI)',
    'Higher Technical Teachers Training College (HTTTC)',
    'Higher Teachers Training College (HTTC)',
  ];

  List<String> _modes(AppLocalizations l10n) => [
        l10n.modeNormal,
        l10n.modeFast,
        l10n.modeSuperFast,
      ];
  List<String> _statuses(AppLocalizations l10n) => [
        l10n.statusCurrentStudent,
        l10n.statusFormerStudent,
      ];
  List<String> _faculties(AppLocalizations l10n) => [
        ..._facultyOptions,
        l10n.facultyOtherOption,
      ];

  @override
  void initState() {
    super.initState();
    // Pre-fill data from UserModel if available
    final user = Provider.of<UserModel>(context, listen: false);
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _emailController = TextEditingController(text: user.email);
    _matriculeController = TextEditingController(text: user.matricule);
    _otherFacultyController = TextEditingController();
    _departmentController = TextEditingController(text: user.department);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _matriculeController.dispose();
    _otherFacultyController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    final deliveryMethod = await _showDeliveryMethodDialog();
    if (deliveryMethod == null) return; // cancelled

    await _showPaymentDialog(_amountForSelectedMode(l10n), deliveryMethod);
  }

  static const double _formerStudentSurcharge = 0.3;

  double _amountForSelectedMode(AppLocalizations l10n) {
    final idx = _modes(l10n).indexOf(_modeOfApplication);
    final base = idx >= 0 ? _modePrices[idx] : _modePrices[0];
    if (_status == l10n.statusFormerStudent) {
      return (base * (1 + _formerStudentSurcharge)).roundToDouble();
    }
    return base;
  }

  Future<String?> _showDeliveryMethodDialog() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String selected = 'pdf';

    return showPremiumGeneralDialog<String>(
      context: context,
      barrierLabel: l10n.chooseDeliveryMethodTitle,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
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
                    title: l10n.chooseDeliveryMethodTitle,
                    subtitle: l10n.chooseDeliveryMethodSubtitle,
                    icon: Icons.local_shipping_outlined,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'pdf',
                          groupValue: selected,
                          title: Text(
                            l10n.deliveryMethodPdfLabel,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            l10n.deliveryMethodPdfSubtitle,
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          onChanged: (v) => setDialogState(() => selected = v!),
                        ),
                        RadioListTile<String>(
                          value: 'onsite',
                          groupValue: selected,
                          title: Text(
                            l10n.deliveryMethodOnsiteLabel,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            l10n.deliveryMethodOnsiteSubtitle,
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          onChanged: (v) => setDialogState(() => selected = v!),
                        ),
                        const SizedBox(height: 24),
                        PremiumSubmitButton(
                          label: l10n.acceptButton,
                          isLoading: false,
                          onPressed: () => Navigator.pop(context, selected),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
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
  }

  Future<void> _showPaymentDialog(double amount, String deliveryMethod) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phoneController = TextEditingController();

    final proceed = await showPremiumGeneralDialog<bool>(
      context: context,
      barrierLabel: l10n.payNowButton,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
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
                    title: l10n.transcriptApplicationTitle,
                    subtitle: l10n.payToSubmitApplicationSubtitle,
                    icon: Icons.receipt_long_rounded,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          l10n.enterMomoNumberToPayBody(amount.toInt()),
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

    if (proceed == true && phoneController.text.trim().isNotEmpty) {
      await _processPayment(amount, deliveryMethod, phoneController.text.trim());
    }
  }

  Future<void> _processPayment(double amount, String deliveryMethod, String phone) async {
    setState(() => _isProcessing = true);

    try {
      final userId = _db.uid;
      if (userId == null) throw "User not authenticated";

      final paymentRef = FapshiService.generatePaymentRef();
      final transaction = PaymentTransaction(
        id: '',
        userId: userId,
        paymentRef: paymentRef,
        amount: amount,
        currency: FapshiService.getCurrency(),
        status: PaymentStatus.pending,
        itemType: 'transcript',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _db.createPaymentTransaction(transaction);

      final response = await FapshiService.collectPayment(
        amount: amount,
        phoneNumber: FapshiService.formatPhoneNumber(phone),
        description: 'Transcript Application ($_modeOfApplication, $deliveryMethod)',
      );

      final paymentId = response['id'] ?? response['paymentId'];
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

      final status = await FapshiService.waitForSuccessfulPayment(paymentId.toString());

      if (status != PaymentStatus.success) {
        // The edge function already flips a confirmed payment to 'success'
        // server-side; only non-success outcomes need recording here.
        await _db.updatePaymentStatus(paymentRef, status);
        throw "Payment was not successful";
      }

      await _launchWhatsAppApplication(deliveryMethod);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _launchWhatsAppApplication(String deliveryMethod) async {
    final l10n = AppLocalizations.of(context)!;
    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String email = _emailController.text.trim();
    final String matricule = _matriculeController.text.trim();
    final String faculty = _faculty == l10n.facultyOtherOption
        ? _otherFacultyController.text.trim()
        : _faculty;
    final String department = _departmentController.text.trim();
    final String deliveryLabel = deliveryMethod == 'pdf'
        ? l10n.deliveryMethodPdfLabel
        : l10n.deliveryMethodOnsiteLabel;

    final String messageText =
        "🎓 *NEW TRANSCRIPT APPLICATION* 🎓\n"
        "----------------------------------\n"
        "📝 *Name:* $name\n"
        "📞 *Tel:* $phone\n"
        "📧 *Email:* $email\n"
        "🆔 *Matricule:* ${matricule.toUpperCase()}\n"
        "🏫 *Faculty:* $faculty\n"
        "📚 *Dept:* $department\n"
        "⚡ *Mode:* $_modeOfApplication\n"
        "👤 *Status:* $_status\n"
        "📦 *Delivery:* $deliveryLabel\n"
        "----------------------------------\n"
        "Please process my application. Thank you!";

    final String whatsappNumber = "237682397481";
    final Uri uri = Uri.parse(
      "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(messageText)}",
    );

    try {
      // Direct launch bypasses canLaunchUrl's package visibility constraints in newer OS versions
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.applicationSubmittedMessage)),
        );
      }
    } catch (e) {
      try {
        await launchUrl(uri);
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.couldNotOpenWhatsappMessage)),
          );
        }
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.transcriptApplicationTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthHeader(
                    title: l10n.applyNowTitle,
                    subtitle: l10n.requestTranscriptSubtitle,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(l10n.personalInformationSectionTitle),
                  AuthTextField(
                    controller: _nameController,
                    hintText: l10n.fullNameHint,
                    prefixIcon: Iconsax.user,
                    validator: (v) => v!.isEmpty ? l10n.enterYourNameValidator : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _phoneController,
                    hintText: l10n.whatsappNumberHint,
                    prefixIcon: Iconsax.call,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v!.length < 9) ? l10n.enterValidPhoneValidator : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _emailController,
                    hintText: l10n.emailAddressHint,
                    prefixIcon: Iconsax.sms,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v!)
                        ? l10n.enterValidEmailValidator
                        : null,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(l10n.academicDetailsSectionTitle),
                  AuthTextField(
                    controller: _matriculeController,
                    hintText: l10n.matriculeNumberHint,
                    prefixIcon: Iconsax.card,
                    validator: (v) => v!.isEmpty ? l10n.enterYourMatriculeValidator : null,
                  ),
                  const SizedBox(height: 16),
                  AuthDropdown(
                    value: _faculty,
                    hintText: l10n.facultyHint,
                    prefixIcon: Iconsax.bank,
                    items: _faculties(l10n),
                    onChanged: (val) => setState(() => _faculty = val ?? ''),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.selectYourFacultyValidator : null,
                  ),
                  if (_faculty == l10n.facultyOtherOption) ...[
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _otherFacultyController,
                      hintText: l10n.otherFacultyHint,
                      prefixIcon: Iconsax.bank,
                      validator: (v) =>
                          v!.trim().isEmpty ? l10n.enterYourOtherFacultyValidator : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _departmentController,
                    hintText: l10n.departmentHint,
                    prefixIcon: Iconsax.hierarchy,
                    validator: (v) => v!.isEmpty ? l10n.enterYourDepartmentValidator : null,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(l10n.applicationOptionsSectionTitle),
                  AuthDropdown(
                    value: _modeOfApplication,
                    hintText: l10n.modeOfApplicationHint,
                    prefixIcon: Iconsax.speedometer,
                    items: _modes(l10n),
                    onChanged: (val) => setState(() => _modeOfApplication = val ?? ''),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.selectAModeValidator : null,
                  ),
                  const SizedBox(height: 16),
                  AuthDropdown(
                    value: _status,
                    hintText: l10n.studentStatusHint,
                    prefixIcon: Iconsax.user_tag,
                    items: _statuses(l10n),
                    onChanged: (val) => setState(() => _status = val ?? ''),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.selectYourStatusValidator : null,
                  ),
                  if (_status == l10n.statusFormerStudent) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.formerStudentSurchargeNotice,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDarkMode ? Colors.amberAccent : Colors.orange[800],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  AuthButton(
                    label: l10n.submitApplicationButton,
                    isLoading: _isProcessing,
                    onPressed: _submitForm,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
