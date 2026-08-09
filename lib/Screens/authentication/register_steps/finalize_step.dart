import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';
import 'package:go_study/Screens/UI/preview/Settings/privacy_policy_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/terms_of_service_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/department.dart';

class FinalizeStep extends StatelessWidget {
  const FinalizeStep({
    super.key,
    required this.formKey,
    required this.bioController,
    required this.selectedInstitutionId,
    required this.selectedDepartmentName,
    required this.onDepartmentChanged,
    required this.agreedToTerms,
    required this.onAgreedToTermsChanged,
    required this.isDark,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController bioController;
  final String? selectedInstitutionId;
  final String? selectedDepartmentName;
  final ValueChanged<String?> onDepartmentChanged;
  final bool agreedToTerms;
  final ValueChanged<bool> onAgreedToTermsChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RegistrationPageHeader(
              title: l10n.finalizeStepTitle,
              description: l10n.finalizeStepDescription,
              icon: Icons.check_circle_outline_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            RegistrationSectionFocus(
              title: l10n.finalizeProfileTitle,
              subtitle: l10n.finalizeProfileSubtitle,
              icon: Icons.assignment_ind_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            RegistrationField(
              label: l10n.academicBioLabel,
              hint: l10n.academicBioHint,
              icon: Icons.description_outlined,
              controller: bioController,
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.academicDepartmentLabel,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white.withOpacity(0.7) : regSlate700,
              ),
            ),
            const SizedBox(height: 8),
            if (selectedInstitutionId == null || selectedInstitutionId!.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: regFieldFill(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: regBorderColor(isDark).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: regIconColor(isDark),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.selectInstitutionFirstHint,
                        style: GoogleFonts.outfit(
                          color: regBodyColor(isDark),
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
                  institutionId: selectedInstitutionId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: regIndigo(context),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  final departments = snapshot.data ?? [];
                  if (departments.isEmpty) {
                    return Text(
                      l10n.noDepartmentsFound,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFEF4444),
                        fontSize: 13.5,
                      ),
                    );
                  }

                  return RegistrationDropdown<String>(
                    label: '',
                    hint: l10n.chooseYourDepartmentHint,
                    icon: Icons.category_outlined,
                    value: selectedDepartmentName ?? '',
                    isDark: isDark,
                    showLabel: false,
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
                                color: regHeadingColor(isDark),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onDepartmentChanged,
                    validator: (val) => val == null || val.isEmpty
                        ? l10n.pleaseSelectDepartment
                        : null,
                  );
                },
              ),
            const SizedBox(height: 24),
            FormField<bool>(
              initialValue: agreedToTerms,
              validator: (value) => (value ?? false)
                  ? null
                  : l10n.agreeToTermsRequired,
              builder: (field) {
                void toggle(bool value) {
                  onAgreedToTermsChanged(value);
                  field.didChange(value);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: agreedToTerms,
                          onChanged: (val) => toggle(val ?? false),
                          activeColor: regIndigo(context),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => toggle(!agreedToTerms),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                children: [
                                  Text(
                                    l10n.agreeToTermsPrefix,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: regBodyColor(isDark),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TermsOfServiceScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.termsOfServiceLink,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: regIndigo(context),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    l10n.andSeparator,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: regBodyColor(isDark),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PrivacyPolicyScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.privacyPolicyLink,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: regIndigo(context),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: regBodyColor(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          field.errorText!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
