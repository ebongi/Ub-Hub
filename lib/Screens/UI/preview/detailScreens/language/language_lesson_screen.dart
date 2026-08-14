import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/language_exercise.dart';
import 'package:go_study/services/language_progress_service.dart';

import 'widgets/cloze_exercise_card.dart';
import 'widgets/matching_exercise_card.dart';
import 'widgets/word_bank_exercise_card.dart';

class LanguageLessonScreen extends StatefulWidget {
  final LanguageTrack track;
  final String level;
  final List<LanguageExercise> exercises;

  const LanguageLessonScreen({
    super.key,
    required this.track,
    required this.level,
    required this.exercises,
  });

  @override
  State<LanguageLessonScreen> createState() => _LanguageLessonScreenState();
}

class _LanguageLessonScreenState extends State<LanguageLessonScreen> {
  final _progressService = LanguageProgressService();

  int _currentIndex = 0;
  int _score = 0;
  bool? _answeredCorrectly;
  bool _completed = false;

  void _handleAnswered(LanguageExercise exercise, bool correct) {
    setState(() {
      _answeredCorrectly = correct;
      if (correct) _score++;
    });
    if (correct) {
      _progressService.markCompleted(widget.track, [exercise.id]);
    }
  }

  void _goNext() {
    if (_currentIndex == widget.exercises.length - 1) {
      setState(() => _completed = true);
      return;
    }
    setState(() {
      _currentIndex++;
      _answeredCorrectly = null;
    });
  }

  Widget _buildExerciseWidget(LanguageExercise exercise) {
    switch (exercise.exerciseType) {
      case ExerciseType.cloze:
        return ClozeExerciseCard(
          key: ValueKey(exercise.id),
          exercise: exercise,
          onCompleted: (correct) => _handleAnswered(exercise, correct),
        );
      case ExerciseType.wordBank:
        return WordBankExerciseCard(
          key: ValueKey(exercise.id),
          exercise: exercise,
          onCompleted: (correct) => _handleAnswered(exercise, correct),
        );
      case ExerciseType.matching:
        return MatchingExerciseCard(
          key: ValueKey(exercise.id),
          exercise: exercise,
          onCompleted: (correct) => _handleAnswered(exercise, correct),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final total = widget.exercises.length;

    if (total == 0) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.practiceTabLabel)),
        body: Center(child: Text(l10n.noQuestionsInQuiz)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _completed
              ? l10n.resultsTitle
              : l10n.questionCounterTitle(_currentIndex + 1, total),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _completed ? _buildResults(theme, l10n) : _buildLessonBody(theme, l10n, total),
    );
  }

  Widget _buildLessonBody(ThemeData theme, AppLocalizations l10n, int total) {
    final exercise = widget.exercises[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / total,
            backgroundColor: theme.dividerColor,
          ),
          const SizedBox(height: 20),
          Text(
            exercise.prompt,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildExerciseWidget(exercise),
                  if (_answeredCorrectly != null) ...[
                    const SizedBox(height: 20),
                    _buildExplanationCard(theme, exercise),
                  ],
                ],
              ),
            ),
          ),
          if (_answeredCorrectly != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _goNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(l10n.continueButton),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationCard(ThemeData theme, LanguageExercise exercise) {
    final isDark = theme.brightness == Brightness.dark;
    final correct = _answeredCorrectly == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (correct ? Colors.green : Colors.orange).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: correct ? Colors.green : Colors.orange),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
            color: correct ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              exercise.explanation,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, AppLocalizations l10n) {
    final total = widget.exercises.length;
    final percentage = (_score / total) * 100;

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            percentage >= 50 ? Icons.emoji_events_rounded : Icons.psychology_rounded,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            percentage >= 50 ? l10n.greatJobTitle : l10n.keepStudyingTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.youScoredOutOfLabel(_score, total),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.accuracyPercentLabel(percentage.toInt()),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: percentage >= 50 ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text(l10n.doneButton),
          ),
        ],
      ),
    );
  }
}
