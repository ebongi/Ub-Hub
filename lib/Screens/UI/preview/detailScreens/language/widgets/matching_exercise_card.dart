import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/language_exercise.dart';

class MatchingExerciseCard extends StatefulWidget {
  final LanguageExercise exercise;
  final ValueChanged<bool> onCompleted;

  const MatchingExerciseCard({
    super.key,
    required this.exercise,
    required this.onCompleted,
  });

  @override
  State<MatchingExerciseCard> createState() => _MatchingExerciseCardState();
}

class _MatchingExerciseCardState extends State<MatchingExerciseCard> {
  late List<int> _leftOrder;
  late List<int> _rightOrder;
  final Set<int> _matchedPairIndices = {};
  int? _selectedLeft;
  int? _selectedRight;
  Set<int> _mismatchFlash = {};
  bool _reportedCompletion = false;

  @override
  void initState() {
    super.initState();
    final pairCount = widget.exercise.pairs?.length ?? 0;
    _leftOrder = List<int>.generate(pairCount, (i) => i)..shuffle();
    _rightOrder = List<int>.generate(pairCount, (i) => i)..shuffle();
  }

  void _tapLeft(int pairIndex) {
    if (_matchedPairIndices.contains(pairIndex) || _mismatchFlash.isNotEmpty) return;
    setState(() => _selectedLeft = pairIndex);
    _tryMatch();
  }

  void _tapRight(int pairIndex) {
    if (_matchedPairIndices.contains(pairIndex) || _mismatchFlash.isNotEmpty) return;
    setState(() => _selectedRight = pairIndex);
    _tryMatch();
  }

  void _tryMatch() {
    if (_selectedLeft == null || _selectedRight == null) return;

    if (_selectedLeft == _selectedRight) {
      final matched = _selectedLeft!;
      setState(() {
        _matchedPairIndices.add(matched);
        _selectedLeft = null;
        _selectedRight = null;
      });
      final total = widget.exercise.pairs?.length ?? 0;
      if (_matchedPairIndices.length == total && !_reportedCompletion) {
        _reportedCompletion = true;
        widget.onCompleted(true);
      }
    } else {
      final wrongLeft = _selectedLeft!;
      final wrongRight = _selectedRight!;
      setState(() => _mismatchFlash = {wrongLeft, wrongRight});
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _mismatchFlash = {};
          _selectedLeft = null;
          _selectedRight = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final pairs = widget.exercise.pairs ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.matchingInstructionLabel,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: _leftOrder
                    .map((i) => _buildTile(
                          pairIndex: i,
                          label: pairs[i].source,
                          isSelected: _selectedLeft == i,
                          theme: theme,
                          onTap: () => _tapLeft(i),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: _rightOrder
                    .map((i) => _buildTile(
                          pairIndex: i,
                          label: pairs[i].target,
                          isSelected: _selectedRight == i,
                          theme: theme,
                          onTap: () => _tapRight(i),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTile({
    required int pairIndex,
    required String label,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final isMatched = _matchedPairIndices.contains(pairIndex);
    final isMismatch = _mismatchFlash.contains(pairIndex);

    Color background = theme.cardColor;
    Color border = theme.dividerColor;
    if (isMatched) {
      background = Colors.green.withOpacity(0.15);
      border = Colors.green;
    } else if (isMismatch) {
      background = Colors.red.withOpacity(0.15);
      border = Colors.red;
    } else if (isSelected) {
      background = theme.colorScheme.primary.withOpacity(0.1);
      border = theme.colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: isMatched ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: isSelected ? 2 : 1),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
