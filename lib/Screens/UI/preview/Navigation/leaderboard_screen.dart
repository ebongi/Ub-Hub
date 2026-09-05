import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_study/Screens/Shared/animations.dart';
import 'package:go_study/services/leaderboard_entry.dart';
import 'package:go_study/services/level_service.dart';
import 'package:go_study/services/points_service.dart';

/// Ranks students by total points, scoped to the caller's own academic
/// level or globally. See supabase/migrations/create_points_and_leaderboard.sql
/// for how scoring/ranking is computed server-side.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Level'),
            Tab(text: 'Global'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LeaderboardTabBody(scope: 'level'),
          _LeaderboardTabBody(scope: 'global'),
        ],
      ),
    );
  }
}

class _LeaderboardTabBody extends StatefulWidget {
  const _LeaderboardTabBody({required this.scope});
  final String scope;

  @override
  State<_LeaderboardTabBody> createState() => _LeaderboardTabBodyState();
}

class _LeaderboardTabBodyState extends State<_LeaderboardTabBody>
    with AutomaticKeepAliveClientMixin {
  final PointsService _points = PointsService();
  late Future<List<LeaderboardEntry>> _entriesFuture;
  late Future<LeaderboardEntry?> _myPositionFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _entriesFuture = _points.getLeaderboard(widget.scope);
    _myPositionFuture = _points.getMyPosition(widget.scope);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_entriesFuture, _myPositionFuture]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<LeaderboardEntry>>(
      future: _entriesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorState(onRetry: () => setState(_load));
        }

        final entries = snap.data ?? const <LeaderboardEntry>[];
        if (entries.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _EmptyState(scope: widget.scope),
                ),
              ],
            ),
          );
        }

        final top3 = entries.take(3).toList();
        final rest = entries.length > 3 ? entries.sublist(3) : const <LeaderboardEntry>[];

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _Podium(top3: top3),
              const SizedBox(height: 20),
              FutureBuilder<LeaderboardEntry?>(
                future: _myPositionFuture,
                builder: (context, mySnap) {
                  final mine = mySnap.data;
                  if (mine == null) return const SizedBox.shrink();
                  return _MyRankCard(entry: mine);
                },
              ),
              const SizedBox(height: 12),
              ...List.generate(rest.length, (i) {
                return FadeInSlide(
                  delay: (i * 0.05).clamp(0, 0.4),
                  child: _LeaderboardRow(entry: rest[i]),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + last).toUpperCase();
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top3});
  final List<LeaderboardEntry> top3;

  LeaderboardEntry? _at(int rank) {
    for (final e in top3) {
      if (e.rank == rank) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final first = _at(1);
    final second = _at(2);
    final third = _at(3);
    if (first == null && second == null && third == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (second != null)
          _PodiumSlot(
            entry: second,
            avatarSize: 60,
            standHeight: 60,
            color: const Color(0xFFC0C0C0),
          ),
        const SizedBox(width: 10),
        if (first != null)
          _PodiumSlot(
            entry: first,
            avatarSize: 80,
            standHeight: 88,
            color: const Color(0xFFFFD700),
            crown: true,
          ),
        const SizedBox(width: 10),
        if (third != null)
          _PodiumSlot(
            entry: third,
            avatarSize: 52,
            standHeight: 44,
            color: const Color(0xFFCD7F32),
          ),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.avatarSize,
    required this.standHeight,
    required this.color,
    this.crown = false,
  });

  final LeaderboardEntry entry;
  final double avatarSize;
  final double standHeight;
  final Color color;
  final bool crown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (crown)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 26),
          ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: color.withOpacity(0.15),
            backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(
                    _initials(entry.name),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: avatarSize / 3),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 88,
          child: Text(
            entry.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        Text(
          '${entry.totalPoints} pts',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          width: 64,
          height: standHeight,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Text(
            '#${entry.rank}',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _MyRankCard extends StatelessWidget {
  const _MyRankCard({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = LevelService.computeLevel(entry.totalPoints);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Icon(Icons.person_rounded, color: theme.colorScheme.primary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rank',
                  style: GoogleFonts.outfit(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w600),
                ),
                Text(
                  '#${entry.rank}  ·  ${level.title}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          Text(
            '${entry.totalPoints} pts',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerLow
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.hintColor),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(_initials(entry.name), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Text('${entry.totalPoints}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 8),
          _TrendIcon(trend: entry.trend),
        ],
      ),
    );
  }
}

class _TrendIcon extends StatelessWidget {
  const _TrendIcon({required this.trend});
  final LeaderboardTrend trend;

  @override
  Widget build(BuildContext context) {
    switch (trend) {
      case LeaderboardTrend.up:
        return const Icon(Icons.arrow_upward_rounded, color: Colors.green, size: 16);
      case LeaderboardTrend.down:
        return const Icon(Icons.arrow_downward_rounded, color: Colors.red, size: 16);
      case LeaderboardTrend.flat:
        return Icon(Icons.remove_rounded, color: Colors.grey.shade400, size: 16);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scope});
  final String scope;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            scope == 'level'
                ? 'No one at your level has earned points yet — be the first!'
                : 'No one has earned points yet — be the first!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.withOpacity(0.5)),
            const SizedBox(height: 14),
            Text("Couldn't load the leaderboard", style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
