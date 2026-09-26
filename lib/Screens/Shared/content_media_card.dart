import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_text_styles.dart';

/// Coursera-style "big image thumbnail" content card: an image (or a
/// gradient + icon fallback) fills the top of the card with a small
/// circular icon badge overlaid on it, and the title/subtitle/action
/// sit below the image rather than overlaid on it.
///
/// Used for department/subject browsing cards in both grid layouts
/// (wrapped by `DepartmentGridCard`) and horizontal-scroll rows (used
/// directly by `DepartmentSection` on the home feed).
class ContentMediaCard extends StatelessWidget {
  const ContentMediaCard({
    super.key,
    required this.title,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.subtitle,
    this.actionLabel,
    this.imageUrl,
    this.onTap,
    this.isPending = false,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final String? imageUrl;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback? onTap;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.colorScheme.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.15);

    return Opacity(
      opacity: isPending ? 0.6 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Material(
          color: cardColor,
          child: InkWell(
            onTap: isPending ? null : onTap,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 16, color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.cardTitle(context),
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
                        if (actionLabel != null && actionLabel!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                actionLabel!,
                                style: AppText.caption(context)
                                    .copyWith(color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: primaryColor.withOpacity(0.1),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _gradientFallback(),
      );
    }
    return _gradientFallback();
  }

  Widget _gradientFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 36, color: Colors.white.withOpacity(0.35)),
      ),
    );
  }
}
