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

// ── Design tokens (shared with splash/signin) ────────────────────────────────
const Color _deepNavy = Color(0xFF080E1E);
const Color _cardNavy = Color(0xFF111D3D);
const Color _accentBlue = Color(0xFF3B82F6);
const Color _accentCyan = Color(0xFF06B6D4);
const Color _white = Colors.white;

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
  double _passwordStrength = 0;
  String _passwordStrengthText = "";
  Color _passwordStrengthColor = Colors.transparent;
  bool _isLoading = false;
  final Authentication _authentication = Authentication();

  final PageController _pageController = PageController();
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
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
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
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
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
    _pageController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

    setState(() {
      _passwordStrength = strength;
      if (strength <= 0.25) {
        _passwordStrengthText = "Weak";
        _passwordStrengthColor = Colors.redAccent;
      } else if (strength <= 0.75) {
        _passwordStrengthText = "Good";
        _passwordStrengthColor = Colors.orangeAccent;
      } else {
        _passwordStrengthText = "Strong";
        _passwordStrengthColor = Colors.greenAccent;
      }
    });
  }

  Future<void> _nextStep() async {
    if (_formkey.currentState?.validate() ?? false) {
      if (_currentStep < _totalSteps - 1) {
        await HapticFeedback.lightImpact();
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

  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      await HapticFeedback.lightImpact();
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
        return "Let's start with your email and password.";
      case 2:
        return "Enter your university details.";
      case 3:
        return "Complete your profile with a bio and department.";
      default:
        return "Sign up to get started.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _deepNavy : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Background atmosphere ──────────────────────────────────────
          const Positioned.fill(child: _BackgroundPainter()),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formkey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── Header ─────────────────────────────────────────
                    SlideTransition(
                      position: _headerSlide,
                      child: FadeTransition(
                        opacity: _headerFade,
                        child: const _RegisterHeader(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Form card ──────────────────────────────────────
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: isDark ? _cardNavy : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.07)
                                  : Colors.black.withOpacity(0.05),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _accentBlue.withOpacity(
                                  isDark ? 0.12 : 0.08,
                                ),
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 400),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProgressBar(),
                                const SizedBox(height: 32),

                                // Step Subtitle (Animated)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    _getStepSubtitle(),
                                    key: ValueKey(_currentStep),
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      color:
                                          (isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A))
                                              .withOpacity(0.45),
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                SizedBox(
                                  height:
                                      380, // Optimized height to balance content and avoid overflows
                                  child: PageView(
                                    controller: _pageController,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      _buildStep1(),
                                      _buildStep2(),
                                      _buildStep3(),
                                      _buildStep4(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildNavigationButtons(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // const SizedBox(height: 32),

                    // ── Footer ─────────────────────────────────────────
                    FadeTransition(
                      opacity: _footerFade,
                      child: _RegisterFooter(onToggle: widget.istoggle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(colors: [_accentBlue, _accentCyan])
                  : null,
              color: isActive
                  ? null
                  : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF0F172A))
                        .withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Email address'),
        const SizedBox(height: 8),
        _GoTextField(
          controller: _emailcontroller,
          hint: 'you@example.com',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final email = v?.trim() ?? "";
            if (email.isEmpty) return 'Please enter your email';
            if (!RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
            ).hasMatch(email)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const _FieldLabel(label: 'Password'),
        const SizedBox(height: 8),
        _GoTextField(
          controller: _passwordcontroller,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: _isPasswordObscured,
          suffixIcon: GestureDetector(
            onTap: () =>
                setState(() => _isPasswordObscured = !_isPasswordObscured),
            child: Icon(
              _isPasswordObscured
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color:
                  (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A))
                      .withOpacity(0.35),
              size: 20,
            ),
          ),
          onChanged: _checkPasswordStrength,
          validator: (v) {
            String password = v ?? "";
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
          const SizedBox(height: 8),
          _buildStrengthIndicator(),
        ],
        const SizedBox(height: 16),
        const _FieldLabel(label: 'Confirm Password'),
        const SizedBox(height: 8),
        _GoTextField(
          controller: _confirmPasswordController,
          hint: '••••••••',
          icon: Icons.lock_reset_rounded,
          obscureText: _isConfirmPasswordObscured,
          suffixIcon: GestureDetector(
            onTap: () => setState(
              () => _isConfirmPasswordObscured = !_isConfirmPasswordObscured,
            ),
            child: Icon(
              _isConfirmPasswordObscured
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color:
                  (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A))
                      .withOpacity(0.35),
              size: 20,
            ),
          ),
          validator: (v) {
            if (v != _passwordcontroller.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor:
                (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)
                    .withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Strength: $_passwordStrengthText",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _passwordStrengthColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Full Name'),
        const SizedBox(height: 8),
        _GoTextField(
          controller: _usernamecontroller,
          hint: 'John Doe',
          icon: Icons.person_outline_rounded,
          validator: (v) =>
              v == null || v.isEmpty ? 'Full Name is required' : null,
        ),
        const SizedBox(height: 22),
        const _FieldLabel(label: 'Phone Number'),
        const SizedBox(height: 8),
        _GoTextField(
          controller: _phoneNumberController,
          hint: '+237 ...',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
          validator: (v) =>
              v == null || v.isEmpty ? 'Phone number is required' : null,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Matricule (Student ID)'),
        const SizedBox(height: 8),
        _GoTextField(
          controller: _matriculeController,
          hint: 'FE... / UG...',
          icon: Icons.badge_outlined,
          validator: (v) =>
              v == null || v.isEmpty ? 'Matricule is required' : null,
        ),
        const SizedBox(height: 22),
        const _FieldLabel(label: 'Academic Level'),
        const SizedBox(height: 8),
        _GoDropdown<String>(
          value: _selectedLevel,
          hint: 'Select Level',
          icon: Icons.school_outlined,
          items: _levels.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF0F172A))
                          .withOpacity(0.9),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedLevel = val ?? ""),
          validator: (val) =>
              val == null || val.isEmpty ? 'Please select your level' : null,
        ),
        const SizedBox(height: 22),
        const _FieldLabel(label: 'Institution (University)'),
        const SizedBox(height: 8),
        StreamBuilder<List<Institution>>(
          stream: DatabaseService().institutions,
          builder: (context, snapshot) {
            final institutions = snapshot.data ?? [];
            return _GoDropdown<String>(
              value: _selectedInstitutionId ?? "",
              hint: 'Select University',
              icon: Icons.account_balance_rounded,
              items: institutions
                  .map(
                    (i) => DropdownMenuItem<String>(
                      value: i.id,
                      child: Text(
                        i.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))
                                  .withOpacity(0.9),
                        ),
                      ),
                    ),
                  )
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

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: TextButton(
              onPressed: _previousStep,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color:
                        (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF0F172A))
                            .withOpacity(0.1),
                  ),
                ),
              ),
              child: Text(
                "Back",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF0F172A))
                          .withOpacity(0.7),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _RegisterButton(
            label: _currentStep == _totalSteps - 1
                ? "Create Account"
                : "Continue",
            isLoading: _isLoading,
            onPressed: _nextStep,
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Tell us about yourself (Bio)'),
        const SizedBox(height: 8),
        _GoTextField(
          controller: _bioController,
          hint: 'Enter a short bio...',
          icon: Icons.edit_note_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: 22),
        const _FieldLabel(label: 'Confirm your Department'),
        const SizedBox(height: 8),
        if (_selectedInstitutionId == null || _selectedInstitutionId!.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Please select an institution in the previous step first.",
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          )
        else
          StreamBuilder<List<Department>>(
            stream: DatabaseService().getDepartments(
              institutionId: _selectedInstitutionId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final departments = snapshot.data ?? [];
              if (departments.isEmpty) {
                return Text(
                  "No departments found for this institution.",
                  style: GoogleFonts.outfit(color: Colors.redAccent),
                );
              }

              return _GoDropdown<String>(
                value: _selectedDepartmentName ?? "",
                hint: 'Select Department',
                icon: Icons.category_outlined,
                items: departments
                    .map(
                      (d) => DropdownMenuItem<String>(
                        value: d.name,
                        child: Text(
                          d.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color:
                                (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A))
                                    .withOpacity(0.9),
                          ),
                        ),
                      ),
                    )
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
    );
  }
}

// ── Background (orbs + dot grid) ─────────────────────────────────────────────
class _BackgroundPainter extends StatelessWidget {
  const _BackgroundPainter();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _BgPainter(isDark: isDark),
      child: const SizedBox.expand(),
    );
  }
}

class _BgPainter extends CustomPainter {
  final bool isDark;
  _BgPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final orbOpacity1 = isDark ? 0.13 : 0.07;
    final orbOpacity2 = isDark ? 0.09 : 0.05;
    final dotOpacity = isDark ? 0.025 : 0.05;

    final orbPaint1 = Paint()
      ..shader =
          RadialGradient(
            colors: [_accentBlue.withOpacity(orbOpacity1), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.1, size.height * 0.05),
              radius: 220,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.05),
      220,
      orbPaint1,
    );

    final orbPaint2 = Paint()
      ..shader =
          RadialGradient(
            colors: [_accentCyan.withOpacity(orbOpacity2), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.9, size.height * 0.85),
              radius: 260,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.85),
      260,
      orbPaint2,
    );

    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(dotOpacity);
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ── Header section ────────────────────────────────────────────────────────────
class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_accentBlue, _accentCyan],
          ).createShader(bounds),
          child: Text.rich(
            TextSpan(
              text: 'Go',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 3,
                height: 1,
              ),
              children: [
                TextSpan(
                  text: 'Study',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    color: Colors.blue,
                    letterSpacing: 3,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Join Us.',
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).brightness == Brightness.dark
                ? _white
                : const Color(0xFF0F172A),
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Create an account to begin your journey.',
          style: GoogleFonts.outfit(
            fontSize: 15,
            color:
                (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0F172A))
                    .withOpacity(0.45),
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: (isDark ? Colors.white : const Color(0xFF0F172A)).withOpacity(
          0.45,
        ),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _GoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const _GoTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: GoogleFonts.outfit(
        color: textColor.withOpacity(0.9),
        fontSize: 15,
      ),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          color: textColor.withOpacity(0.2),
          fontSize: 15,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(icon, color: textColor.withOpacity(0.3), size: 20),
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: suffixIcon,
              )
            : null,
        filled: true,
        fillColor: textColor.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textColor.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textColor.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        errorStyle: GoogleFonts.outfit(
          color: const Color(0xFFEF4444),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _GoDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _GoDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: value is String && (value as String).isEmpty ? null : value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      icon: Icon(
        Icons.expand_more_rounded,
        color:
            (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A))
                .withOpacity(0.3),
      ),
      dropdownColor: Theme.of(context).brightness == Brightness.dark
          ? _cardNavy
          : Colors.white,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          color:
              (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF0F172A))
                  .withOpacity(0.2),
          fontSize: 15,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            icon,
            color:
                (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0F172A))
                    .withOpacity(0.3),
            size: 20,
          ),
        ),
        filled: true,
        fillColor:
            (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A))
                .withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color:
                (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0F172A))
                    .withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color:
                (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0F172A))
                    .withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        errorStyle: GoogleFonts.outfit(
          color: const Color(0xFFEF4444),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _RegisterButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isLoading
              ? LinearGradient(
                  colors: [
                    _accentBlue.withOpacity(0.5),
                    _accentCyan.withOpacity(0.5),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accentBlue, _accentCyan],
                ),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: _accentBlue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class _RegisterFooter extends StatelessWidget {
  final Function onToggle;
  const _RegisterFooter({required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: textColor.withOpacity(0.08), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: textColor.withOpacity(0.2),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: textColor.withOpacity(0.08), thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Already have an account?",
                style: GoogleFonts.outfit(
                  color: textColor.withOpacity(0.4),
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onToggle(),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_accentBlue, _accentCyan],
                  ).createShader(bounds),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
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
