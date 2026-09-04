import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';

class QuizViewScreen extends StatefulWidget {
  final Map<String, dynamic> quizData;

  const QuizViewScreen({super.key, required this.quizData});

  @override
  State<QuizViewScreen> createState() => _QuizViewScreenState();
}

class _QuizViewScreenState extends State<QuizViewScreen> {
  late List<dynamic> _questions;
  int _currentIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  String? _selectedOption;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _questions = widget.quizData['questions'] ?? [];
  }

  void _submitAnswer() {
    if (_selectedOption == null) return;

    final correctAnswer = _questions[_currentIndex]['answer'];
    if (_selectedOption == correctAnswer) {
      _score++;
    }

    setState(() {
      _showFeedback = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = null;
          _showFeedback = false;
        });
      } else {
        setState(() {
          _quizCompleted = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.quizTitle)),
        body: Center(child: Text(l10n.noQuestionsInQuiz)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _quizCompleted
              ? l10n.resultsTitle
              : l10n.questionCounterTitle(_currentIndex + 1, _questions.length),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _quizCompleted ? _buildResults(theme, l10n) : _buildQuizBody(theme, l10n),
    );
  }

  Widget _buildQuizBody(ThemeData theme, AppLocalizations l10n) {
    final currentQuestion = _questions[_currentIndex];
    final List<dynamic> options = currentQuestion['options'] ?? [];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: theme.dividerColor,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    currentQuestion['question'] ?? "",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ...options.map((option) => _buildOptionTile(option, theme)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _selectedOption != null && !_showFeedback
                ? _submitAnswer
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(l10n.submitAnswerButton),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String option, ThemeData theme) {
    bool isSelected = _selectedOption == option;
    bool isCorrect = option == _questions[_currentIndex]['answer'];

    Color tileColor = theme.cardColor;
    if (_showFeedback) {
      if (isCorrect) {
        tileColor = Colors.green.withOpacity(0.2);
      } else if (isSelected)
        tileColor = Colors.red.withOpacity(0.2);
    } else if (isSelected) {
      tileColor = theme.colorScheme.primary.withOpacity(0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: _showFeedback
            ? null
            : () => setState(() => _selectedOption = option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              if (_showFeedback && isCorrect) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.green),
              ],
              if (_showFeedback && isSelected && !isCorrect) ...[
                const SizedBox(width: 8),
                const Icon(Icons.cancel, color: Colors.red),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme, AppLocalizations l10n) {
    double percentage = (_score / _questions.length) * 100;

    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            percentage >= 50
                ? Icons.emoji_events_rounded
                : Icons.psychology_rounded,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            percentage >= 50 ? l10n.greatJobTitle : l10n.keepStudyingTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.youScoredOutOfLabel(_score, _questions.length),
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(l10n.backToGeneratorButton),
          ),
        ],
      ),
    );
  }
}
