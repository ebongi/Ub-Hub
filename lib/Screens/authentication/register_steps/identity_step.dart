import 'package:flutter/material.dart';
import 'package:go_study/Screens/authentication/register_form_widgets.dart';

class IdentityStep extends StatelessWidget {
  const IdentityStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.isDark,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
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
              title: 'Identity',
              description:
                  'Add your real name and contact details so the community can identify you.',
              icon: Icons.badge_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            RegistrationSectionFocus(
              title: 'Personal identity',
              subtitle:
                  'This section makes your profile recognizable to classmates and admins.',
              icon: Icons.person_pin_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            RegistrationField(
              label: 'Full Legal Name',
              hint: 'First and Last Name',
              icon: Icons.person_outline_rounded,
              controller: nameController,
              isDark: isDark,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Full name is required' : null,
            ),
            const SizedBox(height: 24),
            RegistrationField(
              label: 'Phone Contact',
              hint: '+237 ...',
              icon: Icons.phone_android_rounded,
              controller: phoneController,
              isDark: isDark,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Phone number is required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
