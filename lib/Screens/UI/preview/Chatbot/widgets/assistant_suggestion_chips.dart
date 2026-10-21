import 'package:flutter/material.dart';
import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:google_fonts/google_fonts.dart';

/// Row of white pill suggestions shown just above the input while a
/// conversation is empty (the "Create flashcards from a file" etc. chips).
class AssistantSuggestionChips extends StatelessWidget {
  const AssistantSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: suggestions.map((text) {
          return ScaleButton(
            onTap: () => onTap(text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1F20) : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
