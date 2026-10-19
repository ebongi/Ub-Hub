import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/services/timetable_parser.dart';

// Builds a positioned line from a fixed-width string the way the real PDF
// lays out: 5pt per character, cells separated by 2+ spaces (separate text
// runs), single spaces inside a cell kept as blank words (contiguous run).
PositionedLine line(String s, {double top = 100}) {
  final words = <PositionedWord>[];
  for (final m in RegExp(r'\S+|\s').allMatches(s)) {
    // A run of 2+ spaces is a cell gap: emit nothing, so the next word is
    // not contiguous with the previous one.
    words.add(PositionedWord(m.group(0)!, m.start * 5.0, m.end * 5.0));
  }
  final cleaned = <PositionedWord>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    if (!w.isBlank) {
      cleaned.add(w);
      continue;
    }
    final prevBlank = i > 0 && words[i - 1].isBlank;
    final nextBlank = i + 1 < words.length && words[i + 1].isBlank;
    if (!prevBlank && !nextBlank) cleaned.add(w); // lone space = same cell
  }
  return PositionedLine(top, cleaned);
}

// Header columns at chars 0/9/15/31/47 -> x = 0/45/75/155/235.
const header = 'COURSE   DAY    TIME           HALL           LECTURERS';

List<PositionedLine> doc(List<String> rows) =>
    [for (var i = 0; i < rows.length; i++) line(rows[i], top: 100.0 + i * 10)];

final sample = doc([
  'UNIVERSITY OF BUEA',
  'FACULTY/SCHOOL: SCIENCE',
  'DEPARTMENT: COMPUTER SCIENCE',
  header,
  'PROGRAM: COMPUTER SCIENCE',
  'CSC209   MON    07:00-09:00    G112-G113      Tiako, F/Tabo, D',
  'CSC303   MON    15:00-17:00    CLASSROOM BLOCK  Nyanga, B/Mukete, S',
  'CSC301   THU    07:00-09:00    AMPHI 150 E    Achankeng, P, D/Kometa, D',
  'CSC305   FRI    11:00-13:00    AMPHI 150 B    Mawoh, R/Mbungang, B',
  'DEPARTMENT: MATHEMATICS',
  header,
  'PROGRAM: MATHEMATICS',
  'MAT211-G1 TUE   09:00-11:00    AMPHI 750      Mengnjo A./ Mbapte R.',
  'MAT211-G2 TUE   15:00-17:00    AMPHI 150 A    Mengnjo A./ Mbapte R.',
  'DEPARTMENT: CHEMISTRY',
  header,
  'PROGRAM: CHEMISTRY',
  'CHM300   THU    07:00-19:00    CHM LAB',
  'ICH305   FRI    07:00-19:00    CLASSROOM BLOCK II',
  'DEPARTMENT: PHYSICS',
  header,
  'PROGRAM: PHYSICS',
  'ELT303   THU    11:00-13:00    REATAU I       Fotsing J.',
  'ENV309   MON    09:00-11:00    G112-G113',
  'PHY203   TUE    07:00-09:00                   Ndifon I.',
]);

