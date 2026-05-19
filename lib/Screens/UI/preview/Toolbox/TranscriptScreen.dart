import 'package:flutter/material.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Transcriptscreen extends StatefulWidget {
  const Transcriptscreen({super.key});

  @override
  State<Transcriptscreen> createState() => _TranscriptscreenState();
}

class _TranscriptscreenState extends State<Transcriptscreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  String _modeOfApplication = '';
  String _status = '';

  final List<String> _modes = [
    'Normal Mode(1200XAF)',
    'Fast Mode(2500XAF)',
    'Super Fast Mode(3500XAF)',
  ];
  final List<String> _statuses = ['Current', 'Former'];

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
          "🎓 *NEW TRANSCRIPT APPLICATION* 🎓\n\n"
          "Hi  Go-Study Support, I would like to apply for an academic transcript. Here are my application details:\n\n"
          "📝 *Full Name:* $name\n"
          "📞 *Phone Number:* $phone\n"
          "📧 *Email:* $email\n"
          "🆔 *Matricule:* $matricule\n"
          "🏫 *Faculty:* $faculty\n"
          "📚 *Department:* $department\n"
          "⚡ *Mode of Application:* $_modeOfApplication\n"
          "👤 *Student Status:* $_status\n\n"
          "Please let me know the next steps for processing. Thank you!";

      final String whatsappNumber =
          "237682397481"; // Support contact from developer_info_screen
      final String url =
          "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(messageText)}";
      final Uri uri = Uri.parse(url);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Application Prepared",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Your application details are ready. Tap 'Open WhatsApp' to send them directly to the support team for processing.",
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.outfit(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
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
                "Open WhatsApp",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
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
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuthHeader(
                    title: "Apply Now",
                    subtitle:
                        "Fill in the details below to request your academic transcript.",
                  ),
                  const SizedBox(height: 32),

                  AuthTextField(
                    controller: _nameController,
                    hintText: "Full Name",
                    prefixIcon: Iconsax.user,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your name";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AuthTextField(
                    controller: _phoneController,
                    hintText: "Phone Number (+237...)",
                    prefixIcon: Iconsax.call,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your phone number";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AuthTextField(
                    controller: _emailController,
                    hintText: "Email Address",
                    prefixIcon: Iconsax.sms,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  AuthTextField(
                    controller: _matriculeController,
                    hintText: "Matricule Number",
                    prefixIcon: Iconsax.card,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your matricule";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  AuthTextField(
                    controller: _facultyController,
                    hintText: "Faculty",
                    prefixIcon: Iconsax.bank,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your faculty";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  AuthTextField(
                    controller: _departmentController,
                    hintText: "Department",
                    prefixIcon: Iconsax.hierarchy,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your department";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  AuthDropdown(
                    value: _modeOfApplication,
                    hintText: "Mode of Application",
                    prefixIcon: Iconsax.speedometer,
                    items: _modes,
                    onChanged: (value) {
                      setState(() {
                        _modeOfApplication = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please select a mode";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  AuthDropdown(
                    value: _status,
                    hintText: "Student Status",
                    prefixIcon: Iconsax.user_tag,
                    items: _statuses,
                    onChanged: (value) {
                      setState(() {
                        _status = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please select your status";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  AuthButton(
                    label: "Submit Application",
                    onPressed: _submitForm,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
