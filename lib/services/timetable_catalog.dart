import 'package:go_study/services/timetable_class.dart';

/// A selectable course: every timetable slot that shares one course code.
class TimetableCourse {
  final String code;
  final String department;
  final List<TimetableClass> slots;

  const TimetableCourse(this.code, this.department, this.slots);
}

/// The published timetable grouped for the Settings picker
/// (departments -> courses), with search and filtering. Pure, so it's easy
/// to test and cheap to rebuild on every keystroke (a few hundred rows).
class TimetableCatalog {
  final List<String> departments;
  final List<TimetableCourse> courses;

  TimetableCatalog._(this.departments, this.courses);

  factory TimetableCatalog.from(List<TimetableClass> classes) {
    final byCode = <String, List<TimetableClass>>{};
    for (final c in classes) {
      byCode.putIfAbsent(c.courseCode, () => []).add(c);
    }

    final courses =
        byCode.entries.map((e) {
          final slots = [...e.value]
            ..sort((a, b) {
              final d = a.dayOfWeek.compareTo(b.dayOfWeek);
              return d != 0 ? d : a.startMinutes.compareTo(b.startMinutes);
            });
          return TimetableCourse(e.key, slots.first.department, slots);
        }).toList()..sort((a, b) {
          final d = a.department.compareTo(b.department);
          return d != 0 ? d : a.code.compareTo(b.code);
        });

    final departments = courses.map((c) => c.department).toSet().toList()
      ..sort();
    return TimetableCatalog._(departments, courses);
  }

  static String _norm(String s) =>
      s.toUpperCase().replaceAll(RegExp(r'[\s-]+'), '');

  /// Courses matching [query] (course code, ignoring case/spaces/dashes, so
  /// "csc 301" and "MAT211G1" both work), limited to [departments] when
  /// non-empty and to [onlyCodes] when given.
  List<TimetableCourse> filter({
    String query = '',
    Set<String> departments = const {},
    Set<String>? onlyCodes,
  }) {
    final q = _norm(query);
    return courses.where((c) {
      if (departments.isNotEmpty && !departments.contains(c.department)) {
        return false;
      }
      if (onlyCodes != null && !onlyCodes.contains(c.code)) return false;
      if (q.isNotEmpty && !_norm(c.code).contains(q)) return false;
      return true;
    }).toList();
  }

  /// Courses among [codes] whose slots overlap another chosen course's slots
  /// (same weekday, overlapping time). Maps each clashing code to the other
  /// codes it clashes with; courses with no clash are absent. Lab/practical
  /// blocks that run all day are ignored — they coexist with lectures.
  Map<String, Set<String>> clashes(Set<String> codes) {
    final chosen = [
      for (final c in courses)
        if (codes.contains(c.code)) c,
    ];
    final result = <String, Set<String>>{};
    for (var i = 0; i < chosen.length; i++) {
      for (var j = i + 1; j < chosen.length; j++) {
        if (_overlap(chosen[i], chosen[j])) {
          result.putIfAbsent(chosen[i].code, () => {}).add(chosen[j].code);
          result.putIfAbsent(chosen[j].code, () => {}).add(chosen[i].code);
        }
      }
    }
    return result;
  }

  static const _allDayMinutes = 10 * 60;

  static bool _overlap(TimetableCourse a, TimetableCourse b) {
    for (final x in a.slots) {
      if (x.endMinutes - x.startMinutes >= _allDayMinutes) continue;
      for (final y in b.slots) {
        if (y.endMinutes - y.startMinutes >= _allDayMinutes) continue;
        if (x.dayOfWeek == y.dayOfWeek &&
            x.startMinutes < y.endMinutes &&
            y.startMinutes < x.endMinutes) {
          return true;
        }
      }
    }
    return false;
  }

  /// All slots for the given course codes (for scheduling reminders).
  List<TimetableClass> slotsFor(Set<String> codes) => [
    for (final c in courses)
      if (codes.contains(c.code)) ...c.slots,
  ];
}
