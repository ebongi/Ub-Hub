import 'package:flutter/material.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_text_styles.dart';

/// Bold, all-caps, letter-spaced grey header for a flat Settings section
/// (e.g. "APPEARANCE", "ACCOUNT") — no card background/border, matching
/// Coursera's Settings screen rather than the previous grouped-card look.
class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(label.toUpperCase(), style: AppText.settingsSectionLabel(context)),
    );
  }
}

/// Flat Settings row — either a plain outline icon (the original
/// Coursera-reference look) or, when [tint] is given, a small colored icon
/// tile matching the tinted-badge language used by `CompactListRow` and the
/// home-feed toolbox tiles elsewhere in the redesign. Optional grey
/// subtitle, and a trailing chevron/switch/custom widget. Meant to sit
/// inside a `Column` of rows separated by the theme's thin, full-width
/// `Divider`.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.tint,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  /// When set, the icon renders inside a small rounded tinted tile instead
  /// of as a bare outline glyph.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = destructive ? theme.colorScheme.error : (tint ?? theme.colorScheme.onSurfaceVariant);
    final titleColor = destructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return ListTile(
      onTap: onTap,
      leading: tint != null && !destructive
          ? Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint!.withOpacity(isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            )
          : Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: AppText.body(context).copyWith(fontWeight: FontWeight.w500, color: titleColor),
      ),
      subtitle: subtitle != null && subtitle!.isNotEmpty
          ? Text(subtitle!, style: AppText.cardSubtitle(context))
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20)
              : null),
    );
  }
}
