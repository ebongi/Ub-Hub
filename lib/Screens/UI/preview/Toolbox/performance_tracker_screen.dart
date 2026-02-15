import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/grade_model.dart';

class PerformanceTrackerScreen extends StatefulWidget {
  const PerformanceTrackerScreen({super.key});

  @override
  State<PerformanceTrackerScreen> createState() =>
      _PerformanceTrackerScreenState();
}

class _PerformanceTrackerScreenState extends State<PerformanceTrackerScreen> {
  final _currentUser = Supabase.instance.client.auth.currentUser;
  late final DatabaseService _dbService;

  bool _isPredictionMode = false;

  // Real grades from DB
  List<UserGrade> _savedGrades = [];

  // Temporary courses for calculation (used in Calculator side)
  final List<CourseGPA> _tempCourses = [];

  final Map<String, double> _gradePoints = {
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'C-': 1.7,
    'D+': 1.3,
    'D': 1.0,
    'F': 0.0,
  };

  // Prediction variables
  double _targetGPA = 3.5;
  int _plannedCredits = 15;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _currentUser?.id);
    _tempCourses.add(CourseGPA(name: "New Course", credits: 3, grade: "A"));
  }

  double _calculateGPA(List<dynamic> items) {
    double totalPoints = 0;
    int totalCredits = 0;
    for (var item in items) {
      if (item is UserGrade) {
        totalPoints +=
            (_gradePoints[item.grade.toUpperCase()] ?? 0) * item.credits;
        totalCredits += item.credits;
      } else if (item is CourseGPA) {
        totalPoints +=
            (_gradePoints[item.grade.toUpperCase()] ?? 0) * item.credits;
        totalCredits += item.credits;
      }
    }
    return totalCredits == 0 ? 0 : totalPoints / totalCredits;
  }

  int _calculateTotalCredits(List<dynamic> items) {
    int total = 0;
    for (var item in items) {
      if (item is UserGrade) total += item.credits;
      if (item is CourseGPA) total += item.credits;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Performance Tracker",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPredictionMode
                  ? Icons.list_alt_rounded
                  : Icons.auto_graph_rounded,
            ),
            tooltip: _isPredictionMode
                ? "Switch to List"
                : "Switch to Predictor",
            onPressed: () =>
                setState(() => _isPredictionMode = !_isPredictionMode),
          ),
        ],
      ),
      body: StreamBuilder<List<UserGrade>>(
        stream: _dbService.getUserGrades(_currentUser!.id),
        builder: (context, snapshot) {
          _savedGrades = snapshot.data ?? [];
          final currentGPA = _calculateGPA(_savedGrades);
          final totalCredits = _calculateTotalCredits(_savedGrades);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(currentGPA, totalCredits, colorScheme),
                const SizedBox(height: 30),
                if (_isPredictionMode)
                  _buildPredictorView(currentGPA, totalCredits, colorScheme)
                else
                  _buildGradesListView(colorScheme),
              ],
            ),
          );
        },
      ),
      floatingActionButton: !_isPredictionMode
          ? FloatingActionButton.extended(
              onPressed: () => _showAddGradeDialog(),
              label: const Text("Add Grade"),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSummaryCard(double gpa, int credits, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            "Current GPA",
            gpa.toStringAsFixed(2),
            colorScheme.primary,
          ),
          Container(width: 1, height: 40, color: colorScheme.outlineVariant),
          _buildStat(
            "Total Credits",
            credits.toString(),
            colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictorView(
    double currentGPA,
    int currentCredits,
    ColorScheme colorScheme,
  ) {
    // Logic: (CurrentPoints + RequiredPoints) / (CurrentCredits + PlannedCredits) = TargetGPA
    // RequiredPoints = TargetGPA * (CurrentCredits + PlannedCredits) - CurrentPoints
    // AvgRequiredGrade = RequiredPoints / PlannedCredits

    double currentPoints = currentGPA * currentCredits;
    double requiredPoints =
        _targetGPA * (currentCredits + _plannedCredits) - currentPoints;
    double avgRequiredGrade = _plannedCredits > 0
        ? requiredPoints / _plannedCredits
        : 0;

    String advice = "";
    Color adviceColor = colorScheme.primary;

    if (avgRequiredGrade > 4.0) {
      advice = "Mathematically impossible this semester. Try a lower target.";
      adviceColor = Colors.red;
    } else if (avgRequiredGrade < 1.0) {
      advice = "You're doing great! Even a low grade will maintain your goal.";
      adviceColor = Colors.green;
    } else {
      String grade = "C";
      if (avgRequiredGrade >= 3.7) {
        grade = "A- to A";
      } else if (avgRequiredGrade >= 3.3)
        grade = "B+";
      else if (avgRequiredGrade >= 3.0)
        grade = "B";
      else if (avgRequiredGrade >= 2.7)
        grade = "B-";
      advice = "You need an average of $grade to reach $_targetGPA.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Grade Predictor",
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildPredictorSlider(
          "Target GPA",
          _targetGPA,
          1.0,
          4.0,
          (val) => setState(() => _targetGPA = val),
        ),
        _buildPredictorSlider(
          "Planned Credits",
          _plannedCredits.toDouble(),
          1,
          30,
          (val) => setState(() => _plannedCredits = val.toInt()),
        ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: adviceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: adviceColor.withAlpha(50)),
          ),
          child: Column(
            children: [
              const Icon(Icons.psychology_rounded, size: 40),
              const SizedBox(height: 12),
              Text(
                advice,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPredictorSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
            Text(
              value is int ? value.toString() : value.toStringAsFixed(1),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _buildGradesListView(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Semester Results",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_savedGrades.isNotEmpty)
              Text(
                "${_savedGrades.length} Courses",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 15),
        if (_savedGrades.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                "No grades saved yet. Use the '+' button to add your results.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _savedGrades.length,
          itemBuilder: (context, index) {
            final grade = _savedGrades[index];
            return Dismissible(
              key: Key(grade.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _dbService.deleteGrade(grade.id),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    grade.courseName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${grade.credits} Credits • ${grade.semester ?? 'Unknown Semester'}",
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      grade.grade,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  void _showAddGradeDialog() {
    final nameController = TextEditingController();
    int credits = 3;
    String grade = 'A';
    String semester = 'First Semester';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            "Add Course Result",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Course Name",
                    hintText: "e.g. CSC 201",
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  value: credits,
                  decoration: const InputDecoration(labelText: "Credits"),
                  items: [1, 2, 3, 4, 6]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => credits = v!),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: grade,
                  decoration: const InputDecoration(labelText: "Grade"),
                  items: _gradePoints.keys
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => grade = v!),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: semester,
                  decoration: const InputDecoration(labelText: "Semester"),
                  items: ["First Semester", "Second Semester", "Resit"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => semester = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                final newGrade = UserGrade(
                  userId: _currentUser!.id,
                  courseName: nameController.text,
                  credits: credits,
                  grade: grade,
                  semester: semester,
                  createdAt: DateTime.now(),
                );
                await _dbService.saveGrade(newGrade);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save Result"),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseGPA {
  String name;
  int credits;
  String grade;
  CourseGPA({required this.name, required this.credits, required this.grade});
}
