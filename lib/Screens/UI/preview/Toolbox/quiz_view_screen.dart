import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz")),
        body: const Center(child: Text("No questions found in this quiz.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _quizCompleted
              ? "Results"
              : "Question ${_currentIndex + 1}/${_questions.length}",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _quizCompleted ? _buildResults(theme) : _buildQuizBody(theme),
    );
  }

  Widget _buildQuizBody(ThemeData theme) {
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
          Text(
            currentQuestion['question'] ?? "",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          ...options.map((option) => _buildOptionTile(option, theme)),
          const Spacer(),
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
            child: const Text("SUBMIT ANSWER"),
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
            children: [
              Text(
                option,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (_showFeedback && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green),
              if (_showFeedback && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
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
            percentage >= 50 ? "Great Job!" : "Keep Studying!",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You scored $_score out of ${_questions.length}",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            "${percentage.toInt()}% Accuracy",
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
            child: const Text("BACK TO GENERATOR"),
          ),
        ],
      ),
    );
  }
}
