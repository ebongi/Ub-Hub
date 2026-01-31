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
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "GPA Calculator",
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // UG/MBA Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUG = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isUG ? cardColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: _isUG
                              ? Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.1),
                                )
                              : null,
                          boxShadow: _isUG && !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isUG)
                              Icon(
                                Icons.check,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                            if (_isUG) const SizedBox(width: 8),
                            Text(
                              "UG",
                              style: GoogleFonts.outfit(
                                color: _isUG
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color
                                    : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.7),
                                fontWeight: _isUG
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUG = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isUG ? cardColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: !_isUG
                              ? Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.1),
                                )
                              : null,
                          boxShadow: !_isUG && !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_isUG)
                              Icon(
                                Icons.check,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                            if (!_isUG) const SizedBox(width: 8),
                            Text(
                              "MBA",
                              style: GoogleFonts.outfit(
                                color: !_isUG
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color
                                    : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.7),
                                fontWeight: !_isUG
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
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
                          color: cardColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Theme.of(context).iconTheme.color,
                          size: 30,
                        ),
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
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    boxShadow: !isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
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
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                filled: false,
                              ),
                              onChanged: (val) => course.name = val,
                            ),
                          ),
                          Text(
                            coursePoints.toStringAsFixed(2),
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        color: Colors.transparent,
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
                  color: isDark
                      ? const Color(0xFF1E3A8A)
                      : Colors.grey[200], // Dark blue or Light grey
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Calculate Button
            Expanded(
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                        ),
                      ),
                      title: Text(
                        "Calculation Result",
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Your Cumulative GPA is",
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _totalGpa.toStringAsFixed(2),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFD97706),
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isUG ? "Undergraduate Level" : "Graduate Level",
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Close",
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706), // Yellow/Orange
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calculate_outlined, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        "Calculate",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey.withOpacity(0.05)
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -10,
            left: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: Theme.of(context).cardColor,
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Theme.of(context).cardColor,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              ),
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
