import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/services/timetable_format.dart';

void main() {
  final now = DateTime(2026, 10, 19, 22, 30); // Monday night

  test('relativeDay is by calendar date, not by 24h', () {
    expect(relativeDay(now, DateTime(2026, 10, 19, 23, 59)), RelativeDay.today);
    // 2 hours later but already the next calendar day.
    expect(relativeDay(now, DateTime(2026, 10, 20, 0, 30)), RelativeDay.tomorrow);
    expect(relativeDay(now, DateTime(2026, 10, 21, 7)), RelativeDay.other);
    expect(relativeDay(now, DateTime(2026, 10, 26, 7)), RelativeDay.other);
  });

  test('relativeDay handles month and year boundaries', () {
    final eve = DateTime(2026, 12, 31, 20);
    expect(relativeDay(eve, DateTime(2027, 1, 1, 8)), RelativeDay.tomorrow);
  });

  test('splitDuration splits hours and minutes', () {
    expect(splitDuration(const Duration(minutes: 45)), (hours: 0, minutes: 45));
    expect(splitDuration(const Duration(minutes: 130)), (hours: 2, minutes: 10));
    expect(splitDuration(const Duration(hours: 3)), (hours: 3, minutes: 0));
  });

  test('splitDuration rounds up and never shows zero', () {
    expect(splitDuration(const Duration(seconds: 61)), (hours: 0, minutes: 2));
    expect(splitDuration(const Duration(seconds: 5)), (hours: 0, minutes: 1));
    expect(splitDuration(Duration.zero), (hours: 0, minutes: 1));
  });
}
