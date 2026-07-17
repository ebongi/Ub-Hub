import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const _levels = ['200', '300', '400', 'Resit'];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RegistrationPageHeader(
              title: 'Academic',
              description:
                  'Connect your university, matricule, and study level to unlock the right resources.',
              icon: Icons.school_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            RegistrationSectionFocus(
              title: 'Academic affiliation',
              subtitle:
                  'This links your account to the correct educational track.',
              icon: Icons.account_balance_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            RegistrationField(
              label: 'Student Matricule',
              hint: 'Official University ID',
              icon: Icons.badge_outlined,
              controller: matriculeController,
              isDark: isDark,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Matricule is required' : null,
            ),
            const SizedBox(height: 24),
            RegistrationDropdown<String>(
              label: 'Current Academic Level',
              hint: 'Select your level',
              icon: Icons.trending_up_rounded,
              value: selectedLevel,
              isDark: isDark,
              items: _levels
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
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
                  val == null || val.isEmpty ? 'Please select your level' : null,
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<Institution>>(
              stream: DatabaseService().institutions,
              builder: (context, snapshot) {
                final institutions = snapshot.data ?? [];
                return RegistrationDropdown<String>(
                  label: 'Assigned Institution',
                  hint: 'Select your University',
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
                      ? 'Please select your university'
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
