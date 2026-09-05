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
          labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
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
        final rest = entries.length > 3
            ? entries.sublist(3)
            : const <LeaderboardEntry>[];
        // Level is only interesting to show on the Global tab — on the
        // Level tab everyone shares the caller's own level already.
        final showLevel = widget.scope == 'global';

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _Podium(top3: top3, showLevel: showLevel),
              const SizedBox(height: 20),
              FutureBuilder<LeaderboardEntry?>(
                future: _myPositionFuture,
                builder: (context, mySnap) {
                  final mine = mySnap.data;
                  if (mine == null) return const SizedBox.shrink();
                  return _MyRankCard(entry: mine, showLevel: showLevel);
                },
              ),
              const SizedBox(height: 12),
              ...List.generate(rest.length, (i) {
                return FadeInSlide(
                  delay: (i * 0.05).clamp(0, 0.4),
                  child: _LeaderboardRow(entry: rest[i], showLevel: showLevel),
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

/// Gold/silver/bronze visual identity for the top 3 podium slots. Assigned
/// by *display position* (1st/2nd/3rd entry shown), not by matching a
/// numeric `rank` value — ties (e.g. several users tied for 2nd) would
/// otherwise make a rank-matching lookup silently drop a tied entry from
/// the podium entirely.
enum _PodiumTier { gold, silver, bronze }

extension on _PodiumTier {
  Color get color {
    switch (this) {
      case _PodiumTier.gold:
        return const Color(0xFFFFD700);
      case _PodiumTier.silver:
        return const Color(0xFFC0C0C0);
      case _PodiumTier.bronze:
        return const Color(0xFFCD7F32);
    }
  }

  String get medal {
    switch (this) {
      case _PodiumTier.gold:
        return '🥇';
      case _PodiumTier.silver:
        return '🥈';
      case _PodiumTier.bronze:
        return '🥉';
    }
  }

  double get avatarSize {
    switch (this) {
      case _PodiumTier.gold:
        return 84;
      case _PodiumTier.silver:
        return 64;
      case _PodiumTier.bronze:
        return 56;
    }
  }

  double get standHeight {
    switch (this) {
      case _PodiumTier.gold:
        return 92;
      case _PodiumTier.silver:
        return 62;
      case _PodiumTier.bronze:
        return 46;
    }
  }

  bool get crown => this == _PodiumTier.gold;
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top3, required this.showLevel});
  final List<LeaderboardEntry> top3;
  final bool showLevel;

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (second != null)
          _PodiumSlot(
            entry: second,
            tier: _PodiumTier.silver,
            showLevel: showLevel,
          ),
        const SizedBox(width: 10),
        if (first != null)
          _PodiumSlot(
            entry: first,
            tier: _PodiumTier.gold,
            showLevel: showLevel,
          ),
        const SizedBox(width: 10),
        if (third != null)
          _PodiumSlot(
            entry: third,
            tier: _PodiumTier.bronze,
            showLevel: showLevel,
          ),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.tier,
    required this.showLevel,
  });

  final LeaderboardEntry entry;
  final _PodiumTier tier;
  final bool showLevel;

  @override
  Widget build(BuildContext context) {
    final color = tier.color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tier.crown)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700),
              size: 26,
            ),
          ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: tier.avatarSize / 2,
                backgroundColor: color.withOpacity(0.15),
                backgroundImage: entry.avatarUrl != null
                    ? NetworkImage(entry.avatarUrl!)
                    : null,
                child: entry.avatarUrl == null
                    ? Text(
                        _initials(entry.name),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: tier.avatarSize / 3,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Text(tier.medal, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 88,
          child: Text(
            entry.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        if (showLevel && entry.level != null && entry.level!.trim().isNotEmpty)
          Text(
            entry.level!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        Text(
          '${entry.totalPoints} pts',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 64,
          height: tier.standHeight,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Text(
            '#${entry.rank}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _MyRankCard extends StatelessWidget {
  const _MyRankCard({required this.entry, required this.showLevel});
  final LeaderboardEntry entry;
  final bool showLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = LevelService.computeLevel(entry.totalPoints);
    final academicLevel = entry.level?.trim();
    final subtitle = [
      '#${entry.rank}',
      level.title,
      if (showLevel && academicLevel != null && academicLevel.isNotEmpty)
        academicLevel,
    ].join('  ·  ');
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
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
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
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.totalPoints} pts',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.showLevel});
  final LeaderboardEntry entry;
  final bool showLevel;

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
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: theme.hintColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Text(
                    _initials(entry.name),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (showLevel &&
                    entry.level != null &&
                    entry.level!.trim().isNotEmpty)
                  Text(
                    entry.level!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: theme.hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.totalPoints}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
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
        return const Icon(
          Icons.arrow_upward_rounded,
          color: Colors.green,
          size: 16,
        );
      case LeaderboardTrend.down:
        return const Icon(
          Icons.arrow_downward_rounded,
          color: Colors.red,
          size: 16,
        );
      case LeaderboardTrend.flat:
        return Icon(
          Icons.remove_rounded,
          color: Colors.grey.shade400,
          size: 16,
        );
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
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
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
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 14),
            Text(
              "Couldn't load the leaderboard",
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            MaterialButton(
              elevation: 0,
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
