import 'package:flutter/material.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

/// The rounded input pill shared by the assistant chat screens, plus the
/// "Thinking… / Stop" row shown above it while a response streams. Sits
/// directly on [AssistantBackground] (no blur, no divider).
class AssistantInputBar extends StatelessWidget {
  const AssistantInputBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSend,
    this.isLoading = false,
    this.onStop,
    this.onAttach,
    this.counterText,
    this.filePreview,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSend;
  final bool isLoading;
  final VoidCallback? onStop;

  /// Leading attach action. Hidden (no icon) when null — e.g. offline chat.
  final VoidCallback? onAttach;

  /// Small text shown just before the send button (remaining messages).
  final String? counterText;

  /// Caller-built horizontal preview of picked files, shown above the pill.
  final Widget? filePreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final pillColor = isDark ? const Color(0xFF1E1F20) : Colors.white;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, isLandscape ? 8 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading) _LoadingPill(onStop: onStop),
          if (filePreview != null) filePreview!,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (onAttach != null)
                  IconButton(
                    icon: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: textColor.withOpacity(0.6),
                    ),
                    onPressed: onAttach,
                  )
                else
                  const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: 10,
                    minLines: 1,
                    style: GoogleFonts.outfit(fontSize: 16, color: textColor),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: GoogleFonts.outfit(
                        color: textColor.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                if (counterText != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      counterText!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor.withOpacity(0.4),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                  onPressed: onSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill({this.onStop});

  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final textColor = theme.colorScheme.onSurface;
    final pillColor = isDark ? const Color(0xFF1E1F20) : Colors.grey[100];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.thinkingLabel,
              style: GoogleFonts.outfit(
                color: textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            if (onStop != null) ...[
              const SizedBox(width: 12),
              Container(width: 1, height: 12, color: textColor.withOpacity(0.1)),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: onStop,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  Icons.stop_circle_rounded,
                  size: 16,
                  color: Colors.red.shade400,
                ),
                label: Text(
                  l10n.stopButton,
                  style: GoogleFonts.outfit(
                    color: Colors.red.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
