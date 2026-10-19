import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:go_study/Screens/UI/preview/Settings/timetable_reminders_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/timetable_catalog.dart';
import 'package:go_study/services/timetable_entry.dart';
import 'package:go_study/services/timetable_format.dart';
import 'package:go_study/services/timetable_repository.dart';
import 'package:go_study/services/timetable_service.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_text_styles.dart';

/// Home card for the courses the user picked in Settings -> Class
/// reminders: the class in session (with where and when it ends) and the
/// next one (when and where). With no courses picked it invites the user to
/// pick some; if the timetable can't be loaded it stays out of the way.
class NextClassCard extends StatefulWidget {
  const NextClassCard({super.key, this.repository, this.clock});

  final TimetableRepository? repository;

  /// Test hook; defaults to [DateTime.now].
  final DateTime Function()? clock;

  @override
  State<NextClassCard> createState() => _NextClassCardState();
}

class _NextClassCardState extends State<NextClassCard>
    with WidgetsBindingObserver {
  late final TimetableRepository _repo;
  Timer? _ticker;

  bool _loaded = false;
  bool _hasSelection = false;
  List<TimetableEntry> _entries = const [];

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? TimetableRepository();
    WidgetsBinding.instance.addObserver(this);
    // Re-evaluate "now / next" as the clock moves; the data itself is static.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final codes = await _repo.fetchSelectedCodes();
      var entries = <TimetableEntry>[];
      if (codes.isNotEmpty) {
        final catalog = TimetableCatalog.from(await _repo.fetchClasses());
        entries = catalog.slotsFor(codes).map((c) => c.toEntry()).toList();
      }
      if (!mounted) return;
      setState(() {
        _hasSelection = codes.isNotEmpty;
        _entries = entries;
        _loaded = true;
      });
    } catch (_) {
      // Offline / not signed in: keep what we have (nothing on first load).
    }
  }

  Future<void> _openPicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimetableRemindersScreen()),
    );
    if (mounted) _load();
  }

  String _duration(AppLocalizations l10n, Duration d) {
    final t = splitDuration(d);
    if (t.hours == 0) return l10n.nextClassMinutes(t.minutes);
    if (t.minutes == 0) return l10n.nextClassHours(t.hours);
    return l10n.nextClassHoursMinutes(t.hours, t.minutes);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget card(Widget child) => GestureDetector(
          onTap: _openPicker,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerLow
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.15),
              ),
            ),
            child: child,
          ),
        );

    if (!_hasSelection) {
      return card(Row(
        children: [
          Icon(Icons.schedule_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.nextClassPromptTitle,
                    style: AppText.cardTitle(context)),
                const SizedBox(height: 2),
                Text(l10n.nextClassPromptBody,
                    style: AppText.cardSubtitle(context)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ));
    }

    final now = _now;
    final status = TimetableService.statusAt(_entries, now);
    if (status.isEmpty) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).toString();
    final rows = <Widget>[];

    final ongoing = status.ongoing;
    if (ongoing != null) {
      rows.add(_ClassRow(
        label: l10n.nextClassNowLabel,
        color: const Color(0xFF34A853),
        code: ongoing.entry.courseCode ?? ongoing.entry.title,
        detail: [
          if (ongoing.entry.venue != null) ongoing.entry.venue!,
          l10n.nextClassEndsIn(_duration(l10n, ongoing.untilEnd(now))),
        ].join(' · '),
      ));
    }

    final next = status.next;
    if (next != null) {
      final dayLabel = switch (relativeDay(now, next.start)) {
        RelativeDay.today => l10n.nextClassToday,
        RelativeDay.tomorrow => l10n.nextClassTomorrow,
        RelativeDay.other => DateFormat.E(locale).format(next.start),
      };
      final until = next.untilStart(now);
      rows.add(_ClassRow(
        label: l10n.nextClassNextLabel,
        color: theme.colorScheme.primary,
        code: next.entry.courseCode ?? next.entry.title,
        detail: [
          '$dayLabel ${TimetableEntry.formatTime(next.entry.startMinutes)}',
          if (next.entry.venue != null) next.entry.venue!,
          if (until < const Duration(hours: 24))
            l10n.nextClassInDuration(_duration(l10n, until)),
        ].join(' · '),
      ));
    }

    return card(Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          rows[i],
        ],
      ],
    ));
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.label,
    required this.color,
    required this.code,
    required this.detail,
  });

  final String label;
  final Color color;
  final String code;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(code, style: AppText.cardTitle(context)),
              const SizedBox(height: 2),
              Text(detail, style: AppText.cardSubtitle(context)),
            ],
          ),
        ),
      ],
    );
  }
}
