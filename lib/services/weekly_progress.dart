import 'package:go_study/services/exam_event.dart';
import 'package:go_study/services/task_model.dart';

/// Pure logic backing the Weekly Progress home card: week/date math, per-day
/// task aggregation, day-status classification, and summary-row message
/// selection. No Flutter imports — unit-testable with a bare `test()` and fixed
/// [DateTime]s.

/// Strips the time component, keeping the calendar day in local time.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday 00:00 (local) of the week containing [d].
/// [DateTime.weekday] is Mon=1 .. Sun=7.
DateTime mondayOf(DateTime d) {
  final base = dateOnly(d);
  return DateTime(base.year, base.month, base.day - (d.weekday - 1));
}

/// Calendar-day arithmetic (DST-safe — never uses `Duration(days:)`, so it
/// always lands on local 00:00 and normalises month/year overflow).
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

enum DayStatus {
  /// Past day: nothing was completed and nothing is still outstanding.
  rest,

  /// Past day: nothing completed that day but tasks due then remain undone.
  missed,

  /// Past day: at least one task was completed on that day.
  done,

  /// The current day.
  today,

  /// A day still to come.
  future,
}

/// Task counts for a single day of the shown week.
class DayProgress {
  const DayProgress({
    required this.date,
    required this.dueTotal,
    required this.dueRemaining,
    required this.completedHere,
  });

  /// Local midnight of the day.
  final DateTime date;

  /// Tasks whose deadline falls on this day.
  final int dueTotal;

  /// [dueTotal] that are not yet done.
  final int dueRemaining;

  /// Tasks whose `completed_at` falls on this day (regardless of their deadline).
  final int completedHere;

  int get dueCompleted => dueTotal - dueRemaining;
  bool get hasDue => dueTotal > 0;
}

class WeeklyProgressData {
  const WeeklyProgressData({required this.days, required this.nextExam});

  /// Exactly 7 entries, Monday .. Sunday.
  final List<DayProgress> days;

  /// Soonest still-upcoming active exam, or null.
  final ExamEvent? nextExam;
}

/// Buckets [tasks] into the seven days of the week starting at [weekStart], and
/// finds the next upcoming exam relative to [now].
WeeklyProgressData computeWeeklyProgress({
  required DateTime weekStart,
  required DateTime now,
  required List<TodoTask> tasks,
  required List<ExamEvent> exams,
}) {
  final start = mondayOf(weekStart); // normalise defensively
  final days = List<DateTime>.generate(7, (i) => addDays(start, i));

  final dueTotal = List<int>.filled(7, 0);
  final dueRemaining = List<int>.filled(7, 0);
  final completedHere = List<int>.filled(7, 0);

  int? indexFor(DateTime dt) {
    final d = dateOnly(dt.toLocal());
    for (var i = 0; i < 7; i++) {
      if (days[i] == d) return i;
    }
    return null;
  }

  for (final t in tasks) {
    final dl = t.deadline;
    if (dl != null) {
      final i = indexFor(dl);
      if (i != null) {
        dueTotal[i]++;
        if (!t.isDone) dueRemaining[i]++;
      }
    }
    final c = t.completedAt;
    if (c != null) {
      final i = indexFor(c);
      if (i != null) completedHere[i]++;
    }
  }

  final dayProgress = <DayProgress>[
    for (var i = 0; i < 7; i++)
      DayProgress(
        date: days[i],
        dueTotal: dueTotal[i],
        dueRemaining: dueRemaining[i],
        completedHere: completedHere[i],
      ),
  ];

  // `exams` arrives ordered by start_time ascending, so the first one still
  // running or yet to start is the soonest. `for`/`break`, not `firstWhere`
  // (which throws when nothing matches).
  ExamEvent? nextExam;
  for (final e in exams) {
    if (e.status != 'active') continue;
    if (e.endTime.toLocal().isAfter(now)) {
      nextExam = e;
      break;
    }
  }

  return WeeklyProgressData(days: dayProgress, nextExam: nextExam);
}

/// Classifies a day for its status glyph.
DayStatus dayStatusFor(DayProgress day, DateTime now) {
  final today = dateOnly(now);
  final d = dateOnly(day.date);
  if (d == today) return DayStatus.today;
  if (d.isAfter(today)) return DayStatus.future;
  if (day.completedHere > 0) return DayStatus.done;
  if (day.dueRemaining > 0) return DayStatus.missed;
  return DayStatus.rest;
}

/// Which summary-row-1 message applies to the selected day, plus the count that
/// feeds its plural. The widget maps [Row1Bucket] to a localized string.
enum Row1Bucket {
  noTasksToday,
  remainingToday,
  noTasksYesterday,
  completedYesterday,
  noTasksOnPastDate,
  completedOnPastDate,
  nothingTomorrow,
  dueTomorrow,
  nothingOnFutureDate,
  dueOnFutureDate,
}

class Row1Spec {
  const Row1Spec(this.bucket, this.count);
  final Row1Bucket bucket;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is Row1Spec && other.bucket == bucket && other.count == count;

  @override
  int get hashCode => Object.hash(bucket, count);

  @override
  String toString() => 'Row1Spec($bucket, $count)';
}

/// Picks the summary-row-1 message for [day]. Relative wording
/// ("yesterday"/"today"/"tomorrow") is only used within the current week;
/// other days fall back to a dated phrasing.
Row1Spec summaryRow1For({
  required DayProgress day,
  required DateTime now,
  required bool isCurrentWeek,
}) {
  final today = dateOnly(now);
  final sel = dateOnly(day.date);

  if (sel == today) {
    if (day.dueTotal == 0) return const Row1Spec(Row1Bucket.noTasksToday, 0);
    return Row1Spec(Row1Bucket.remainingToday, day.dueRemaining);
  }

  if (sel.isBefore(today)) {
    final isYesterday = isCurrentWeek && sel == addDays(today, -1);
    if (day.completedHere == 0 && day.dueTotal == 0) {
      return Row1Spec(
        isYesterday
            ? Row1Bucket.noTasksYesterday
            : Row1Bucket.noTasksOnPastDate,
        0,
      );
    }
    return Row1Spec(
      isYesterday
          ? Row1Bucket.completedYesterday
          : Row1Bucket.completedOnPastDate,
      day.completedHere,
    );
  }

  // future
  final isTomorrow = isCurrentWeek && sel == addDays(today, 1);
  if (day.dueTotal == 0) {
    return Row1Spec(
      isTomorrow ? Row1Bucket.nothingTomorrow : Row1Bucket.nothingOnFutureDate,
      0,
    );
  }
  return Row1Spec(
    isTomorrow ? Row1Bucket.dueTomorrow : Row1Bucket.dueOnFutureDate,
    day.dueTotal,
  );
}
