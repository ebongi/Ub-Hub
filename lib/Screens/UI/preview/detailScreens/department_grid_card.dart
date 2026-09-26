import 'package:flutter/material.dart';
import 'package:go_study/Screens/Shared/content_media_card.dart';
import 'package:go_study/Screens/Shared/department_ui_data.dart';
import 'package:go_study/services/department.dart';

/// Grid card for a department/subject — thin wrapper around
/// [ContentMediaCard]. Shared between [AllDepartmentsScreen] (a
/// signed-in user's own institution) and `InstitutionAboutScreen` (a
/// read-only preview of any institution's subjects).
class DepartmentGridCard extends StatelessWidget {
  const DepartmentGridCard({
    super.key,
    required this.department,
    required this.onTap,
    this.isPending = false,
  });

  final Department department;
  final VoidCallback? onTap;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final uiData = DepartmentUIData.fromDepartmentName(department.name);

    return ContentMediaCard(
      title: department.name,
      subtitle: department.description,
      imageUrl: department.imageUrl,
      icon: uiData.icon,
      primaryColor: uiData.primaryColor,
      secondaryColor: uiData.secondaryColor,
      onTap: onTap,
      isPending: isPending,
    );
  }
}
