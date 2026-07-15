import 'package:flutter/material.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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

  final List<String> _modes = [
    'Normal Mode (1200 XAF)',
    'Fast Mode (2500 XAF)',
    'Super Fast Mode (3500 XAF)',
  ];
  final List<String> _statuses = ['Current Student', 'Former Student'];

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Confirm Application",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "You will be redirected to WhatsApp to complete your application with our support team.",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
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
                      const SnackBar(
                        content: Text(
                          "Could not open WhatsApp. Please ensure WhatsApp is installed.",
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              "Continue to WhatsApp",
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Transcript Application",
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
                  const AuthHeader(
                    title: "Apply Now",
                    subtitle:
                        "Fill in the details below to request your academic transcript.",
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Personal Information"),
                  AuthTextField(
                    controller: _nameController,
                    hintText: "Full Name",
                    prefixIcon: Iconsax.user,
                    validator: (v) => v!.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _phoneController,
                    hintText: "WhatsApp Number (e.g. 6xxxxxxxx)",
                    prefixIcon: Iconsax.call,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v!.length < 9) ? "Enter a valid phone number" : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _emailController,
                    hintText: "Email Address",
                    prefixIcon: Iconsax.sms,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v!)
                        ? "Enter a valid email"
                        : null,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Academic Details"),
                  AuthTextField(
                    controller: _matriculeController,
                    hintText: "Matricule Number",
                    prefixIcon: Iconsax.card,
                    validator: (v) => v!.isEmpty ? "Enter your matricule" : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _facultyController,
                    hintText: "Faculty",
                    prefixIcon: Iconsax.bank,
                    validator: (v) => v!.isEmpty ? "Enter your faculty" : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _departmentController,
                    hintText: "Department",
                    prefixIcon: Iconsax.hierarchy,
                    validator: (v) => v!.isEmpty ? "Enter your department" : null,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Application Options"),
                  AuthDropdown(
                    value: _modeOfApplication,
                    hintText: "Mode of Application",
                    prefixIcon: Iconsax.speedometer,
                    items: _modes,
                    onChanged: (val) => setState(() => _modeOfApplication = val ?? ''),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Select a mode" : null,
                  ),
                  const SizedBox(height: 16),
                  AuthDropdown(
                    value: _status,
                    hintText: "Student Status",
                    prefixIcon: Iconsax.user_tag,
                    items: _statuses,
                    onChanged: (val) => setState(() => _status = val ?? ''),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Select your status" : null,
                  ),
                  const SizedBox(height: 40),
                  AuthButton(
                    label: "Submit Application",
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
