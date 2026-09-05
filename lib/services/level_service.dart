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

  /// Points needed, from this tier's own floor, to reach the next tier.
  /// 0 at the max tier — there is no next level to progress toward.
  final int pointsForNextLevel;

  /// 0..1 progress toward the next tier. Always 1.0 at the max tier.
  final double progress;

  /// True once a student has reached the highest defined tier (Einstein).
  /// There's no further named tier beyond it — this stays true forever
  /// past that point, however many more points are earned.
  final bool isMaxLevel;

  const LevelInfo({
    required this.level,
    required this.title,
    required this.totalPoints,
    required this.pointsIntoLevel,
    required this.pointsForNextLevel,
    required this.progress,
    required this.isMaxLevel,
  });
}

class _Tier {
  const _Tier(this.title, this.points);
  final String title;
  final int points;
}

class LevelService {
  LevelService._();

  /// Named tiers in ascending order of points required to reach them —
  /// an academic-career ladder from brand-new student up to a legendary
  /// "Einstein" tier. No underlying formula: tune/add/rename entries here
  /// directly to reshape the curve or the naming.
  static const List<_Tier> _tiers = [
    _Tier('Fresher', 0),
    _Tier('Sophomore', 50),
    _Tier('Scholar', 200),
    _Tier('Graduate', 500),
    _Tier('Fellow', 1000),
    _Tier('Lecturer', 1800),
    _Tier('Senior Lecturer', 2800),
    _Tier('Professor', 4000),
    _Tier('Dean', 5500),
    _Tier('Chancellor', 7500),
    _Tier('Einstein', 10000),
  ];

  static LevelInfo computeLevel(int totalPoints) {
    final points = totalPoints < 0 ? 0 : totalPoints;

    var index = 0;
    for (var i = 0; i < _tiers.length; i++) {
      if (points >= _tiers[i].points) {
        index = i;
      } else {
        break;
      }
    }

    final tier = _tiers[index];
    final isMax = index == _tiers.length - 1;
    final pointsIntoLevel = points - tier.points;
    final pointsForNextLevel = isMax ? 0 : _tiers[index + 1].points - tier.points;
    final progress = isMax
        ? 1.0
        : (pointsIntoLevel / pointsForNextLevel).clamp(0.0, 1.0);

    return LevelInfo(
      level: index + 1,
      title: tier.title,
      totalPoints: points,
      pointsIntoLevel: pointsIntoLevel,
      pointsForNextLevel: pointsForNextLevel,
      progress: progress,
      isMaxLevel: isMax,
    );
  }
}
