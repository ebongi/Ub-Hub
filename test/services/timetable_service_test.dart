import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/services/timetable_entry.dart';
import 'package:go_study/services/timetable_service.dart';

TimetableEntry slot(
  int day,
  String start,
  String end, {
  String title = 'Class',
  String? venue,
}) => TimetableEntry(
  userId: 'u',
  title: title,
  venue: venue,
  dayOfWeek: day,
  startMinutes: TimetableEntry.parseTime(start),
  endMinutes: TimetableEntry.parseTime(end),
);

void main() {
  // 2026-10-19 is a Monday.
  DateTime at(int day, int h, [int m = 0]) => DateTime(2026, 10, day, h, m);

  group('TimetableEntry', () {
    test('parseTime accepts HH:MM and HH:MM:SS', () {
      expect(TimetableEntry.parseTime('08:30'), 510);
      expect(TimetableEntry.parseTime('08:30:00'), 510);
      expect(TimetableEntry.parseTime('8:05'), 485);
    });

    test('parseTime rejects bad input', () {
      expect(() => TimetableEntry.parseTime('25:00'), throwsFormatException);
      expect(() => TimetableEntry.parseTime('abc'), throwsFormatException);
    });

    test('supabase round trip', () {
      final e = TimetableEntry.fromSupabase({
        'id': 'a',
        'user_id': 'u',
        'title': 'MTH201',
        'venue': 'Room 204',
        'day_of_week': 2,
        'start_time': '08:00:00',
        'end_time': '10:00:00',
      });
      expect(e.startMinutes, 480);
      final json = e.toSupabase();
      expect(json['start_time'], '08:00');
      expect(json['end_time'], '10:00');
      expect(json['day_of_week'], 2);
    });
  });

  group('TimetableService.statusAt', () {
    final entries = [
      slot(1, '08:00', '10:00', title: 'Mon morning', venue: 'Room 204'),
      slot(1, '14:00', '16:00', title: 'Mon afternoon'),
      slot(3, '09:00', '11:00', title: 'Wed'),
    ];

    test('empty timetable has no status', () {
      expect(TimetableService.statusAt([], at(19, 9)).isEmpty, isTrue);
    });

    test('ongoing class and next class later the same day', () {
      final s = TimetableService.statusAt(entries, at(19, 9));
      expect(s.ongoing!.entry.title, 'Mon morning');
      expect(s.ongoing!.entry.venue, 'Room 204');
      expect(s.ongoing!.untilEnd(at(19, 9)), const Duration(hours: 1));
      expect(s.next!.entry.title, 'Mon afternoon');
    });

    test('start is inclusive, end is exclusive', () {
      expect(
        TimetableService.statusAt(entries, at(19, 8)).ongoing?.entry.title,
        'Mon morning',
      );
      final atEnd = TimetableService.statusAt(entries, at(19, 10));
      expect(atEnd.ongoing, isNull);
      expect(atEnd.next!.entry.title, 'Mon afternoon');
    });

    test('before the first class of the day', () {
      final s = TimetableService.statusAt(entries, at(19, 6));
      expect(s.ongoing, isNull);
      expect(s.next!.entry.title, 'Mon morning');
      expect(s.next!.untilStart(at(19, 6)), const Duration(hours: 2));
    });

    test('after the last class rolls to a later day', () {
      final s = TimetableService.statusAt(entries, at(19, 17));
      expect(s.ongoing, isNull);
      expect(s.next!.entry.title, 'Wed');
      expect(s.next!.start, at(21, 9));
    });

    test('wraps into next week', () {
      final s = TimetableService.statusAt(entries, at(21, 12)); // Wed noon
      expect(s.next!.entry.title, 'Mon morning');
      expect(s.next!.start, at(26, 8));
    });

    test('a single weekly class that just ended resolves to next week', () {
      final only = [slot(1, '08:00', '10:00')];
      final s = TimetableService.statusAt(only, at(19, 11));
      expect(s.next!.start, at(26, 8));
    });

    test('overlapping slots prefer the most recently started', () {
      final overlap = [
        slot(1, '08:00', '11:00', title: 'Long'),
        slot(1, '09:00', '10:00', title: 'Short'),
      ];
      expect(
        TimetableService.statusAt(overlap, at(19, 9, 30)).ongoing!.entry.title,
        'Short',
      );
    });

    test('invalid slots are ignored', () {
      final bad = [slot(1, '10:00', '09:00')];
      expect(TimetableService.statusAt(bad, at(19, 8)).isEmpty, isTrue);
    });
  });

  group('classes at the same time', () {
    test('every class in session is returned, most recently started first', () {
      final entries = [
        slot(1, '08:00', '11:00', title: 'Long'),
        slot(1, '09:00', '10:00', title: 'Short'),
        slot(1, '09:00', '10:00', title: 'Short B'),
      ];
      final s = TimetableService.statusAt(entries, at(19, 9, 30));
      expect(s.ongoingAll.map((o) => o.entry.title), [
        'Short',
        'Short B',
        'Long',
      ]);
      expect(s.ongoing!.entry.title, 'Short');
    });

    test('classes starting together are all "next"', () {
      final entries = [
        slot(1, '14:00', '16:00', title: 'A'),
        slot(1, '14:00', '16:00', title: 'B'),
        slot(1, '17:00', '19:00', title: 'Later'),
      ];
      final s = TimetableService.statusAt(entries, at(19, 12));
      expect(s.nextAll.map((o) => o.entry.title), ['A', 'B']);
      expect(s.next!.entry.title, 'A');
    });

    test('a later start is not grouped with the earliest', () {
      final entries = [
        slot(1, '14:00', '16:00', title: 'A'),
        slot(1, '15:00', '17:00', title: 'B'),
      ];
      final s = TimetableService.statusAt(entries, at(19, 12));
      expect(s.nextAll.map((o) => o.entry.title), ['A']);
    });

    test('ongoing and next groups coexist', () {
      final entries = [
        slot(1, '08:00', '10:00', title: 'Now1'),
        slot(1, '08:00', '10:00', title: 'Now2'),
        slot(1, '14:00', '16:00', title: 'Next1'),
        slot(1, '14:00', '16:00', title: 'Next2'),
      ];
      final s = TimetableService.statusAt(entries, at(19, 9));
      expect(s.ongoingAll.length, 2);
      expect(s.nextAll.length, 2);
    });
  });

  test('forDay sorts by start time', () {
    final list = [slot(1, '14:00', '15:00'), slot(1, '08:00', '09:00')];
    expect(TimetableService.forDay(list, 1).first.startMinutes, 480);
    expect(TimetableService.forDay(list, 2), isEmpty);
  });
}
