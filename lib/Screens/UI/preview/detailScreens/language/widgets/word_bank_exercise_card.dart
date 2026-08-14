import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/language_exercise.dart';

class WordBankExerciseCard extends StatefulWidget {
  final LanguageExercise exercise;
  final ValueChanged<bool> onCompleted;

  const WordBankExerciseCard({
    super.key,
    required this.exercise,
    required this.onCompleted,
  });

  @override
  State<WordBankExerciseCard> createState() => _WordBankExerciseCardState();
}

class _WordBankExerciseCardState extends State<WordBankExerciseCard> {
  late List<int> _bankOrder;
  final List<int> _selectedIndices = [];
  bool _submitted = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    final wordBank = widget.exercise.wordBank ?? const [];
    _bankOrder = List<int>.generate(wordBank.length, (i) => i)..shuffle();
  }

  void _addChip(int index) {
    if (_submitted) return;
    setState(() => _selectedIndices.add(index));
  }

  void _removeChip(int index) {
    if (_submitted) return;
    setState(() => _selectedIndices.remove(index));
  }

  void _check() {
    final wordBank = widget.exercise.wordBank ?? const [];
    final targetTokens = widget.exercise.wordBankAnswerTokens;
    if (_selectedIndices.length != targetTokens.length || _submitted) return;

    final selectedWords = _selectedIndices.map((i) => wordBank[i]).toList();
    var correct = true;
    for (var i = 0; i < targetTokens.length; i++) {
      if (selectedWords[i] != targetTokens[i]) {
        correct = false;
        break;
      }
    }

    setState(() {
      _submitted = true;
      _isCorrect = correct;
    });
    widget.onCompleted(correct);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final exercise = widget.exercise;
    final wordBank = exercise.wordBank ?? const [];
    final targetTokens = exercise.wordBankAnswerTokens;
    final canCheck = _selectedIndices.length == targetTokens.length && !_submitted;

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
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _selectedIndices.length; i++)
                _buildAnswerChip(
                  index: _selectedIndices[i],
                  position: i,
                  wordBank: wordBank,
                  targetTokens: targetTokens,
                  theme: theme,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final index in _bankOrder)
              if (!_selectedIndices.contains(index))
                _buildBankChip(index, wordBank, theme),
          ],
        ),
        if (_submitted && !_isCorrect) ...[
          const SizedBox(height: 16),
          Text(
            l10n.correctAnswerLabel(exercise.targetAnswer),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: canCheck ? _check : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: Text(l10n.checkAnswerButton),
        ),
      ],
    );
  }

  Widget _buildBankChip(int index, List<String> wordBank, ThemeData theme) {
    return ScaleTapChip(
      onTap: () => _addChip(index),
      label: wordBank[index],
      backgroundColor: theme.cardColor,
      borderColor: theme.dividerColor,
    );
  }

  Widget _buildAnswerChip({
    required int index,
    required int position,
    required List<String> wordBank,
    required List<String> targetTokens,
    required ThemeData theme,
  }) {
    Color background = theme.colorScheme.primary.withOpacity(0.1);
    Color border = theme.colorScheme.primary;
    if (_submitted) {
      final isPositionCorrect = position < targetTokens.length &&
          wordBank[index] == targetTokens[position];
      background = (isPositionCorrect ? Colors.green : Colors.red).withOpacity(0.15);
      border = isPositionCorrect ? Colors.green : Colors.red;
    }

    return ScaleTapChip(
      onTap: () => _removeChip(index),
      label: wordBank[index],
      backgroundColor: background,
      borderColor: border,
    );
  }
}

class ScaleTapChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;

  const ScaleTapChip({
    super.key,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
