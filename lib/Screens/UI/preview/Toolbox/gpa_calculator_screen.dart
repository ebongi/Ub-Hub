import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GPACalculatorScreen extends StatefulWidget {
  const GPACalculatorScreen({super.key});

  @override
  State<GPACalculatorScreen> createState() => _GPACalculatorScreenState();
}

class _GPACalculatorScreenState extends State<GPACalculatorScreen> {
  bool _isUG = true;
  final List<CourseGPA> _courses = [
    CourseGPA(name: "Linear Algebra", credits: 3, grade: "B-"),
    CourseGPA(name: "Software Engineering 311", credits: 3, grade: "B"),
    CourseGPA(name: "Introduction To Database", credits: 3, grade: "A-"),
    CourseGPA(name: "Data Structures and Algorithms", credits: 3, grade: "A"),
  ];

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

  final List<int> _creditValues = [1, 2, 3, 4, 5, 6];

  double get _totalGpa {
    double totalPoints = 0;
    int totalCredits = 0;
    for (var course in _courses) {
      totalPoints += (_gradePoints[course.grade] ?? 0) * course.credits;
      totalCredits += course.credits;
    }
    return totalCredits == 0 ? 0 : totalPoints / totalCredits;
  }

  void _addCourse() {
    setState(() {
      _courses.add(CourseGPA(name: "New Course", credits: 3, grade: "A"));
    });
  }

  void _reset() {
    setState(() {
      _courses.clear();
      _addCourse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "GPA Calculator",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // UG/MBA Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUG = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isUG ? primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "UG",
                          style: GoogleFonts.outfit(
                            color: _isUG
                                ? Colors.white
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUG = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isUG ? primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "MBA",
                          style: GoogleFonts.outfit(
                            color: !_isUG
                                ? Colors.white
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Course List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _courses.length + 1,
              itemBuilder: (context, index) {
                if (index == _courses.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 80),
                    child: InkWell(
                      onTap: _addCourse,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Icon(Icons.add, color: primaryColor, size: 30),
                      ),
                    ),
                  );
                }

                final course = _courses[index];
                final coursePoints =
                    (_gradePoints[course.grade] ?? 0) * course.credits;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: course.name,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                hintText: "Course Name",
                              ),
                              onChanged: (val) => course.name = val,
                            ),
                          ),
                          Text(
                            coursePoints.toStringAsFixed(2),
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              context,
                              "Credit",
                              course.credits.toString(),
                              _creditValues.map((e) => e.toString()).toList(),
                              (val) {
                                if (val != null) {
                                  setState(
                                    () => course.credits = int.parse(val),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              context,
                              "Grade",
                              course.grade,
                              _gradePoints.keys.toList(),
                              (val) {
                                if (val != null) {
                                  setState(() => course.grade = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
        ),
        child: Row(
          children: [
            // Reset Button
            InkWell(
              onTap: _reset,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
              ),
            ),
            const SizedBox(width: 16),
            // Calculate Button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: theme.cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Text(
                        "Calculation Result",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Your Cumulative GPA is",
                            style: GoogleFonts.outfit(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _totalGpa.toStringAsFixed(2),
                            style: GoogleFonts.outfit(
                              color: primaryColor,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isUG ? "Undergraduate Level" : "Graduate Level",
                            style: GoogleFonts.outfit(color: Colors.grey),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Close",
                            style: GoogleFonts.outfit(color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Calculate",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -8,
            left: 0,
            child: Container(
              color: Theme.of(context).cardTheme.color,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              items: items.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
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
