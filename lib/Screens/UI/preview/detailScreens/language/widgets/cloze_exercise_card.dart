import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/language_exercise.dart';

class ClozeExerciseCard extends StatefulWidget {
  final LanguageExercise exercise;
  final ValueChanged<bool> onCompleted;

  const ClozeExerciseCard({
    super.key,
    required this.exercise,
    required this.onCompleted,
  });

  @override
  State<ClozeExerciseCard> createState() => _ClozeExerciseCardState();
}

class _ClozeExerciseCardState extends State<ClozeExerciseCard> {
  String? _selected;
  bool _submitted = false;

  void _check() {
    if (_selected == null || _submitted) return;
    setState(() => _submitted = true);
    widget.onCompleted(_selected == widget.exercise.targetAnswer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final exercise = widget.exercise;
    final options = exercise.options ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            exercise.sourceText,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...options.map((option) => _buildOptionTile(option, theme)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _selected != null && !_submitted ? _check : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(l10n.checkAnswerButton),
        ),
      ],
    );
  }

  Widget _buildOptionTile(String option, ThemeData theme) {
    final exercise = widget.exercise;
    final isSelected = _selected == option;
    final isCorrect = option == exercise.targetAnswer;

    Color tileColor = theme.cardColor;
    if (_submitted) {
      if (isCorrect) {
        tileColor = Colors.green.withOpacity(0.2);
      } else if (isSelected) {
        tileColor = Colors.red.withOpacity(0.2);
      }
    } else if (isSelected) {
      tileColor = theme.colorScheme.primary.withOpacity(0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _submitted ? null : () => setState(() => _selected = option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (_submitted && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green),
              if (_submitted && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
