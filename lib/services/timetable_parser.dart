import 'package:go_study/services/timetable_entry.dart';

/// One row of a faculty-wide teaching timetable, before the user has chosen
/// which of the rows are theirs.
class ParsedClass {
  final String department;
  final String program;

  /// Base course code, e.g. `MAT211` for a row listed as `MAT211-G1`.
  final String courseCode;

  /// Lab/tutorial group suffix (`G1`, `G2`) when the code carries one.
  final String? group;
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String? hall;
  final String? lecturers;

  const ParsedClass({
    required this.department,
    required this.program,
    required this.courseCode,
    this.group,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.hall,
    this.lecturers,
  });

  /// Level from the course number's first digit (MAT211 -> 200).
  int get level => int.parse(courseCode[3]) * 100;

  /// A dawn-to-dusk slot (e.g. `CHM LAB 07:00-19:00`) — a lab/practical
  /// block rather than a lecture, so the UI can word it differently.
  bool get isAllDayBlock => endMinutes - startMinutes >= 10 * 60;

  /// Course code as listed, including any group suffix.
  String get listedCode => group == null ? courseCode : '$courseCode-$group';

  TimetableEntry toEntry(String userId) => TimetableEntry(
        userId: userId,
        courseCode: listedCode,
        title: listedCode,
        lecturer: lecturers,
        venue: hall,
        dayOfWeek: dayOfWeek,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        source: 'import',
      );
}

class TimetableParseResult {
  final List<ParsedClass> classes;

  /// Lines that looked like a class row (had a day and a time range) but
  /// didn't pass validation — shown on the review screen instead of being
  /// silently dropped.
  final List<String> skipped;

  const TimetableParseResult(this.classes, this.skipped);

  Set<String> get programs => classes.map((c) => c.program).toSet();
}

/// A word from the PDF with its horizontal extent in page points.
class PositionedWord {
  final String text;
  final double left;
  final double right;

  const PositionedWord(this.text, this.left, this.right);

  bool get isBlank => text.trim().isEmpty;
}

/// One extracted text line: its words and vertical position on the page.
class PositionedLine {
  final double top;
  final List<PositionedWord> words;

  const PositionedLine(this.top, this.words);
}

/// Deterministic parser for the university's Excel-exported teaching
/// timetable (header block per department, a `PROGRAM:` line, then
/// `COURSE DAY TIME HALL LECTURERS` rows). No AI and no credits: the PDFs
/// are text, not scans, and the layout is rigid.
///
/// It works on words *with positions* (see timetable_pdf_reader.dart), not
/// flat text, because plain text extraction glues the columns together
/// ("G119-G123Sofeu D.") and makes the hall/lecturer boundary ambiguous.
/// Each spreadsheet cell is drawn as its own contiguous text run, so a row
/// after its code/day/time is split into runs wherever the words stop being
/// contiguous: the first run is the hall (when it starts left of the
/// lecturers column), the rest are lecturers. This also handles two quirks
/// of the real file:
///  * the hall cell can overflow underneath the lecturers column (the PDF
///    holds "CLASSROOM BLOCK II 50 A" but the sheet clips it to "CLASSROOM
///    BLOCK") — it stays one run, so it never leaks into the lecturers;
///  * a row with no hall (`PHY205 WED 15:00-17:00 Tsobgni`) has a single run
///    starting in the lecturers column, so it gets a null hall rather than a
///    lecturer name as venue.
class TimetableParser {
  const TimetableParser._();

  static const _days = {
    'MON': 1, 'TUE': 2, 'WED': 3, 'THU': 4, 'FRI': 5, 'SAT': 6, 'SUN': 7,
  };

  static final _code = RegExp(r'^([A-Z]{3}\d{3})(?:-(G\d))?$');
  static final _time = RegExp(r'^(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})$');

  // Used until a header row ("COURSE DAY TIME HALL LECTURERS") is seen.
  static const _defaultLecturersX = 241.0;

  // Words closer than this (either side) belong to the same text run.
  static const _runGap = 1.5;

  // Slack for "starts in the lecturers column".
  static const _columnSlack = 2.0;

  static String _join(Iterable<PositionedWord> words) =>
      words.map((w) => w.text).join().replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _normaliseHall(String raw) =>
      raw.toUpperCase().replaceFirst(RegExp(r'^REATAU'), 'RESTAU');

  // The extractor sometimes breaks one visual row into two lines a fraction
  // of a point apart (the lecturers land on their own line); fragments within
  // this vertical distance are folded back into their row.
  static const _sameRowTolerance = 2.5;

  static final _rowStart = RegExp(r'^[A-Z]{3}\d{3}(?:-G\d)?$');

  static bool _startsRow(PositionedLine l) {
    final first = l.words.where((w) => !w.isBlank);
    return first.isNotEmpty && _rowStart.hasMatch(first.first.text);
  }

