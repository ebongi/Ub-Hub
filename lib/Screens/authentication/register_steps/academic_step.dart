import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/institution.dart';

class AcademicStep extends StatelessWidget {
  const AcademicStep({
    super.key,
    required this.formKey,
    required this.matriculeController,
    required this.selectedLevel,
    required this.onLevelChanged,
    required this.selectedInstitutionId,
    required this.onInstitutionChanged,
    required this.isDark,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController matriculeController;
  final String selectedLevel;
  final ValueChanged<String?> onLevelChanged;
  final String? selectedInstitutionId;
  final ValueChanged<String?> onInstitutionChanged;
  final bool isDark;

  static const _levelCodes = ['200', '300', '400', 'Resit'];

  String _levelDisplayName(AppLocalizations l10n, String code) =>
      code == 'Resit' ? l10n.academicLevelResit : code;

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
              title: l10n.academicStepTitle,
              description: l10n.academicStepDescription,
              icon: Icons.school_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            RegistrationSectionFocus(
              title: l10n.academicAffiliationTitle,
              subtitle: l10n.academicAffiliationSubtitle,
              icon: Icons.account_balance_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            RegistrationField(
              label: l10n.studentMatriculeLabel,
              hint: l10n.officialUniversityIdHint,
              icon: Icons.badge_outlined,
              controller: matriculeController,
              isDark: isDark,
              validator: (v) =>
                  v == null || v.isEmpty ? l10n.matriculeRequired : null,
            ),
            const SizedBox(height: 24),
            RegistrationDropdown<String>(
              label: l10n.currentAcademicLevelLabel,
              hint: l10n.selectYourLevelHint,
              icon: Icons.trending_up_rounded,
              value: selectedLevel,
              isDark: isDark,
              items: _levelCodes
                  .map(
                    (code) => DropdownMenuItem<String>(
                      value: code,
                      child: Text(
                        _levelDisplayName(l10n, code),
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: regHeadingColor(isDark),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onLevelChanged,
              validator: (val) =>
                  val == null || val.isEmpty ? l10n.pleaseSelectLevel : null,
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<Institution>>(
              stream: DatabaseService().institutions,
              builder: (context, snapshot) {
                final institutions = snapshot.data ?? [];
                return RegistrationDropdown<String>(
                  label: l10n.assignedInstitutionLabel,
                  hint: l10n.selectYourUniversityHint,
                  icon: Icons.account_balance_rounded,
                  value: selectedInstitutionId ?? '',
                  isDark: isDark,
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
                              color: regHeadingColor(isDark),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onInstitutionChanged,
                  validator: (val) => val == null || val.isEmpty
                      ? l10n.pleaseSelectUniversity
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
