import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/language_exercise.dart';
import 'package:go_study/services/language_exercise_service.dart';
import 'package:go_study/services/language_progress_service.dart';

import 'language_lesson_screen.dart';

class LanguagePracticeTab extends StatefulWidget {
  final LanguageTrack track;

  const LanguagePracticeTab({super.key, required this.track});

  @override
  State<LanguagePracticeTab> createState() => _LanguagePracticeTabState();
}

class _LanguagePracticeTabState extends State<LanguagePracticeTab> {
  final _exerciseService = LanguageExerciseService();
  final _progressService = LanguageProgressService();

  late Future<void> _loadFuture;
  Map<String, List<LanguageExercise>>? _byLevel;
  Set<String> _completedIds = {};
  String _selectedLevel = LanguageExercise.levels.first;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final byLevel = await _exerciseService.byLevelForTrack(widget.track);
    final completed = await _progressService.getCompleted(widget.track);
    if (!mounted) return;
    setState(() {
      _byLevel = byLevel;
      _completedIds = completed;
    });
  }

  Future<void> _startLesson() async {
    final exercises = _byLevel?[_selectedLevel] ?? const [];
    if (exercises.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LanguageLessonScreen(
          track: widget.track,
          level: _selectedLevel,
          exercises: exercises,
        ),
      ),
    );

    final completed = await _progressService.getCompleted(widget.track);
    if (!mounted) return;
    setState(() => _completedIds = completed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || _byLevel == null) {
          return Center(
            child: Text(l10n.errorLoadingMessages(snapshot.error.toString())),
          );
        }

        final byLevel = _byLevel!;
        final selectedExercises = byLevel[_selectedLevel] ?? const [];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.track == LanguageTrack.frForEn
                  ? l10n.frenchForEnglishSpeakersTitle
                  : l10n.englishForFrenchSpeakersTitle,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.selectLevelLabel,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: LanguageExercise.levels.map((level) {
                final exercises = byLevel[level] ?? const [];
                final completedCount =
                    exercises.where((e) => _completedIds.contains(e.id)).length;
                final isSelected = level == _selectedLevel;

                return ChoiceChip(
                  label: Text('$level  ($completedCount/${exercises.length})'),
                  selected: isSelected,
                  labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.cardColor,
                  onSelected: (_) => setState(() => _selectedLevel = level),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: selectedExercises.isEmpty ? null : _startLesson,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(l10n.startLessonButton),
            ),
          ],
        );
      },
    );
  }
}
