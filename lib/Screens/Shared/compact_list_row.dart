import 'package:flutter/material.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_text_styles.dart';

/// Coursera-style compact list row ("Guided Projects for You", "Recently
/// Viewed Products"): a small leading icon tile, title/subtitle stacked,
/// and a trailing chevron/widget — no card border, meant to sit inside a
/// `Column` of rows separated by the theme's thin `Divider`.
///
/// Used to restyle `SubjectCard` and the material/course list tiles across
/// the department/course/subject detail screens.
class CompactListRow extends StatelessWidget {
  const CompactListRow({
    super.key,
    required this.title,
    required this.icon,
    required this.tint,
    this.subtitle,
    this.iconBackgroundColor,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.isPending = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color tint;
  final Color? iconBackgroundColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: isPending ? 0.6 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isPending ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: dense ? 8 : 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor ?? tint.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: tint),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle(context).copyWith(fontSize: 14),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.cardSubtitle(context),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
