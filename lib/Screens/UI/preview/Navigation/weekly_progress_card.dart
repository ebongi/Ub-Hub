import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_study/Screens/Shared/compact_list_row.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/exam_schedule_screen.dart';
import 'package:go_study/Screens/UI/preview/Toolbox/task_manager_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/exam_event.dart';
import 'package:go_study/services/task_model.dart';
import 'package:go_study/services/weekly_progress.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Glanceable "this week" card on the home feed: a navigable Mon–Sun strip with
/// a per-day status glyph, plus a two-row summary (task status for the selected
/// day, and the next upcoming exam). Wired to the live `tasks` / `exams`
/// Supabase streams via [DatabaseService].
class WeeklyProgressCard extends StatefulWidget {
  const WeeklyProgressCard({super.key, this.supabaseClient});

  /// Test-injection hook, mirroring [Home].
  final SupabaseClient? supabaseClient;

  @override
  State<WeeklyProgressCard> createState() => _WeeklyProgressCardState();
}

class _WeeklyProgressCardState extends State<WeeklyProgressCard> {
  late final SupabaseClient _supabase;
  late final Stream<List<TodoTask>> _tasks;
  late final Stream<List<ExamEvent>> _exams;

  /// Monday 00:00 (local) of the shown week.
  late DateTime _weekStart;

  /// 0..6 offset from [_weekStart] — the source of truth for the selected day.
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient ?? Supabase.instance.client;

    // Subscribe once. This widget rebuilds on every day-cell tap; reading
    // db.tasks / db.exams inside build() would open a fresh realtime channel
    // each time.
    final db = DatabaseService(uid: _supabase.auth.currentUser?.id);
    _tasks = db.tasks;
    _exams = db.exams;

