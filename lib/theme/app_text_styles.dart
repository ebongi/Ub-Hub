import 'package:flutter/material.dart';

/// Semantic text-style helpers built on top of [Theme.of(context).textTheme],
/// so the app's font (Outfit, set in [ThemeProvider]) and brightness keep
/// flowing through automatically. This is a thin naming layer over the
/// existing ad hoc `GoogleFonts.outfit(...)` call sites being migrated in
/// this redesign pass — not a full rewrite of Material's `TextTheme` roles.
class AppText {
  AppText._();

  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        );
  }

  static TextStyle cardTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.15,
        );
  }

  static TextStyle cardSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
  }

  static TextStyle body(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14);
  }

  static TextStyle caption(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        );
  }

  /// Bold, all-caps, letter-spaced grey label for flat Settings-style
  /// section headers (e.g. "APPEARANCE", "ACCOUNT").
  static TextStyle settingsSectionLabel(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
  }
}
