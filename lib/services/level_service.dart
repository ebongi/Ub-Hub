import 'dart:math';

/// Gamification level derived from a student's total points. Pure logic, no
/// Flutter imports — same shape as [WeeklyProgressData] in weekly_progress.dart.
///
/// This is deliberately never stored server-side: total_points is the only
/// persisted number (see profiles.total_points / points_ledger), and the
/// level is always re-derived from it here so there is exactly one place
/// that defines what a "level" means.
class LevelInfo {
  final int level;
  final String title;
  final int totalPoints;
  final int pointsIntoLevel;
  final int pointsForNextLevel;
  final double progress;

  const LevelInfo({
    required this.level,
    required this.title,
    required this.totalPoints,
    required this.pointsIntoLevel,
    required this.pointsForNextLevel,
    required this.progress,
  });
}

class LevelService {
  LevelService._();

  /// Points needed per level "unit" — level = floor(sqrt(points / this)) + 1.
  /// Growing the point cost per level (rather than a flat points-per-level)
  /// means early levels come quickly while sustained engagement is needed
  /// to keep climbing. Tune this single constant to reshape the curve.
  static const int _pointsPerLevelUnit = 50;

  static const List<String> _titles = [
    'Fresher',
    'Sophomore',
    'Diligent Student',
    'Rising Scholar',
    'Honor Student',
    "Dean's Lister",
    'Campus Scholar',
    'Valedictorian',
    'Academic Star',
    'Legend',
  ];

  /// Points required to reach [level] (level 1 starts at 0 points). Inverse
  /// of [_levelForPoints].
  static int _pointsForLevel(int level) {
    final n = level - 1;
    return n * n * _pointsPerLevelUnit;
  }

  static int _levelForPoints(int points) {
    if (points <= 0) return 1;
    return (sqrt(points / _pointsPerLevelUnit)).floor() + 1;
  }

  static String _titleForLevel(int level) {
    if (level <= _titles.length) return _titles[level - 1];
    return '${_titles.last} · Lv $level';
  }

  static LevelInfo computeLevel(int totalPoints) {
    final points = totalPoints < 0 ? 0 : totalPoints;
    final level = _levelForPoints(points);
    final currentFloor = _pointsForLevel(level);
    final nextFloor = _pointsForLevel(level + 1);
    final pointsIntoLevel = points - currentFloor;
    final pointsForNextLevel = nextFloor - currentFloor;
    final progress = pointsForNextLevel == 0
        ? 1.0
        : (pointsIntoLevel / pointsForNextLevel).clamp(0.0, 1.0);
    return LevelInfo(
      level: level,
      title: _titleForLevel(level),
      totalPoints: points,
      pointsIntoLevel: pointsIntoLevel,
      pointsForNextLevel: pointsForNextLevel,
      progress: progress,
    );
  }
}
