import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/services/exam_event.dart';
import 'package:go_study/services/task_model.dart';
import 'package:go_study/services/weekly_progress.dart';

// Reference week: Mon 31 Aug 2026 .. Sun 6 Sep 2026. "Now" is Wed 2 Sep 2026
// (index 2 in the strip). All DateTimes here are local so `.toLocal()` inside
// the helpers is a no-op — the production UTC-instant path is exercised by that
// call but left out of unit tests to keep them timezone-agnostic.
final DateTime kNow = DateTime(2026, 9, 2, 10, 0);
final DateTime kWeekStart = DateTime(2026, 8, 31);

TodoTask _task({DateTime? deadline, bool isDone = false, DateTime? completedAt}) {
  return TodoTask(
    userId: 'u',
    title: 't',
    deadline: deadline,
    isDone: isDone,
    completedAt: completedAt,
  );
}

ExamEvent _exam({
  required String name,
  required DateTime start,
  DateTime? end,
  String status = 'active',
}) {
  return ExamEvent(
    userId: 'u',
    name: name,
    category: 'Final',
    startTime: start,
    endTime: end ?? start.add(const Duration(hours: 2)),
    status: status,
  );
}

DayProgress _dp({
  DateTime? date,
  int dueTotal = 0,
  int dueRemaining = 0,
  int completedHere = 0,
}) {
  return DayProgress(
    date: date ?? DateTime(2026, 9, 2),
    dueTotal: dueTotal,
    dueRemaining: dueRemaining,
    completedHere: completedHere,
  );
}

