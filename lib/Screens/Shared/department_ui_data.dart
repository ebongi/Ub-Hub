import 'package:flutter/material.dart';

/// Maps a department/subject name to an icon + color pair used for its
/// gradient fallback (when no image is set) and icon badge. Shared by
/// [ContentMediaCard]-based cards and [CompactListRow]-based rows across
/// the department/subject browsing screens.
class DepartmentUIData {
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  DepartmentUIData({
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });

  static DepartmentUIData fromDepartmentName(String name) {
    switch (name.toLowerCase().trim()) {
      case 'computer science':
        return DepartmentUIData(
          icon: Icons.computer_rounded,
          primaryColor: const Color(0xFF2563EB), // Blue 600
          secondaryColor: const Color(0xFF60A5FA), // Blue 400
        );
      case 'mathematics':
        return DepartmentUIData(
          icon: Icons.functions_rounded,
          primaryColor: const Color(0xFF059669), // Emerald 600
          secondaryColor: const Color(0xFF34D399), // Emerald 400
        );
      case 'physics':
        return DepartmentUIData(
          icon: Icons.science_rounded,
          primaryColor: const Color(0xFF7C3AED), // Violet 600
          secondaryColor: const Color(0xFFA78BFA), // Violet 400
        );
      default:
        return DepartmentUIData(
          icon: Icons.account_balance_rounded,
          primaryColor: const Color(0xFF475569), // Slate 600
          secondaryColor: const Color(0xFF94A3B8), // Slate 400
        );
    }
  }
}
