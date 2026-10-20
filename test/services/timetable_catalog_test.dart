import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/services/timetable_catalog.dart';
import 'package:go_study/services/timetable_class.dart';

TimetableClass slot(String dept, String code, int day, int start) =>
    TimetableClass(
      department: dept,
      program: dept,
      courseCode: code,
      dayOfWeek: day,
      startMinutes: start,
      endMinutes: start + 120,
      hall: 'AMPHI 600',
    );

void main() {
  final catalog = TimetableCatalog.from([
    slot('MATHEMATICS', 'MAT211-G1', 2, 540),
    slot('MATHEMATICS', 'MAT211-G2', 2, 900),
    slot('COMPUTER SCIENCE', 'CSC301', 4, 420),
    slot('COMPUTER SCIENCE', 'CSC301', 1, 480),
    slot('COMPUTER SCIENCE', 'CSC205', 1, 900),
    slot('PHYSICS', 'PHY203', 2, 420),
  ]);

  test('groups slots by course and lists departments sorted', () {
    expect(catalog.departments, ['COMPUTER SCIENCE', 'MATHEMATICS', 'PHYSICS']);
    expect(catalog.courses.map((c) => c.code), [
      'CSC205',
      'CSC301',
      'MAT211-G1',
      'MAT211-G2',
      'PHY203',
    ]);
  });

  test("a course's slots are ordered by day then time", () {
    final csc301 = catalog.courses.firstWhere((c) => c.code == 'CSC301');
    expect(csc301.slots.map((s) => s.dayOfWeek), [1, 4]);
  });

  test('search ignores case, spaces and dashes', () {
    expect(catalog.filter(query: 'csc 301').map((c) => c.code), ['CSC301']);
    expect(catalog.filter(query: 'mat211g1').map((c) => c.code), ['MAT211-G1']);
    expect(catalog.filter(query: 'mat').map((c) => c.code), [
      'MAT211-G1',
      'MAT211-G2',
    ]);
  });

  test('department filter limits courses', () {
    final r = catalog.filter(departments: {'PHYSICS', 'MATHEMATICS'});
    expect(r.map((c) => c.code), ['MAT211-G1', 'MAT211-G2', 'PHY203']);
  });

  test('selected-only filter and combined filters', () {
    expect(catalog.filter(onlyCodes: {'CSC205', 'PHY203'}).map((c) => c.code), [
      'CSC205',
      'PHY203',
    ]);
    expect(
      catalog
          .filter(
            query: '2',
            departments: {'COMPUTER SCIENCE'},
            onlyCodes: {'CSC205', 'CSC301'},
          )
          .map((c) => c.code),
      ['CSC205'],
    );
  });

  test('slotsFor returns every slot of the chosen codes', () {
    final slots = catalog.slotsFor({'CSC301', 'PHY203'});
    expect(slots.length, 3);
    expect(catalog.slotsFor({}), isEmpty);
  });

  group('clashes', () {
    TimetableClass at(String code, int day, int start, int end) =>
        TimetableClass(
          department: 'D',
          program: 'D',
          courseCode: code,
          dayOfWeek: day,
          startMinutes: start,
          endMinutes: end,
        );

    final c = TimetableCatalog.from([
      at('AAA101', 1, 420, 540), // Mon 07:00-09:00
      at('BBB101', 1, 420, 540), // identical slot
      at('CCC101', 1, 480, 600), // partial overlap with AAA/BBB
      at('DDD101', 1, 540, 660), // back-to-back after AAA/BBB (no clash)
      at('EEE101', 2, 420, 540), // different day
      at('LAB101', 1, 420, 1140), // all-day lab block, ignored
    ]);

    test('identical and partially overlapping slots clash', () {
      final r = c.clashes({'AAA101', 'BBB101', 'CCC101'});
      expect(r['AAA101'], {'BBB101', 'CCC101'});
      expect(r['BBB101'], {'AAA101', 'CCC101'});
      expect(r['CCC101'], {'AAA101', 'BBB101'});
    });

    test('back-to-back, different-day and unchosen courses do not clash', () {
      expect(c.clashes({'AAA101', 'DDD101'}), isEmpty);
      expect(c.clashes({'AAA101', 'EEE101'}), isEmpty);
      expect(c.clashes({'AAA101'}), isEmpty);
      expect(c.clashes({'AAA101', 'BBB101'}).keys, {'AAA101', 'BBB101'});
    });

    test('all-day lab blocks never clash', () {
      expect(c.clashes({'LAB101', 'AAA101', 'DDD101'}), isEmpty);
    });
  });
}
