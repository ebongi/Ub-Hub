enum LeaderboardTrend { up, down, flat }

class LeaderboardEntry {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int totalPoints;
  final int rank;
  final LeaderboardTrend trend;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.totalPoints,
    required this.rank,
    required this.trend,
  });

  factory LeaderboardEntry.fromSupabase(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      name: (name != null && name.trim().isNotEmpty) ? name : 'Student',
      avatarUrl: json['avatar_url'] as String?,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      trend: _trendFromString(json['trend'] as String?),
    );
  }

  static LeaderboardTrend _trendFromString(String? value) {
    switch (value) {
      case 'up':
        return LeaderboardTrend.up;
      case 'down':
        return LeaderboardTrend.down;
      default:
        return LeaderboardTrend.flat;
    }
  }
}
