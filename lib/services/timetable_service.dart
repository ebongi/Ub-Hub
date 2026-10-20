import 'package:go_study/services/timetable_entry.dart';

/// A concrete dated occurrence of a weekly [TimetableEntry].
class ClassOccurrence {
  final TimetableEntry entry;
  final DateTime start;
  final DateTime end;

  const ClassOccurrence(this.entry, this.start, this.end);

  Duration untilStart(DateTime now) => start.difference(now);
  Duration untilEnd(DateTime now) => end.difference(now);
}

/// What's happening right now: every class in session and every class due
/// to start next (the ones sharing the earliest upcoming start time). Both
/// can be non-empty at once, e.g. mid-lecture with another class later today.
class TimetableStatus {
  /// In session now, most recently started first.
  final List<ClassOccurrence> ongoingAll;

  /// Classes starting together at the earliest upcoming start time.
  final List<ClassOccurrence> nextAll;

  const TimetableStatus({this.ongoingAll = const [], this.nextAll = const []});

  /// The primary class in session (the one that started most recently).
  ClassOccurrence? get ongoing => ongoingAll.isEmpty ? null : ongoingAll.first;

  /// The primary next class (first of those starting together).
  ClassOccurrence? get next => nextAll.isEmpty ? null : nextAll.first;

  bool get isEmpty => ongoingAll.isEmpty && nextAll.isEmpty;
}

/// Pure schedule maths — no network or clock access, so it works offline and
/// is trivial to test: pass `now` in. All times are device-local.
class TimetableService {
  const TimetableService._();

  /// Dated occurrence of [entry] on the calendar day of [day]. Built with the
  /// DateTime constructor (not Duration arithmetic) so DST shifts can't move
  /// a class off its wall-clock time.
  static ClassOccurrence _on(TimetableEntry entry, DateTime day) {
    DateTime at(int minutes) =>
        DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
    return ClassOccurrence(entry, at(entry.startMinutes), at(entry.endMinutes));
  }

  static TimetableStatus statusAt(List<TimetableEntry> entries, DateTime now) {
    final ongoing = <ClassOccurrence>[];
    var upcoming = <ClassOccurrence>[];

    final valid = entries.where((e) => e.isValid).toList();
    final today = DateTime(now.year, now.month, now.day);

    // 8 days covers today plus a full week ahead, so a lone weekly class that
    // already ended today resolves to the same slot next week.
    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      for (final entry in valid.where((e) => e.dayOfWeek == day.weekday)) {
        final occ = _on(entry, day);
        if (!occ.start.isAfter(now) && occ.end.isAfter(now)) {
          ongoing.add(occ);
        } else if (occ.start.isAfter(now)) {
          upcoming.add(occ);
        }
      }
      // Anything on a later day starts later, so the first day with an
      // upcoming class holds the earliest start.
      if (upcoming.isNotEmpty) break;
    }

    // Most recently started first; the sort is stable, so ties keep the
    // caller's order.
    ongoing.sort((a, b) => b.start.compareTo(a.start));

    DateTime? earliest;
    for (final o in upcoming) {
      if (earliest == null || o.start.isBefore(earliest)) earliest = o.start;
    }
    upcoming = [
      for (final o in upcoming)
        if (o.start == earliest) o,
    ];

    return TimetableStatus(ongoingAll: ongoing, nextAll: upcoming);
  }

  /// All slots for one ISO weekday, earliest first.
  static List<TimetableEntry> forDay(
    List<TimetableEntry> entries,
    int weekday,
  ) {
    return entries.where((e) => e.dayOfWeek == weekday).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  }
}
