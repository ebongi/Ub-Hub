import 'package:supabase_flutter/supabase_flutter.dart';

import 'leaderboard_entry.dart';

/// Thin wrapper over the points/leaderboard RPCs — mirrors how
/// DatabaseService.useAICredit/addAICredits call Postgres RPCs so the
/// point value and daily caps live only in the award_points() function,
/// never trusted from the client. See
/// supabase/migrations/create_points_and_leaderboard.sql.
class PointsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Reports that [eventType] happened (with any observed data in
  /// [metadata], e.g. a quiz score) and returns the points actually
  /// awarded — 0 if today's cap for that event type was already hit.
  Future<int> awardPoints(
    String eventType, {
    Map<String, dynamic> metadata = const {},
  }) async {
    final result = await _supabase.rpc(
      'award_points',
      params: {'p_event_type': eventType, 'p_metadata': metadata},
    );
    return (result as num?)?.toInt() ?? 0;
  }

  /// scope is 'level' (same academic level as the current user) or 'global'.
  Future<List<LeaderboardEntry>> getLeaderboard(
    String scope, {
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _supabase.rpc(
      'get_leaderboard',
      params: {'p_scope': scope, 'p_limit': limit, 'p_offset': offset},
    );
    return (rows as List)
        .map((row) => LeaderboardEntry.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  Future<LeaderboardEntry?> getMyPosition(String scope) async {
    final rows = await _supabase.rpc(
      'get_my_leaderboard_position',
      params: {'p_scope': scope},
    );
    final list = rows as List;
    if (list.isEmpty) return null;
    return LeaderboardEntry.fromSupabase(list.first as Map<String, dynamic>);
  }
}
