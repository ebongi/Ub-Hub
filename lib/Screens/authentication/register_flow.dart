import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/core/app_wordmark.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/services/auth.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/Screens/authentication/register_steps/personal_details_step.dart';
import 'package:go_study/Screens/authentication/register_steps/academic_details_step.dart';
import 'package:provider/provider.dart';
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _bioController = TextEditingController();

  final List<GlobalKey<FormState>> _pageFormKeys = List.generate(
    2,
    (_) => GlobalKey<FormState>(),
  );

  final Authentication _authentication = Authentication();

  String _selectedLevel = '';
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
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _matriculeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    final valid = _pageFormKeys[_currentStep].currentState?.validate() ?? false;
    if (!valid) return;

    if (_currentStep < 1) {
      await HapticFeedback.lightImpact();
      setState(() => _currentStep = _currentStep + 1);
    } else {
      _submitForm();
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep == 0) return;
    await HapticFeedback.lightImpact();
    setState(() => _currentStep = _currentStep - 1);
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;
    final valid = _pageFormKeys[_currentStep].currentState?.validate() ?? false;
    if (!valid) return;

    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();

    setState(() => _isLoading = true);
    try {
      final user = await _authentication.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: fullName,
        matricule: _matriculeController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        level: _selectedLevel.trim(),
        bio: _bioController.text.trim(),
      );

      if (user != null && mounted) {
        Provider.of<UserModel>(context, listen: false).setName(fullName);
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: const AppWordmark(fontSize: 20),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Text(
                    l10n.registerTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: regHeadingColor(isDark),
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.registerSubtitle,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  height: 1.5,
                  color: regBodyColor(isDark),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AuthStepTracker(
                currentStep: _currentStep,
                stepLabels: [
                  l10n.personalDetailsStepLabel,
                  l10n.academicDetailsStepLabel,
                ],
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _currentStep == 0
                    ? PersonalDetailsStep(
                        key: const ValueKey('personal'),
                        formKey: _pageFormKeys[0],
                        firstNameController: _firstNameController,
                        lastNameController: _lastNameController,
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
                        isDark: isDark,
                      )
                    : AcademicDetailsStep(
                        key: const ValueKey('academic'),
                        formKey: _pageFormKeys[1],
                        phoneController: _phoneController,
                        matriculeController: _matriculeController,
                        bioController: _bioController,
                        selectedLevel: _selectedLevel,
                        onLevelChanged: (val) {
                          setState(() => _selectedLevel = val ?? '');
                        },
                        agreedToTerms: _agreedToTerms,
                        onAgreedToTermsChanged: (val) {
                          setState(() => _agreedToTerms = val);
                        },
                        isDark: isDark,
                      ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _NavigationButtons(
                currentStep: _currentStep,
                isLoading: _isLoading,
                onNext: _nextStep,
                onBack: _previousStep,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _RegisterFooter(onToggle: widget.istoggle, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons({
    required this.currentStep,
    required this.isLoading,
    required this.onNext,
    required this.onBack,
  });

  final int currentStep;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastStep = currentStep == 1;
    return Row(
      children: [
        if (currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: regBorderColor(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              child: Text(
                l10n.registerBack,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: regHeadingColor(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
            ),
          ),
        if (currentStep > 0) const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 2,
          child: AuthPrimaryButton(
            label: isLastStep ? l10n.registerComplete : l10n.registerContinue,
            isLoading: isLoading,
            onPressed: onNext,
            trailingIcon: isLastStep ? null : Icons.arrow_forward_rounded,
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
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.alreadyRegistered,
            style: GoogleFonts.outfit(
              color: regBodyColor(isDark),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => onToggle(),
            child: Text(
              l10n.signInToPortal,
              style: GoogleFonts.outfit(
                color: regIndigo(context),
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