void main() {
  group('mondayOf', () {
    test('maps any day of the week to that week\'s Monday at 00:00', () {
      expect(mondayOf(DateTime(2026, 9, 2, 10, 30)), DateTime(2026, 8, 31));
      expect(mondayOf(DateTime(2026, 9, 6, 23, 59)), DateTime(2026, 8, 31)); // Sun
      expect(mondayOf(DateTime(2026, 8, 31)), DateTime(2026, 8, 31)); // Mon
    });

    test('is idempotent', () {
      final m = mondayOf(DateTime(2026, 9, 4, 8));
      expect(mondayOf(m), m);
    });
  });

  group('addDays', () {
    test('crosses month and year boundaries', () {
      expect(addDays(DateTime(2026, 12, 29), 4), DateTime(2027, 1, 2));
      expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    });
  });

  group('computeWeeklyProgress - task bucketing', () {
    WeeklyProgressData run(List<TodoTask> tasks) => computeWeeklyProgress(
          weekStart: kWeekStart,
          now: kNow,
          tasks: tasks,
          exams: const [],
        );

    test('returns 7 days, Monday..Sunday', () {
      final vm = run(const []);
      expect(vm.days.length, 7);
      expect(vm.days.first.date, DateTime(2026, 8, 31));
      expect(vm.days.last.date, DateTime(2026, 9, 6));
    });

    test('open task with a deadline this week counts as due + remaining', () {
      final vm = run([_task(deadline: DateTime(2026, 9, 2, 17))]);
      expect(vm.days[2].dueTotal, 1);
      expect(vm.days[2].dueRemaining, 1);
      expect(vm.days[2].completedHere, 0);
    });

    test('done task counts against its completed_at day, not its deadline', () {
      final vm = run([
        _task(
          deadline: DateTime(2026, 9, 3, 9),
          isDone: true,
          completedAt: DateTime(2026, 8, 31, 20),
        ),
      ]);
      expect(vm.days[0].completedHere, 1); // Monday = completed_at
      expect(vm.days[3].dueTotal, 1); // Thursday = deadline
      expect(vm.days[3].dueRemaining, 0);
    });

    test('null deadline is ignored', () {
      final vm = run([_task(deadline: null)]);
      expect(vm.days.every((d) => d.dueTotal == 0), isTrue);
    });

    test('deadline outside the shown week is ignored', () {
      final vm = run([_task(deadline: DateTime(2026, 9, 20))]);
      expect(vm.days.every((d) => d.dueTotal == 0), isTrue);
    });

    test('multiple tasks on the same day aggregate', () {
      final vm = run([
        _task(deadline: DateTime(2026, 9, 1, 8)),
        _task(deadline: DateTime(2026, 9, 1, 18)),
        _task(deadline: DateTime(2026, 9, 1, 22), isDone: true),
      ]);
      expect(vm.days[1].dueTotal, 3);
      expect(vm.days[1].dueRemaining, 2);
    });

    test('buckets correctly for a week straddling the year boundary', () {
      final vm = computeWeeklyProgress(
        weekStart: DateTime(2026, 12, 28), // Monday
        now: DateTime(2026, 12, 30, 10),
        tasks: [_task(deadline: DateTime(2027, 1, 1, 12))], // Friday
        exams: const [],
      );
      expect(vm.days[4].date, DateTime(2027, 1, 1));
      expect(vm.days[4].dueTotal, 1);
    });
  });

  group('computeWeeklyProgress - next exam', () {
    WeeklyProgressData run(List<ExamEvent> exams) => computeWeeklyProgress(
          weekStart: kWeekStart,
          now: kNow,
          tasks: const [],
          exams: exams,
        );

    test('picks the earliest active exam still to finish', () {
      final vm = run([
        _exam(name: 'Mid', start: DateTime(2026, 9, 15, 9)),
        _exam(name: 'Final', start: DateTime(2026, 10, 3, 9)),
      ]);
      expect(vm.nextExam?.name, 'Mid');
    });

    test('excludes past exams', () {
      final vm = run([
        _exam(
          name: 'Old',
          start: DateTime(2026, 8, 1, 9),
          end: DateTime(2026, 8, 1, 11),
        ),
        _exam(name: 'Upcoming', start: DateTime(2026, 9, 20, 9)),
      ]);
      expect(vm.nextExam?.name, 'Upcoming');
    });

    test('excludes non-active exams', () {
      final vm = run([
        _exam(
          name: 'Cancelled',
          start: DateTime(2026, 9, 10, 9),
          status: 'cancelled',
        ),
        _exam(name: 'Real', start: DateTime(2026, 9, 25, 9)),
      ]);
      expect(vm.nextExam?.name, 'Real');
    });

    test('an exam in progress right now still counts', () {
      final vm = run([
        _exam(
          name: 'Now',
          start: DateTime(2026, 9, 2, 9),
          end: DateTime(2026, 9, 2, 12),
        ),
      ]);
      expect(vm.nextExam?.name, 'Now');
    });

    test('null when there are no upcoming exams', () {
      expect(run(const []).nextExam, isNull);
    });
  });

  group('dayStatusFor', () {
    final monday = DateTime(2026, 8, 31);
    final wednesday = DateTime(2026, 9, 2); // == kNow day
    final friday = DateTime(2026, 9, 4);

    test('past, nothing done, nothing outstanding -> rest', () {
      expect(dayStatusFor(_dp(date: monday), kNow), DayStatus.rest);
    });

    test('past, nothing done, work outstanding -> missed', () {
      expect(
        dayStatusFor(_dp(date: monday, dueTotal: 2, dueRemaining: 2), kNow),
        DayStatus.missed,
      );
    });

    test('past, something completed that day -> done (even with work left)', () {
      expect(
        dayStatusFor(
          _dp(date: monday, dueTotal: 5, dueRemaining: 4, completedHere: 1),
          kNow,
        ),
        DayStatus.done,
      );
    });

    test('the current day -> today regardless of counts', () {
      expect(
        dayStatusFor(_dp(date: wednesday, dueTotal: 3, dueRemaining: 3), kNow),
        DayStatus.today,
      );
    });

    test('a future day -> future', () {
      expect(dayStatusFor(_dp(date: friday), kNow), DayStatus.future);
    });
  });

  group('summaryRow1For - current week', () {
    Row1Spec run(DateTime date, {int dueTotal = 0, int dueRemaining = 0, int completedHere = 0}) {
      return summaryRow1For(
        day: _dp(
          date: date,
          dueTotal: dueTotal,
          dueRemaining: dueRemaining,
          completedHere: completedHere,
        ),
        now: kNow,
        isCurrentWeek: true,
      );
    }

    final wed = DateTime(2026, 9, 2); // today
    final tue = DateTime(2026, 9, 1); // yesterday
    final mon = DateTime(2026, 8, 31); // 2 days ago
    final thu = DateTime(2026, 9, 3); // tomorrow
    final sat = DateTime(2026, 9, 5); // 3 days ahead

    test('today with nothing due', () {
      expect(run(wed), const Row1Spec(Row1Bucket.noTasksToday, 0));
    });
    test('today with tasks remaining', () {
      expect(
        run(wed, dueTotal: 3, dueRemaining: 2),
        const Row1Spec(Row1Bucket.remainingToday, 2),
      );
    });
    test('today all done -> remainingToday with count 0', () {
      expect(
        run(wed, dueTotal: 3, dueRemaining: 0),
        const Row1Spec(Row1Bucket.remainingToday, 0),
      );
    });

    test('yesterday, nothing was due', () {
      expect(run(tue), const Row1Spec(Row1Bucket.noTasksYesterday, 0));
    });
    test('yesterday, none completed', () {
      expect(
        run(tue, dueTotal: 2, dueRemaining: 2),
        const Row1Spec(Row1Bucket.completedYesterday, 0),
      );
    });
    test('yesterday, some completed', () {
      expect(
        run(tue, dueTotal: 2, completedHere: 2),
        const Row1Spec(Row1Bucket.completedYesterday, 2),
      );
    });

    test('older past day, nothing due -> dated variant', () {
      expect(run(mon), const Row1Spec(Row1Bucket.noTasksOnPastDate, 0));
    });
    test('older past day, some completed -> dated variant', () {
      expect(
        run(mon, completedHere: 3),
        const Row1Spec(Row1Bucket.completedOnPastDate, 3),
      );
    });

    test('tomorrow, nothing scheduled', () {
      expect(run(thu), const Row1Spec(Row1Bucket.nothingTomorrow, 0));
    });
    test('tomorrow with tasks due', () {
      expect(
        run(thu, dueTotal: 1),
        const Row1Spec(Row1Bucket.dueTomorrow, 1),
      );
    });

    test('further future day, nothing scheduled -> dated variant', () {
      expect(run(sat), const Row1Spec(Row1Bucket.nothingOnFutureDate, 0));
    });
    test('further future day with tasks due -> dated variant', () {
      expect(
        run(sat, dueTotal: 5),
        const Row1Spec(Row1Bucket.dueOnFutureDate, 5),
      );
    });
  });

  group('summaryRow1For - other week collapses relative wording', () {
    test('a past day in another week never uses "yesterday" phrasing', () {
      final spec = summaryRow1For(
        day: _dp(date: DateTime(2026, 9, 1), completedHere: 1), // would be "yesterday"
        now: kNow,
        isCurrentWeek: false,
      );
      expect(spec, const Row1Spec(Row1Bucket.completedOnPastDate, 1));
    });

    test('a future day in another week never uses "tomorrow" phrasing', () {
      final spec = summaryRow1For(
        day: _dp(date: DateTime(2026, 9, 3), dueTotal: 2), // would be "tomorrow"
        now: kNow,
        isCurrentWeek: false,
      );
      expect(spec, const Row1Spec(Row1Bucket.dueOnFutureDate, 2));
    });
  });
}
