/// One weekly class slot. [dayOfWeek] is ISO (1 = Monday ... 7 = Sunday),
/// matching [DateTime.weekday]; [startMinutes]/[endMinutes] are minutes since
/// local midnight.
class TimetableEntry {
  final String id;
  final String userId;
  final String? courseCode;
  final String title;
  final String? lecturer;
  final String? venue;
  final int dayOfWeek;
  final int startMinutes;
  final int endMinutes;
  final String source;

  const TimetableEntry({
    this.id = '',
    required this.userId,
    this.courseCode,
    required this.title,
    this.lecturer,
    this.venue,
    required this.dayOfWeek,
    required this.startMinutes,
    required this.endMinutes,
    this.source = 'manual',
  });

  /// Parses Postgres `time` text ("08:30" or "08:30:00") into minutes since
  /// midnight. Throws [FormatException] on anything else.
  static int parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2}(?:\.\d+)?)?$')
        .firstMatch(value.trim());
    if (match == null) throw FormatException('Invalid time: $value');
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    if (h > 23 || m > 59) throw FormatException('Invalid time: $value');
    return h * 60 + m;
  }

  static String formatTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory TimetableEntry.fromSupabase(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      courseCode: json['course_code'],
      title: json['title'] ?? '',
      lecturer: json['lecturer'],
      venue: json['venue'],
      dayOfWeek: json['day_of_week'] as int,
      startMinutes: parseTime(json['start_time'] as String),
      endMinutes: parseTime(json['end_time'] as String),
      source: json['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      if (courseCode != null) 'course_code': courseCode,
      'title': title,
      if (lecturer != null) 'lecturer': lecturer,
      if (venue != null) 'venue': venue,
      'day_of_week': dayOfWeek,
      'start_time': formatTime(startMinutes),
      'end_time': formatTime(endMinutes),
      'source': source,
      if (id.isNotEmpty) 'id': id,
    };
  }

  /// A slot the service can place on the calendar.
  bool get isValid =>
      dayOfWeek >= 1 &&
      dayOfWeek <= 7 &&
      startMinutes >= 0 &&
      endMinutes <= 24 * 60 &&
      endMinutes > startMinutes;
}
