/// Display helpers for the home "next class" card — pure, so the wording
/// rules are unit-testable without a widget tree.
enum RelativeDay { today, tomorrow, other }

/// Where [when] falls relative to [now] by calendar date.
RelativeDay relativeDay(DateTime now, DateTime when) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(when.year, when.month, when.day);
  final diff = DateTime(day.year, day.month, day.day)
      .difference(today)
      .inDays; // whole days; both are local midnights
  if (diff == 0) return RelativeDay.today;
  if (diff == 1) return RelativeDay.tomorrow;
  return RelativeDay.other;
}

/// Splits [d] into whole hours and minutes, rounding up to the next minute
/// (never shows "0 min" for a class that hasn't started/finished yet).
({int hours, int minutes}) splitDuration(Duration d) {
  final totalMinutes = d.inSeconds <= 0 ? 0 : (d.inSeconds + 59) ~/ 60;
  final minutes = totalMinutes < 1 ? 1 : totalMinutes;
  return (hours: minutes ~/ 60, minutes: minutes % 60);
}
