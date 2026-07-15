import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/services/auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/institution.dart';
import 'package:go_study/services/department.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
Color _indigo(BuildContext context) => Theme.of(context).colorScheme.primary;
const Color _slate900 = Color(0xFF0F172A);
const Color _slate700 = Color(0xFF334155);
const Color _slate500 = Color(0xFF64748B);
const Color _slate300 = Color(0xFFCBD5E1);
const Color _slate100 = Color(0xFFF1F5F9);
const Color _green = Color(0xFF10B981);

Color _bgColor(bool isDark) =>
    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
Color _surfaceColor(bool isDark) =>
    isDark ? const Color(0xFF1E293B) : Colors.white;
Color _headingColor(bool isDark) => isDark ? Colors.white : _slate900;
Color _bodyColor(bool isDark) =>
    isDark ? Colors.white.withOpacity(0.55) : _slate500;
Color _borderColor(bool isDark) =>
    isDark ? Colors.white.withOpacity(0.1) : _slate300;
Color _fieldFill(bool isDark) =>
    isDark ? Colors.white.withOpacity(0.06) : _slate100;
Color _iconColor(bool isDark) =>
    isDark ? Colors.white.withOpacity(0.4) : _slate500;

class Register extends StatefulWidget {
  const Register({super.key, required this.istoggle});
  final Function istoggle;

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register>
    with SingleTickerProviderStateMixin {
  final _usernamecontroller = TextEditingController();
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _matriculeController = TextEditingController();
  String _selectedLevel = "";
  final List<String> _levels = ["200", "300", "400", "Resit"];
  String? _selectedInstitutionId;
  String? _selectedDepartmentName;
  final _bioController = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  String _passwordStrengthText = "";
  bool _isLoading = false;
  final Authentication _authentication = Authentication();

  bool _isMovingForward = true;
  int _currentStep = 0;
  final int _totalSteps = 4;

  late AnimationController _entryController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
          ),
        );

    _footerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
    _loadOnboardingData();
  }

  Future<void> _loadOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDepartmentName = prefs.getString('onboarding_department');
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _usernamecontroller.dispose();
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    _matriculeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

    setState(() {
      if (strength <= 0.25) {
        _passwordStrengthText = "Weak";
      } else if (strength <= 0.75) {
        _passwordStrengthText = "Good";
      } else {
        _passwordStrengthText = "Strong";
      }
    });
  }

  Future<void> _nextStep() async {
    if (_formkey.currentState?.validate() ?? false) {
      if (_currentStep < _totalSteps - 1) {
        await HapticFeedback.lightImpact();
        setState(() {
          _isMovingForward = true;
          _currentStep++;
        });
      } else {
        _submitForm();
      }
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      await HapticFeedback.lightImpact();
      setState(() {
        _isMovingForward = false;
        _currentStep--;
      });
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
          level: _selectedLevel.trim(),
          institutionId: _selectedInstitutionId,
          department: _selectedDepartmentName,
          bio: _bioController.text.trim(),
        );

        if (user != null && mounted) {
          Provider.of<UserModel>(
            context,
            listen: false,
          ).setName(_usernamecontroller.text.trim());
          Navigator.of(context).pop();
        }
      } on sb.AuthException catch (e) {
        if (mounted) ErrorHandler.showErrorSnackBar(context, e);
      } catch (e) {
        if (mounted) ErrorHandler.showErrorSnackBar(context, e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return "Secure your academic portal access.";
      case 1:
        return "Help us identify you within the community.";
      case 2:
        return "Connect your account to your university.";
      case 3:
        return "Finalize your profile for collaboration.";
      default:
        return "Student Registration";
    }
  }

  Widget _buildStepHeader(String title, String description, IconData icon, bool isDark) {
    final primary = _indigo(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withOpacity(isDark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _headingColor(isDark),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: _bodyColor(isDark),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            _buildStepHeader(
              "Account Credentials",
              "Set up a strong password to protect your academic records and data.",
              Icons.shield_outlined,
              isDark,
            ),
            _buildStep1(),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildStepHeader(
              "Personal Identity",
              "Use your real name as it appears on your student records.",
              Icons.person_pin_outlined,
              isDark,
            ),
            _buildStep2(),
          ],
        );
      case 2:
        return Column(
          children: [
            _buildStepHeader(
              "Academic Affiliation",
              "Connecting with your institution unlocks specific course materials.",
              Icons.school_outlined,
              isDark,
            ),
            _buildStep3(),
          ],
        );
      case 3:
        return Column(
          children: [
            _buildStepHeader(
              "Professional Profile",
              "Tell your peers about your interests and confirm your department.",
              Icons.assignment_ind_outlined,
              isDark,
            ),
            _buildStep4(),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _bgColor(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Brand chip ───────────────────────────────────────────
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _BrandChip(isDark: isDark),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Heading ──────────────────────────────────────────────
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _RegisterHeader(isDark: isDark),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Form card ────────────────────────────────────────────
                SlideTransition(
                  position: _cardSlide,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: _surfaceColor(isDark),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _borderColor(isDark).withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stepper
                          _buildStepper(isDark),

                          const SizedBox(height: 32),

                          // Step subtitle (animated)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Row(
                              key: ValueKey(_currentStep),
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _indigo(context),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _getStepSubtitle(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: _headingColor(isDark).withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Step content (animated)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              final isNew =
                                  child.key == ValueKey<int>(_currentStep);
                              final offset = _isMovingForward
                                  ? const Offset(0.05, 0.0)
                                  : const Offset(-0.05, 0.0);
                              final beginOffset = isNew ? offset : -offset;

                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: beginOffset,
                                  end: Offset.zero,
                                ).animate(animation),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildCurrentStepWidget(),
                          ),

                          const SizedBox(height: 32),

                          // Navigation buttons
                          _buildNavigationButtons(isDark),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Footer ───────────────────────────────────────────────
                FadeTransition(
                  opacity: _footerFade,
                  child: _RegisterFooter(
                    onToggle: widget.istoggle,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stepper ───────────────────────────────────────────────────────────────
  Widget _buildStepper(bool isDark) {
    final primary = _indigo(context);
    final stepLabels = ["Account", "Identity", "Academic", "Finalize"];
    final stepIcons = [
      Icons.lock_person_outlined,
      Icons.badge_outlined,
      Icons.school_outlined,
      Icons.check_circle_outline_rounded,
    ];

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 20,
              right: 20,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: _borderColor(isDark).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final stepWidth = width / (_totalSteps - 1);
                  final activeWidth = stepWidth * _currentStep;
                  return Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: activeWidth,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, primary.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Spacer(),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_totalSteps, (index) {
                final isCompleted = index < _currentStep;
                final isActive = index == _currentStep;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? primary
                        : isCompleted
                            ? primary.withOpacity(0.12)
                            : _surfaceColor(isDark),
                    border: Border.all(
                      color: isActive
                          ? primary
                          : isCompleted
                              ? primary.withOpacity(0.3)
                              : _borderColor(isDark),
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: primary.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : stepIcons[index],
                        key: ValueKey(isCompleted),
                        size: 20,
                        color: isActive
                            ? Colors.white
                            : isCompleted
                                ? primary
                                : _iconColor(isDark),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_totalSteps, (index) {
            final isActive = index == _currentStep;
            final isCompleted = index < _currentStep;

            return SizedBox(
              width: 64,
              child: Text(
                stepLabels[index],
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  letterSpacing: 0.3,
                  fontWeight: (isActive || isCompleted)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isActive
                      ? primary
                      : isCompleted
                          ? _headingColor(isDark).withOpacity(0.6)
                          : _bodyColor(isDark).withOpacity(0.5),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Navigation buttons ────────────────────────────────────────────────────
  Widget _buildNavigationButtons(bool isDark) {
    final primary = _indigo(context);
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _borderColor(isDark), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                "Back",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: _headingColor(isDark),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              disabledBackgroundColor: primary.withOpacity(0.55),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: primary.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _currentStep == _totalSteps - 1
                        ? "Complete Registration"
                        : "Continue",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Email + Password ───────────────────────────────────────────────
  Widget _buildStep1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey<int>(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RegField(
          label: 'Academic Email',
          hint: 'student@university.edu',
          icon: Icons.alternate_email_rounded,
          controller: _emailcontroller,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final email = v?.trim() ?? "";
            if (email.isEmpty) return 'Please enter your email';
            if (!RegExp(
              r"^[a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
            ).hasMatch(email)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _RegField(
          label: 'Secure Password',
          hint: 'Enter strong password',
          icon: Icons.lock_outline_rounded,
          controller: _passwordcontroller,
          isDark: isDark,
          obscureText: _isPasswordObscured,
          onChanged: _checkPasswordStrength,
          suffixIcon: GestureDetector(
            onTap: () =>
                setState(() => _isPasswordObscured = !_isPasswordObscured),
            child: Icon(
              _isPasswordObscured
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: _iconColor(isDark),
              size: 20,
            ),
          ),
          validator: (v) {
            final password = v ?? "";
            if (password.isEmpty) return 'Password is required';
            if (password.length < 8) return 'Minimum 8 characters';
            if (!password.contains(RegExp(r'[A-Z]'))) {
              return 'Add at least one uppercase letter';
            }
            if (!password.contains(RegExp(r'[0-9]'))) {
              return 'Add at least one digit';
            }
            if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
              return 'Add a special character';
            }
            return null;
          },
        ),
        if (_passwordcontroller.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildStrengthIndicator(isDark),
        ],
        const SizedBox(height: 20),
        _RegField(
          label: 'Confirm Password',
          hint: 'Repeat password',
          icon: Icons.lock_reset_rounded,
          controller: _confirmPasswordController,
          isDark: isDark,
          obscureText: _isConfirmPasswordObscured,
          suffixIcon: GestureDetector(
            onTap: () => setState(
              () => _isConfirmPasswordObscured = !_isConfirmPasswordObscured,
            ),
            child: Icon(
              _isConfirmPasswordObscured
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: _iconColor(isDark),
              size: 20,
            ),
          ),
          validator: (v) {
            if (v != _passwordcontroller.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ── Password strength indicator ───────────────────────────────────────────
  Widget _buildStrengthIndicator(bool isDark) {
    final password = _passwordcontroller.text;
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int segments = 0;
    if (password.isNotEmpty) {
      if (hasMinLength) segments++;
      if (hasUppercase) segments++;
      if (hasDigits) segments++;
      if (hasSpecialChar) segments++;
    }

    Color getStrengthColor(int segs) {
      switch (segs) {
        case 1:
          return const Color(0xFFEF4444);
        case 2:
          return const Color(0xFFF97316);
        case 3:
          return const Color(0xFFF59E0B);
        case 4:
          return _green;
        default:
          return Colors.transparent;
      }
    }

    final strengthColor = getStrengthColor(segments);
    final emptyColor = _borderColor(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: strengthColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: strengthColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Password Security",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _headingColor(isDark).withOpacity(0.7),
                ),
              ),
              Text(
                _passwordStrengthText.isEmpty ? "—" : _passwordStrengthText,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: strengthColor == Colors.transparent
                      ? _bodyColor(isDark)
                      : strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (index) {
              final isFilled = index < segments;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isFilled ? strengthColor : emptyColor.withOpacity(0.2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          _buildRequirementItem("Min. 8 characters", hasMinLength, isDark),
          const SizedBox(height: 6),
          _buildRequirementItem("Uppercase (A-Z)", hasUppercase, isDark),
          const SizedBox(height: 6),
          _buildRequirementItem("Number (0-9)", hasDigits, isDark),
          const SizedBox(height: 6),
          _buildRequirementItem("Special char (!@#)", hasSpecialChar, isDark),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String label, bool isMet, bool isDark) {
    final color = isMet ? _green : _bodyColor(isDark).withOpacity(0.4);

    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet
                  ? _headingColor(isDark).withOpacity(0.8)
                  : _bodyColor(isDark).withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Name + Phone ──────────────────────────────────────────────────
  Widget _buildStep2() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey<int>(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RegField(
          label: 'Full Legal Name',
          hint: 'First and Last Name',
          icon: Icons.person_outline_rounded,
          controller: _usernamecontroller,
          isDark: isDark,
          validator: (v) =>
              v == null || v.isEmpty ? 'Full Name is required' : null,
        ),
        const SizedBox(height: 24),
        _RegField(
          label: 'Phone Contact',
          hint: '+237 ...',
          icon: Icons.phone_android_rounded,
          controller: _phoneNumberController,
          isDark: isDark,
          keyboardType: TextInputType.phone,
          validator: (v) =>
              v == null || v.isEmpty ? 'Phone number is required' : null,
        ),
      ],
    );
  }

  // ── Step 3: Academic details ───────────────────────────────────────────────
  Widget _buildStep3() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey<int>(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RegField(
          label: 'Student Matricule',
          hint: 'Official University ID',
          icon: Icons.badge_outlined,
          controller: _matriculeController,
          isDark: isDark,
          validator: (v) =>
              v == null || v.isEmpty ? 'Matricule is required' : null,
        ),
        const SizedBox(height: 24),
        _RegDropdown<String>(
          label: 'Current Academic Level',
          hint: 'Select your level',
          icon: Icons.trending_up_rounded,
          value: _selectedLevel,
          isDark: isDark,
          items: _levels
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: _headingColor(isDark),
                        )),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _selectedLevel = val ?? ""),
          validator: (val) => val == null || val.isEmpty
              ? 'Please select your level'
              : null,
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<Institution>>(
          stream: DatabaseService().institutions,
          builder: (context, snapshot) {
            final institutions = snapshot.data ?? [];
            return _RegDropdown<String>(
              label: 'Assigned Institution',
              hint: 'Select your University',
              icon: Icons.account_balance_rounded,
              value: _selectedInstitutionId ?? "",
              isDark: isDark,
              items: institutions
                  .map((i) => DropdownMenuItem<String>(
                        value: i.id,
                        child: Text(i.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              color: _headingColor(isDark),
                            )),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedInstitutionId = val);
                }
              },
              validator: (val) => val == null || val.isEmpty
                  ? 'Please select your university'
                  : null,
            );
          },
        ),
      ],
    );
  }

  // ── Step 4: Bio + Department ──────────────────────────────────────────────
  Widget _buildStep4() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      key: const ValueKey<int>(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RegField(
          label: 'Academic Bio',
          hint: 'Briefly describe your academic interests...',
          icon: Icons.description_outlined,
          controller: _bioController,
          isDark: isDark,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic Department',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white.withOpacity(0.7) : _slate700,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedInstitutionId == null ||
                _selectedInstitutionId!.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _fieldFill(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderColor(isDark).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: _iconColor(isDark), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Please select an institution in the previous step to load departments.",
                        style: GoogleFonts.outfit(
                          color: _bodyColor(isDark),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              StreamBuilder<List<Department>>(
                stream: DatabaseService().getDepartments(
                  institutionId: _selectedInstitutionId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: _indigo(context),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  final departments = snapshot.data ?? [];
                  if (departments.isEmpty) {
                    return Text(
                      "No departments found for this institution.",
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFEF4444),
                        fontSize: 13.5,
                      ),
                    );
                  }

                  return _RegDropdown<String>(
                    label: '',
                    hint: 'Choose your Department',
                    icon: Icons.category_outlined,
                    value: _selectedDepartmentName ?? "",
                    isDark: isDark,
                    showLabel: false,
                    items: departments
                        .map((d) => DropdownMenuItem<String>(
                              value: d.name,
                              child: Text(d.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    color: _headingColor(isDark),
                                  )),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDepartmentName = val);
                      }
                    },
                    validator: (val) => val == null || val.isEmpty
                        ? 'Please select your department'
                        : null,
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ── Brand chip ────────────────────────────────────────────────────────────────
class _BrandChip extends StatelessWidget {
  final bool isDark;
  const _BrandChip({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = _indigo(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              text: 'Go',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: primary,
                letterSpacing: 0.5,
              ),
              children: [
                TextSpan(
                  text: 'Study',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white.withOpacity(0.9) : _slate700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Register header ───────────────────────────────────────────────────────────
class _RegisterHeader extends StatelessWidget {
  final bool isDark;
  const _RegisterHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Registration',
          style: GoogleFonts.outfit(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: _headingColor(isDark),
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Join the GoStudy academic network to collaborate with peers and access exclusive resources.',
          style: GoogleFonts.outfit(
            fontSize: 15.5,
            color: _bodyColor(isDark),
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ── Reusable field for register ───────────────────────────────────────────────
class _RegField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isDark;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const _RegField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final primary = _indigo(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withOpacity(0.8) : _slate700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: GoogleFonts.outfit(
            fontSize: 15.5,
            color: isDark ? Colors.white.withOpacity(0.95) : _slate900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              fontSize: 15,
              color: isDark ? Colors.white.withOpacity(0.25) : _slate300,
            ),
            prefixIcon: Icon(icon, color: primary.withOpacity(0.7), size: 20),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: suffixIcon,
                  )
                : null,
            filled: true,
            fillColor: _fieldFill(isDark),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _borderColor(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _borderColor(isDark).withOpacity(0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: GoogleFonts.outfit(
              color: const Color(0xFFEF4444),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable dropdown for register ────────────────────────────────────────────
class _RegDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final T? value;
  final bool isDark;
  final bool showLabel;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _RegDropdown({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.isDark,
    required this.items,
    required this.onChanged,
    this.validator,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = _indigo(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withOpacity(0.8) : _slate700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          isExpanded: true,
          value: value is String && (value as String).isEmpty ? null : value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: _surfaceColor(isDark),
          icon: Icon(Icons.expand_more_rounded, color: _iconColor(isDark)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              fontSize: 15,
              color: isDark ? Colors.white.withOpacity(0.25) : _slate300,
            ),
            prefixIcon: Icon(icon, color: primary.withOpacity(0.7), size: 20),
            filled: true,
            fillColor: _fieldFill(isDark),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _borderColor(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _borderColor(isDark).withOpacity(0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorStyle: GoogleFonts.outfit(
              color: const Color(0xFFEF4444),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Register footer ───────────────────────────────────────────────────────────
class _RegisterFooter extends StatelessWidget {
  final Function onToggle;
  final bool isDark;
  const _RegisterFooter({required this.onToggle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: _borderColor(isDark).withOpacity(0.5), thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'VERIFICATION REQUIRED',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: _bodyColor(isDark).withOpacity(0.8),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(child: Divider(color: _borderColor(isDark).withOpacity(0.5), thickness: 1)),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Already registered?",
                style: GoogleFonts.outfit(
                  color: _bodyColor(isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onToggle(),
                child: Text(
                  'Sign In to Portal',
                  style: GoogleFonts.outfit(
                    color: _indigo(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                    decorationColor: _indigo(context).withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
