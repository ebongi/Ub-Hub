import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/gemini_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:neo/services/task_model.dart';
import 'package:neo/services/exam_event.dart';

class AIStudyPlanScreen extends StatefulWidget {
  const AIStudyPlanScreen({super.key});

  @override
  State<AIStudyPlanScreen> createState() => _AIStudyPlanScreenState();
}

class _AIStudyPlanScreenState extends State<AIStudyPlanScreen> {
  final GeminiService _geminiService = GeminiService();
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _studyPlan;
  String? _error;

  DatabaseService get _dbService {
    final user = _supabase.auth.currentUser;
    return DatabaseService(uid: user?.id);
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Get tasks and exams
      final List<TodoTask> tasks = await _dbService.tasks.first;
      final List<ExamEvent> exams = await _dbService.exams.first;

      // 2. Filter active tasks and upcoming exams
      final List<TodoTask> activeTasks = tasks.where((t) => !t.isDone).toList();
      final List<ExamEvent> upcomingExams = exams
          .where((e) => e.startTime.isAfter(DateTime.now()))
          .toList();

      // 3. Generate plan
      final plan = await _geminiService.generateStudyPlan(
        tasks: activeTasks,
        exams: upcomingExams,
      );

      setState(() {
        _studyPlan = plan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to generate plan: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "AI Study Plan",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_studyPlan != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _generatePlan,
              tooltip: "Regenerate Plan",
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    "Gemini is analyzing your schedule...",
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _studyPlan == null
          ? _buildInitialState(theme)
          : _buildPlanView(theme),
    );
  }

  Widget _buildInitialState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            "Ready for a Smarter Study Session?",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "I'll analyze your pending tasks and upcoming exams to create a balanced routine just for you.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _generatePlan,
            icon: const Icon(Icons.bolt_rounded),
            label: const Text("GENERATE MY PLAN"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 20),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanView(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Markdown(
            data: _studyPlan!,
            styleSheet: MarkdownStyleSheet(
              h1: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
              h2: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
              p: GoogleFonts.outfit(fontSize: 16),
              listBullet: GoogleFonts.outfit(fontSize: 16),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "This plan is AI-generated and for guidance only.",
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
