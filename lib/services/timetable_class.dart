import 'package:go_study/services/timetable_entry.dart';

/// One slot of the published faculty timetable (a `timetable_classes` row).
class TimetableClass {
  final String department;
  final String program;

  /// As listed, including any lab-group suffix (`MAT211-G1`).
  final String courseCode;
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String? hall;
  final String? lecturers;

  const TimetableClass({
    required this.department,
    required this.program,
    required this.courseCode,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.hall,
    this.lecturers,
  });

  factory TimetableClass.fromSupabase(Map<String, dynamic> json) {
    return TimetableClass(
      department: json['department'] ?? '',
      program: json['program'] ?? '',
      courseCode: json['course_code'] ?? '',
      dayOfWeek: json['day_of_week'] as int,
      startMinutes: TimetableEntry.parseTime(json['start_time'] as String),
      endMinutes: TimetableEntry.parseTime(json['end_time'] as String),
      hall: json['hall'],
      lecturers: json['lecturers'],
    );
  }

  /// For [TimetableService] ("ongoing / next class") maths.
  TimetableEntry toEntry() => TimetableEntry(
        userId: '',
        courseCode: courseCode,
        title: courseCode,
        lecturer: lecturers,
        venue: hall,
        dayOfWeek: dayOfWeek,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        source: 'import',
      );
}