void main() {
  final result = TimetableParser.parse(sample);
  ParsedClass find(String listed, int day) => result.classes
      .firstWhere((c) => c.listedCode == listed && c.dayOfWeek == day);

  test('parses every class row and skips titles/headers', () {
    expect(result.classes.length, 11);
    expect(result.skipped, isEmpty);
    expect(result.programs,
        {'COMPUTER SCIENCE', 'MATHEMATICS', 'CHEMISTRY', 'PHYSICS'});
  });

  test('carries department and program context', () {
    final c = find('CSC209', 1);
    expect(c.department, 'COMPUTER SCIENCE');
    expect(c.program, 'COMPUTER SCIENCE');
    expect(c.startMinutes, 7 * 60);
    expect(c.endMinutes, 9 * 60);
    expect(c.level, 200);
  });

  test('separates hall from lecturers', () {
    expect(find('CSC209', 1).hall, 'G112-G113');
    expect(find('CSC209', 1).lecturers, 'Tiako, F/Tabo, D');
    expect(find('CSC303', 1).hall, 'CLASSROOM BLOCK');
    expect(find('CSC301', 4).hall, 'AMPHI 150 E');
    expect(find('CSC301', 4).lecturers, 'Achankeng, P, D/Kometa, D');
  });

  test('hall with no lecturers', () {
    expect(find('ICH305', 5).hall, 'CLASSROOM BLOCK II');
    expect(find('ICH305', 5).lecturers, isNull);
    expect(find('ENV309', 1).hall, 'G112-G113');
    expect(find('ENV309', 1).lecturers, isNull);
  });

  test('row with no hall: tail is lecturers, venue null', () {
    final c = find('PHY203', 2);
    expect(c.hall, isNull);
    expect(c.lecturers, 'Ndifon I.');
  });

  test('normalises the REATAU typo to RESTAU', () {
    expect(find('ELT303', 4).hall, 'RESTAU I');
    expect(find('ELT303', 4).lecturers, 'Fotsing J.');
  });

  test('lab group suffix is split from the course code', () {
    final c = find('MAT211-G1', 2);
    expect(c.courseCode, 'MAT211');
    expect(c.group, 'G1');
    expect(find('MAT211-G2', 2).hall, 'AMPHI 150 A');
  });

  test('all-day lab blocks are flagged', () {
    expect(find('CHM300', 4).isAllDayBlock, isTrue);
    expect(find('CSC209', 1).isAllDayBlock, isFalse);
  });

  test('hall overflowing under the lecturers column stays in the hall', () {
    // Real file: the sheet clips "CLASSROOM BLOCK II 50 A" but the PDF text
    // keeps it, drawn across the lecturers column before the lecturers.
    PositionedWord w(String t, double l, double r) => PositionedWord(t, l, r);
    final overflow = PositionedLine(100, [
      w('CPS401', 80, 114), w('WED', 114, 130), w('07:00-09:00', 135, 183),
      w('CLASSROOM', 185, 216), w(' ', 216, 219), w('BLOCK', 219, 237),
      w(' ', 237, 240), w('II', 240, 247), w(' ', 247, 251), w('50', 251, 258),
      w(' ', 258, 261), w('A', 261, 267),
      // lecturers restart at the column, behind the overflow
      w('Dr', 241, 248), w(' ', 248, 252), w('Anyinkeng,', 252, 287),
    ]);
    final r = TimetableParser.parse([
      PositionedLine(0, [
        w('COURSE', 80, 110), w('DAY', 114, 130), w('TIME', 135, 150),
        w('HALL', 185, 200), w('LECTURERS', 241, 290),
      ]),
      overflow,
    ]);
    expect(r.classes.single.hall, 'CLASSROOM BLOCK II 50 A');
    expect(r.classes.single.lecturers, 'Dr Anyinkeng,'.replaceAll(RegExp(r',$'), ''));
  });

  test('lecturers extracted as a separate line are folded back into the row', () {
    PositionedWord w(String t, double l, double r) => PositionedWord(t, l, r);
    final r = TimetableParser.parse([
      PositionedLine(0, [
        w('COURSE', 80, 110), w('DAY', 114, 130), w('TIME', 135, 150),
        w('HALL', 185, 200), w('LECTURERS', 241, 290),
      ]),
      PositionedLine(182.5, [
        w('PHY205', 80, 114), w('WED', 114, 130), w('15:00-17:00', 135, 183),
        w('CLASSROOM', 185, 216), w(' ', 216, 219), w('BLOCK', 219, 237),
      ]),
      // 0.8pt higher, as in the real file — and it can come after the row.
      PositionedLine(181.7, [
        w('Tsobgni', 241, 262), w(' ', 262, 266), w('P.', 266, 275),
      ]),
      PositionedLine(190.9, [
        w('ELT307', 80, 114), w('WED', 114, 130), w('17:00-19:00', 135, 183),
        w('RESTAU', 185, 205), w(' ', 205, 209), w('I', 209, 213),
      ]),
    ]);
    expect(r.classes.length, 2);
    expect(r.classes[0].lecturers, 'Tsobgni P.');
    expect(r.classes[0].hall, 'CLASSROOM BLOCK');
    expect(r.classes[1].lecturers, isNull);
  });

  test('malformed rows are reported, not dropped', () {
    final r = TimetableParser.parse(doc([
      header,
      'PROGRAM: X',
      'CSC101   MON    11:00-09:00    G112-G113      Foo',
      'CSC1     TUE    09:00-11:00    G112-G113',
    ]));
    expect(r.classes, isEmpty);
    expect(r.skipped.length, 2);
  });

  test('duplicate slots listed under two programs are kept once', () {
    final r = TimetableParser.parse(doc([
      header,
      'PROGRAM: A',
      'CSC101   MON    07:00-09:00    G112-G113      X',
      'PROGRAM: B',
      'CSC101   MON    07:00-09:00    G112-G113      X',
    ]));
    expect(r.classes.length, 1);
  });

  test('filters by program and level', () {
    final mine = TimetableParser.forProgramAndLevel(
      result.classes,
      program: 'computer science',
      level: 300,
    );
    expect(
        mine.map((c) => c.courseCode).toSet(), {'CSC303', 'CSC301', 'CSC305'});
  });

  test('toEntry maps to a timetable row', () {
    final e = find('MAT211-G1', 2).toEntry('u1');
    expect(e.courseCode, 'MAT211-G1');
    expect(e.venue, 'AMPHI 750');
    expect(e.dayOfWeek, 2);
    expect(e.source, 'import');
    expect(e.isValid, isTrue);
  });
}
