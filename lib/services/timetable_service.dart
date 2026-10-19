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

/// What's happening right now: the class in session (if any) and the next
/// one to start (if any). Both can be set at once, e.g. mid-lecture with
/// another class later today.
class TimetableStatus {
  final ClassOccurrence? ongoing;
  final ClassOccurrence? next;

  const TimetableStatus({this.ongoing, this.next});

  bool get isEmpty => ongoing == null && next == null;
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

  static TimetableStatus statusAt(
    List<TimetableEntry> entries,
    DateTime now,
  ) {
    ClassOccurrence? ongoing;
    ClassOccurrence? next;

    final valid = entries.where((e) => e.isValid).toList();
    final today = DateTime(now.year, now.month, now.day);

    // 8 days covers today plus a full week ahead, so a lone weekly class that
    // already ended today resolves to the same slot next week.
    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      for (final entry in valid.where((e) => e.dayOfWeek == day.weekday)) {
        final occ = _on(entry, day);
        if (!occ.start.isAfter(now) && occ.end.isAfter(now)) {
          // Overlapping slots: prefer the one that started most recently.
          if (ongoing == null || occ.start.isAfter(ongoing.start)) {
            ongoing = occ;
          }
        } else if (occ.start.isAfter(now)) {
          if (next == null || occ.start.isBefore(next.start)) next = occ;
        }
      }
      if (next != null) {
        // Anything on a later day starts later, so the first day with an
        // upcoming class holds the earliest one.
        break;
      }
    }

    return TimetableStatus(ongoing: ongoing, next: next);
  }

  /// All slots for one ISO weekday, earliest first.
  static List<TimetableEntry> forDay(List<TimetableEntry> entries, int weekday) {
    return entries.where((e) => e.dayOfWeek == weekday).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  }
}
