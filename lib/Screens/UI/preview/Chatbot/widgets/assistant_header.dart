import 'package:flutter/material.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact custom header shared by the assistant chat screens, replacing
/// the old blurred `AppBar`. Shows a round gradient sparkle avatar, the
/// screen title with a "BETA" pill, a status line, and up to three
/// trailing actions: restart (new chat), an overflow (⋮) menu, and a
/// collapse chevron.
class AssistantHeader extends StatelessWidget {
  const AssistantHeader({
    super.key,
    required this.title,
    required this.status,
    this.onRestart,
    this.onCollapse,
    this.menuItems = const [],
    this.onMenuSelected,
  });

  final String title;
  final String status;

  /// Restart / "new chat" action. Hidden when null.
  final VoidCallback? onRestart;

  /// Collapse action — returns to the previous tab (online) or pops the
  /// route (offline). Hidden when null.
  final VoidCallback? onCollapse;

  /// Entries for the overflow (⋮) menu. The button is hidden when empty.
  final List<PopupMenuEntry<String>> menuItems;
  final ValueChanged<String>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final onSurface = theme.colorScheme.onSurface;
    final iconColor = onSurface.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          const _SparkleAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.assistantBetaBadge,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34C759),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onRestart != null)
            IconButton(
              tooltip: l10n.newChatButton,
              icon: const Icon(Icons.refresh_rounded),
              color: iconColor,
              onPressed: onRestart,
            ),
          if (menuItems.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: iconColor),
              onSelected: onMenuSelected,
              itemBuilder: (_) => menuItems,
            ),
          if (onCollapse != null)
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              color: iconColor,
              onPressed: onCollapse,
            ),
        ],
      ),
    );
  }
}

class _SparkleAvatar extends StatelessWidget {
  const _SparkleAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF9B72F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 22,
        color: Colors.white,
      ),
    );
  }
}