    final now = DateTime.now();
    _weekStart = mondayOf(now);
    _selectedIndex = now.weekday - 1; // Mon=1 .. Sun=7
  }

  bool get _isCurrentWeek => _weekStart == mondayOf(DateTime.now());

  void _pageWeeks(int delta) {
    setState(() => _weekStart = addDays(_weekStart, 7 * delta));
  }

  void _goToThisWeek() {
    final now = DateTime.now();
    setState(() {
      _weekStart = mondayOf(now);
      _selectedIndex = now.weekday - 1;
    });
  }

  void _selectDay(int i) {
    if (i == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = i);
  }

  void _openTasks() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TaskManagerScreen()),
    );
  }

  void _openExams() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExamScheduleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Signed-out users see nothing — this is a personal dashboard card.
    if (_supabase.auth.currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<List<TodoTask>>(
      stream: _tasks,
      builder: (context, taskSnap) {
        return StreamBuilder<List<ExamEvent>>(
          stream: _exams,
          builder: (context, examSnap) {
            if (taskSnap.hasError || examSnap.hasError) {
              debugPrint(
                'WeeklyProgressCard stream error: '
                '${taskSnap.error ?? examSnap.error}',
              );
              return const SizedBox.shrink();
            }

            final loading =
                taskSnap.connectionState == ConnectionState.waiting ||
                    examSnap.connectionState == ConnectionState.waiting;

            final now = DateTime.now();
            final vm = computeWeeklyProgress(
              weekStart: _weekStart,
              now: now,
              tasks: taskSnap.data ?? const [],
              exams: examSnap.data ?? const [],
            );

            return _buildCard(context, vm, now, loading);
          },
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    WeeklyProgressData vm,
    DateTime now,
    bool loading,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final shortDate = DateFormat('d MMM');
    final weekEnd = addDays(_weekStart, 6);
    final rangeLabel = l10n.weeklyProgressWeekRange(
      shortDate.format(_weekStart),
      shortDate.format(weekEnd),
    );

    final selectedDay = vm.days[_selectedIndex];
    final row1 = loading
        ? '—'
        : _row1Text(
            l10n,
            summaryRow1For(
              day: selectedDay,
              now: now,
              isCurrentWeek: _isCurrentWeek,
            ),
            shortDate.format(selectedDay.date),
          );

    final ExamEvent? nextExam = vm.nextExam;
    final row2Title = loading
        ? '—'
        : (nextExam != null
            ? l10n.weeklyProgressNextExam(
                DateFormat('d MMMM y').format(nextExam.startTime.toLocal()),
              )
            : l10n.weeklyProgressNoUpcomingExams);
    final row2Subtitle = loading
        ? null
        : (nextExam != null
            ? nextExam.name
            : l10n.weeklyProgressExamRowFallbackSubtitle);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeekHeader(
            rangeLabel: rangeLabel,
            showTodayPill: !_isCurrentWeek,
            onPrev: () => _pageWeeks(-1),
            onNext: () => _pageWeeks(1),
            onToday: _goToThisWeek,
          ),
          const SizedBox(height: AppSpacing.lg),
          _DayStrip(
            weekStart: _weekStart,
            selectedIndex: _selectedIndex,
            now: now,
            days: vm.days,
            loading: loading,
            onSelect: _selectDay,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SummaryBlock(
            row1Title: row1,
            row2Title: row2Title,
            row2Subtitle: row2Subtitle,
            onTapTasks: loading ? null : _openTasks,
            onTapExams: loading ? null : _openExams,
          ),
        ],
      ),
    );
  }

  String _row1Text(AppLocalizations l10n, Row1Spec spec, String day) {
    switch (spec.bucket) {
      case Row1Bucket.noTasksToday:
        return l10n.weeklyProgressNoTasksToday;
      case Row1Bucket.remainingToday:
        return l10n.weeklyProgressTasksRemainingToday(spec.count);
      case Row1Bucket.noTasksYesterday:
        return l10n.weeklyProgressNoTasksYesterday;
      case Row1Bucket.completedYesterday:
        return l10n.weeklyProgressCompletedYesterday(spec.count);
      case Row1Bucket.noTasksOnPastDate:
        return l10n.weeklyProgressNoTasksOnPastDate(day);
      case Row1Bucket.completedOnPastDate:
        return l10n.weeklyProgressCompletedOnPastDate(spec.count, day);
      case Row1Bucket.nothingTomorrow:
        return l10n.weeklyProgressNothingTomorrow;
      case Row1Bucket.dueTomorrow:
        return l10n.weeklyProgressDueTomorrow(spec.count);
      case Row1Bucket.nothingOnFutureDate:
        return l10n.weeklyProgressNothingOnFutureDate(day);
      case Row1Bucket.dueOnFutureDate:
        return l10n.weeklyProgressDueOnFutureDate(spec.count, day);
    }
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.rangeLabel,
    required this.showTodayPill,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final String rangeLabel;
  final bool showTodayPill;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _HeaderIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: l10n.weeklyProgressPrevWeekTooltip,
          onTap: onPrev,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            rangeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.cardTitle(context).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _HeaderIconButton(
          icon: Icons.chevron_right_rounded,
          tooltip: l10n.weeklyProgressNextWeekTooltip,
          onTap: onNext,
        ),
        const Spacer(),
        if (showTodayPill)
          Tooltip(
            message: l10n.weeklyProgressTodayPillTooltip,
            child: Material(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: InkWell(
                onTap: onToday,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  child: Text(
                    l10n.weeklyProgressTodayPill,
                    style: AppText.caption(context).copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              icon,
              size: 24,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.weekStart,
    required this.selectedIndex,
    required this.now,
    required this.days,
    required this.loading,
    required this.onSelect,
  });

  final DateTime weekStart;
  final int selectedIndex;
  final DateTime now;
  final List<DayProgress> days;
  final bool loading;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final narrowWeekdays = MaterialLocalizations.of(context).narrowWeekdays;
    final today = dateOnly(now);

    return Row(
      children: List.generate(7, (i) {
        final date = addDays(weekStart, i);
        return Expanded(
          child: _DayCell(
            letter: narrowWeekdays[date.weekday % 7],
            status: loading ? null : dayStatusFor(days[i], now),
            isToday: dateOnly(date) == today,
            isSelected: i == selectedIndex,
            onTap: () => onSelect(i),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.letter,
    required this.status,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final String letter;
  final DayStatus? status;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isToday
              ? primary.withOpacity(isDark ? 0.20 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              letter,
              style: AppText.caption(context).copyWith(
                color: isToday ? primary : theme.colorScheme.onSurfaceVariant,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusGlyph(status: status),
          ],
        ),
      ),
    );
  }
}

class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.status});

  /// null renders a neutral placeholder ring (loading).
  final DayStatus? status;

  static const double _size = 26;
  static const double _iconSize = 15;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final greyBg =
        isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06);
    final greyFg = isDark ? Colors.white70 : Colors.black54;

    switch (status) {
      case null:
        return SizedBox(
          width: _size,
          height: _size,
          child: CustomPaint(
            size: const Size(_size, _size),
            painter: _DashedCirclePainter(
              theme.colorScheme.outline.withOpacity(0.4),
            ),
          ),
        );
      case DayStatus.rest:
        return _filled(greyBg, Icons.pause_rounded, greyFg);
      case DayStatus.missed:
        return _filled(greyBg, Icons.close_rounded, greyFg);
      case DayStatus.done:
        return _filled(
          primary.withOpacity(isDark ? 0.28 : 0.15),
          Icons.check_rounded,
          primary,
        );
      case DayStatus.today:
        return _dashed(primary, Icons.check_rounded, primary);
      case DayStatus.future:
        return _dashed(
          theme.colorScheme.outline,
          Icons.check_rounded,
          theme.colorScheme.onSurfaceVariant,
        );
    }
  }

  Widget _filled(Color bg, IconData icon, Color fg) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: _iconSize, color: fg),
    );
  }

  Widget _dashed(Color ring, IconData icon, Color fg) {
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _DashedCirclePainter(ring),
        child: Center(child: Icon(icon, size: _iconSize, color: fg)),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const dashCount = 16;
    const gapRatio = 0.45;
    final sweep = (2 * math.pi) / dashCount;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.shortestSide - paint.strokeWidth) / 2,
    );

    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * sweep, sweep * (1 - gapRatio), false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.row1Title,
    required this.row2Title,
    required this.row2Subtitle,
    required this.onTapTasks,
    required this.onTapExams,
  });

  final String row1Title;
  final String row2Title;
  final String? row2Subtitle;
  final VoidCallback? onTapTasks;
  final VoidCallback? onTapExams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          CompactListRow(
            dense: true,
            icon: Icons.checklist_rounded,
            tint: const Color(0xFF24C1E0),
            title: row1Title,
            onTap: onTapTasks,
            trailing: const SizedBox.shrink(),
          ),
          Divider(height: 1, color: theme.dividerColor),
          CompactListRow(
            dense: true,
            icon: Icons.event_rounded,
            tint: const Color(0xFFEA4335),
            title: row2Title,
            subtitle: row2Subtitle,
            onTap: onTapExams,
            trailing: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