  /// Folds a lecturers-only fragment into the row line it belongs to (the
  /// adjacent line that starts with a course code, within tolerance).
  static List<List<PositionedWord>> _mergeFragments(
    List<PositionedLine> lines,
    double lecturersX,
  ) {
    final rows = [for (final l in lines) List<PositionedWord>.of(l.words)];
    final consumed = <int>{};
    for (var i = 0; i < lines.length; i++) {
      if (_startsRow(lines[i])) continue;
      final first = lines[i].words.where((w) => !w.isBlank);
      if (first.isEmpty || first.first.left < lecturersX - _columnSlack) continue;
      for (final j in [i - 1, i + 1]) {
        if (j < 0 || j >= lines.length || !_startsRow(lines[j])) continue;
        if ((lines[j].top - lines[i].top).abs() > _sameRowTolerance) continue;
        rows[j].addAll(lines[i].words);
        consumed.add(i);
        break;
      }
    }
    return [
      for (var i = 0; i < rows.length; i++)
        if (!consumed.contains(i)) rows[i],
    ];
  }

  static TimetableParseResult parse(List<PositionedLine> rawLines) {
    final classes = <ParsedClass>[];
    final skipped = <String>[];
    final seen = <String>{};

    var department = '';
    var program = '';
    var lecturersX = _defaultLecturersX;

    // Header rows fix the lecturers column; use the first one seen for the
    // fragment merge (all pages share one layout).
    for (final l in rawLines) {
      final ws = l.words.where((w) => !w.isBlank).toList();
      if (ws.isNotEmpty && ws.first.text == 'COURSE') {
        final lec = ws.where((w) => w.text == 'LECTURERS');
        if (lec.isNotEmpty) {
          lecturersX = lec.first.left;
          break;
        }
      }
    }
    final lines = _mergeFragments(rawLines, lecturersX);

    for (final line in lines) {
      final text = _join(line);
      if (text.isEmpty) continue;

      if (text.startsWith('DEPARTMENT:')) {
        department = text.substring('DEPARTMENT:'.length).trim();
        continue;
      }
      if (text.startsWith('PROGRAM:')) {
        program = text.substring('PROGRAM:'.length).trim();
        continue;
      }

      final words = line.where((w) => !w.isBlank).toList();
      if (words.isEmpty) continue;

      if (words.first.text == 'COURSE') {
        final lec = words.where((w) => w.text == 'LECTURERS');
        if (lec.isNotEmpty) lecturersX = lec.first.left;
        continue;
      }

      final day = words.length > 1 ? _days[words[1].text] : null;
      if (day == null) continue; // titles, legends, wrapped fragments

      final codeM = _code.firstMatch(words.first.text);
      final timeM = words.length > 2 ? _time.firstMatch(words[2].text) : null;
      if (codeM == null || timeM == null) {
        skipped.add(text);
        continue;
      }

      final int start, end;
      try {
        start = TimetableEntry.parseTime(timeM.group(1)!);
        end = TimetableEntry.parseTime(timeM.group(2)!);
      } on FormatException {
        skipped.add(text);
        continue;
      }
      if (end <= start) {
        skipped.add(text);
        continue;
      }

      // Everything after the time word (blanks kept: they carry contiguity).
      final timeWord = words[2];
      final tail = line.skipWhile((w) => !identical(w, timeWord)).skip(1);

      final runs = <List<PositionedWord>>[];
      PositionedWord? prev;
      for (final w in tail) {
        if (prev == null || (w.left - prev.right).abs() > _runGap) {
          runs.add([]);
        }
        runs.last.add(w);
        prev = w;
      }
      final nonEmpty = runs.where((r) => _join(r).isNotEmpty).toList();

      String? hall;
      var lecturerRuns = nonEmpty;
      if (nonEmpty.isNotEmpty) {
        final firstLeft = nonEmpty.first.firstWhere((w) => !w.isBlank).left;
        if (firstLeft < lecturersX - _columnSlack) {
          hall = _normaliseHall(_join(nonEmpty.first));
          lecturerRuns = nonEmpty.skip(1).toList();
        }
      }
      final lecturers =
          lecturerRuns.isEmpty ? null : lecturerRuns.map(_join).join(' ');

      final parsed = ParsedClass(
        department: department,
        program: program,
        courseCode: codeM.group(1)!,
        group: codeM.group(2),
        dayOfWeek: day,
        startMinutes: start,
        endMinutes: end,
        hall: hall,
        lecturers: lecturers?.replaceAll(RegExp(r'[,\s]+$'), ''),
      );

      // The same slot can be repeated under several programs; keep one.
      final key =
          '${parsed.listedCode}|${parsed.dayOfWeek}|$start|$end|${parsed.hall}';
      if (seen.add(key)) classes.add(parsed);
    }

    return TimetableParseResult(classes, skipped);
  }

  /// Rows for a user's program and level, e.g. Computer Science, 200.
  static List<ParsedClass> forProgramAndLevel(
    List<ParsedClass> classes, {
    required String program,
    required int level,
  }) =>
      classes
          .where((c) =>
              c.program.toUpperCase() == program.toUpperCase() &&
              c.level == level)
          .toList();
}
