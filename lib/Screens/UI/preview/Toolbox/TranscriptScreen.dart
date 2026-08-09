import 'package:flutter/material.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

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
  late TextEditingController _facultyController;
  late TextEditingController _departmentController;

  String _modeOfApplication = '';
  String _status = '';

  List<String> _modes(AppLocalizations l10n) => [
        l10n.modeNormal,
        l10n.modeFast,
        l10n.modeSuperFast,
      ];
  List<String> _statuses(AppLocalizations l10n) => [
        l10n.statusCurrentStudent,
        l10n.statusFormerStudent,
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
    _facultyController = TextEditingController(text: user.institutionName);
    _departmentController = TextEditingController(text: user.department);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _matriculeController.dispose();
    _facultyController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text.trim();
      final String phone = _phoneController.text.trim();
      final String email = _emailController.text.trim();
      final String matricule = _matriculeController.text.trim();
      final String faculty = _facultyController.text.trim();
      final String department = _departmentController.text.trim();

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
          "----------------------------------\n"
          "Please process my application. Thank you!";

      final String whatsappNumber = "237682397481";
      final String url =
          "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(messageText)}";
      final Uri uri = Uri.parse(url);

      _showConfirmationDialog(uri);
    }
  }

  void _showConfirmationDialog(Uri uri) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.confirmApplicationTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.redirectToWhatsappBody,
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Direct launch bypasses canLaunchUrl's package visibility constraints in newer OS versions
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                try {
                  await launchUrl(uri);
                } catch (e2) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.couldNotOpenWhatsappMessage,
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              l10n.continueToWhatsappButton,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
                  AuthTextField(
                    controller: _facultyController,
                    hintText: l10n.facultyHint,
                    prefixIcon: Iconsax.bank,
                    validator: (v) => v!.isEmpty ? l10n.enterYourFacultyValidator : null,
                  ),
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
                  const SizedBox(height: 40),
                  AuthButton(
                    label: l10n.submitApplicationButton,
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
