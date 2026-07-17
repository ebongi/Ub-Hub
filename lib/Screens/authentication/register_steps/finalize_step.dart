import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';
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
    required this.isDark,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController bioController;
  final String? selectedInstitutionId;
  final String? selectedDepartmentName;
  final ValueChanged<String?> onDepartmentChanged;
  final bool isDark;

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
              title: 'Finalize',
              description:
                  'Complete your profile with your department and a short academic bio.',
              icon: Icons.check_circle_outline_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            RegistrationSectionFocus(
              title: 'Finalize profile',
              subtitle:
                  'This is the last step before your study account is ready.',
              icon: Icons.assignment_ind_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            RegistrationField(
              label: 'Academic Bio',
              hint: 'Briefly describe your academic interests...',
              icon: Icons.description_outlined,
              controller: bioController,
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Academic Department',
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
                        'Select an institution in the previous step to load departments.',
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
                      'No departments found for this institution.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFEF4444),
                        fontSize: 13.5,
                      ),
                    );
                  }

                  return RegistrationDropdown<String>(
                    label: '',
                    hint: 'Choose your Department',
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
                        ? 'Please select your department'
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
