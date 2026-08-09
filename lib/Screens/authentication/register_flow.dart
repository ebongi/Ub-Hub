import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';
import 'package:go_study/Screens/authentication/register_steps/account_step.dart';
import 'package:go_study/Screens/authentication/register_steps/identity_step.dart';
import 'package:go_study/Screens/authentication/register_steps/academic_step.dart';
import 'package:go_study/Screens/authentication/register_steps/finalize_step.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class RegisterFlow extends StatefulWidget {
  const RegisterFlow({super.key, required this.istoggle});
  final Function istoggle;

  @override
  State<RegisterFlow> createState() => _RegisterFlowState();
}

class _RegisterFlowState extends State<RegisterFlow>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _bioController = TextEditingController();

  final List<GlobalKey<FormState>> _pageFormKeys = List.generate(
    4,
    (_) => GlobalKey<FormState>(),
  );

  final PageController _pageController = PageController(initialPage: 0);
  final Authentication _authentication = Authentication();

  String _selectedLevel = '';
  String? _selectedInstitutionId;
  String? _selectedDepartmentName;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  int _currentStep = 0;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _loadOnboardingData();
  }

  Future<void> _loadOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedDepartmentName = prefs.getString('onboarding_department');
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _matriculeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    // Strength feedback is handled inside the Account step widget.
  }

  Future<void> _nextStep() async {
    final valid = _pageFormKeys[_currentStep].currentState?.validate() ?? false;
    if (!valid) return;

    if (_currentStep < 3) {
      await HapticFeedback.lightImpact();
      final next = _currentStep + 1;
      setState(() => _currentStep = next);
      await _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _submitForm();
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep == 0) return;
    await HapticFeedback.lightImpact();
    final previous = _currentStep - 1;
    setState(() => _currentStep = previous);
    await _pageController.animateToPage(
      previous,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;
    final valid = _pageFormKeys[_currentStep].currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _isLoading = true);
    try {
      final user = await _authentication.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        matricule: _matriculeController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        level: _selectedLevel.trim(),
        institutionId: _selectedInstitutionId,
        department: _selectedDepartmentName,
        bio: _bioController.text.trim(),
      );

      if (user != null && mounted) {
        Provider.of<UserModel>(context, listen: false)
            .setName(_nameController.text.trim());
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: regBgColor(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _BrandChip(isDark: isDark),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Text(
                    l10n.registerTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: regHeadingColor(isDark),
                      height: 1.1,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.registerSubtitle,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  height: 1.5,
                  color: regBodyColor(isDark),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: regSurfaceColor(isDark),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: regBorderColor(isDark).withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.28 : 0.04),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressHeader(
                      current: _currentStep,
                      total: 4,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.54,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          AccountStep(
                            formKey: _pageFormKeys[0],
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController: _confirmPasswordController,
                            isPasswordObscured: _isPasswordObscured,
                            isConfirmPasswordObscured: _isConfirmPasswordObscured,
                            onTogglePassword: () {
                              setState(
                                () => _isPasswordObscured = !_isPasswordObscured,
                              );
                            },
                            onToggleConfirmPassword: () {
                              setState(
                                () => _isConfirmPasswordObscured =
                                    !_isConfirmPasswordObscured,
                              );
                            },
                            onPasswordChanged: _checkPasswordStrength,
                            isDark: isDark,
                          ),
                          IdentityStep(
                            formKey: _pageFormKeys[1],
                            nameController: _nameController,
                            phoneController: _phoneController,
                            isDark: isDark,
                          ),
                          AcademicStep(
                            formKey: _pageFormKeys[2],
                            matriculeController: _matriculeController,
                            selectedLevel: _selectedLevel,
                            onLevelChanged: (val) {
                              setState(() => _selectedLevel = val ?? '');
                            },
                            selectedInstitutionId: _selectedInstitutionId,
                            onInstitutionChanged: (val) {
                              setState(() => _selectedInstitutionId = val);
                            },
                            isDark: isDark,
                          ),
                          FinalizeStep(
                            formKey: _pageFormKeys[3],
                            bioController: _bioController,
                            selectedInstitutionId: _selectedInstitutionId,
                            selectedDepartmentName: _selectedDepartmentName,
                            onDepartmentChanged: (val) {
                              setState(() => _selectedDepartmentName = val);
                            },
                            agreedToTerms: _agreedToTerms,
                            onAgreedToTermsChanged: (val) {
                              setState(() => _agreedToTerms = val);
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _NavigationButtons(
                      currentStep: _currentStep,
                      isLoading: _isLoading,
                      onNext: _nextStep,
                      onBack: _previousStep,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _RegisterFooter(onToggle: widget.istoggle, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final primary = regIndigo(context);
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
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
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
                    color: isDark ? Colors.white.withOpacity(0.9) : regSlate700,
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

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.isDark,
  });

  final int current;
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = regIndigo(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(total, (index) {
            final active = index == current;
            final done = index < current;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < total - 1 ? 8 : 0),
                height: 8,
                decoration: BoxDecoration(
                  color: active || done ? primary : regBorderColor(isDark),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.registerStepOf(current + 1, total),
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: regBodyColor(isDark),
          ),
        ),
      ],
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons({
    required this.currentStep,
    required this.isLoading,
    required this.onNext,
    required this.onBack,
    required this.isDark,
  });

  final int currentStep;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = regIndigo(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        if (currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: regBorderColor(isDark), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                l10n.registerBack,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: regHeadingColor(isDark),
                ),
              ),
            ),
          ),
        if (currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLoading ? null : onNext,
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
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    currentStep == 3 ? l10n.registerComplete : l10n.registerContinue,
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
}

class _RegisterFooter extends StatelessWidget {
  const _RegisterFooter({required this.onToggle, required this.isDark});
  final Function onToggle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child:
                  Divider(color: regBorderColor(isDark).withOpacity(0.5), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.registerVerificationRequired,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: regBodyColor(isDark).withOpacity(0.8),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child:
                  Divider(color: regBorderColor(isDark).withOpacity(0.5), thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.alreadyRegistered,
                style: GoogleFonts.outfit(
                  color: regBodyColor(isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onToggle(),
                child: Text(
                  l10n.signInToPortal,
                  style: GoogleFonts.outfit(
                    color: regIndigo(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                    decorationColor: regIndigo(context).withOpacity(0.3),
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
