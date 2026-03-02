import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/Shared/constanst.dart'; // Reusable widgets
import 'package:go_study/services/auth.dart';
import 'package:provider/provider.dart';

class Register extends StatefulWidget {
  const Register({super.key, required this.istoggle});
  final Function istoggle;

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _usernamecontroller = TextEditingController();
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _matriculeController = TextEditingController();
  String _selectedLevel = "";
  final List<String> _levels = ["200", "300", "400", "500", "600", "Resit"];
  final _formkey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  final Authentication _authentication = Authentication();

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  void dispose() {
    _usernamecontroller.dispose();
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    _phoneNumberController.dispose();
    _matriculeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formkey.currentState?.validate() ?? false) {
      if (_currentStep < _totalSteps - 1) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitForm();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;

    if (_formkey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final user = await _authentication.createUserWithEmailAndPassword(
          email: _emailcontroller.text.trim(),
          password: _passwordcontroller.text.trim(),
          name: _usernamecontroller.text.trim(),
          matricule: _matriculeController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          level: _selectedLevel,
        );

        if (user != null && mounted) {
          Provider.of<UserModel>(
            context,
            listen: false,
          ).setName(_usernamecontroller.text.trim());
          Navigator.of(context).pop();
        }
      } on sb.AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              content: Text(e.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              content: const Text("An unexpected error occurred"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Form(
                  key: _formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthHeader(
                        title: _getStepTitle(),
                        subtitle: _getStepSubtitle(),
                      ),
                      const SizedBox(height: 40),
                      _buildProgressBar(theme),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 350, // Fixed height for form area
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStep1(theme),
                            _buildStep2(theme),
                            _buildStep3(theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildNavigationButtons(theme),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return "Account Details";
      case 1:
        return "Personal Info";
      case 2:
        return "Academic Info";
      default:
        return "Create Account";
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return "Let's start with your email and password.";
      case 1:
        return "Tell us more about yourself.";
      case 2:
        return "Finally, enter your university details.";
      default:
        return "Sign up to get started.";
    }
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? (theme.brightness == Brightness.dark
                        ? Colors.cyanAccent
                        : theme.colorScheme.primary)
                  : theme.dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Column(
      children: [
        AuthTextField(
          controller: _emailcontroller,
          hintText: "Email Address",
          prefixIcon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (email) {
            if (email == null || email.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        AuthTextField(
          controller: _passwordcontroller,
          hintText: "Password",
          prefixIcon: Icons.lock_rounded,
          obscureText: _isPasswordObscured,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() => _isPasswordObscured = !_isPasswordObscured);
            },
            icon: Icon(
              _isPasswordObscured
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: theme.brightness == Brightness.dark
                  ? Colors.cyanAccent
                  : theme.colorScheme.primary,
            ),
          ),
          validator: (password) => password == null || password.length < 6
              ? 'Password must be at least 6 characters'
              : null,
        ),
      ],
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Column(
      children: [
        AuthTextField(
          controller: _usernamecontroller,
          hintText: "Full Name",
          prefixIcon: Icons.person_rounded,
          validator: (name) =>
              name == null || name.isEmpty ? 'Full Name is required' : null,
        ),
        const SizedBox(height: 20),
        AuthTextField(
          controller: _phoneNumberController,
          hintText: "Phone Number",
          prefixIcon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          validator: (phone) => phone == null || phone.isEmpty
              ? 'Phone number is required'
              : null,
        ),
      ],
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return Column(
      children: [
        AuthTextField(
          controller: _matriculeController,
          hintText: "Matricule (Student ID)",
          prefixIcon: Icons.badge_rounded,
          validator: (matricule) => matricule == null || matricule.isEmpty
              ? 'Matricule is required'
              : null,
        ),
        const SizedBox(height: 20),
        AuthDropdown(
          value: _selectedLevel,
          hintText: "Select Level",
          prefixIcon: Icons.school_rounded,
          items: _levels,
          onChanged: (val) {
            setState(() {
              _selectedLevel = val ?? "";
            });
          },
          validator: (val) =>
              val == null || val.isEmpty ? 'Please select your level' : null,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? Colors.cyanAccent
                        : theme.colorScheme.primary,
                  ),
                ),
                child: Text(
                  "Back",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? Colors.cyanAccent
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AuthButton(
              label: _currentStep == _totalSteps - 1 ? "Sign Up" : "Next",
              isLoading: _isLoading,
              onPressed: _nextStep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.only(bottom: 40),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Already have an account?",
              style: GoogleFonts.outfit(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: () => widget.istoggle(),
              child: Text(
                "Sign In",
                style: GoogleFonts.outfit(
                  color: isDarkMode
                      ? Colors.cyanAccent
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
