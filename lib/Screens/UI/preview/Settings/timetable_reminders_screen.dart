import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:go_study/Screens/Shared/department_ui_data.dart';
import 'package:go_study/Screens/Shared/settings_section.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/timetable_catalog.dart';
import 'package:go_study/services/timetable_class.dart';
import 'package:go_study/services/timetable_entry.dart';
import 'package:go_study/services/timetable_reminder_service.dart';
import 'package:go_study/services/timetable_repository.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';
import 'package:go_study/theme/app_text_styles.dart';

/// Settings -> Class reminders: pick departments, then tick the courses to
/// get a reminder for before each class. Search and the department /
/// "selected only" filters narrow the list.
class TimetableRemindersScreen extends StatefulWidget {
  final TimetableRepository? repository;

  /// Reschedules the weekly reminders for the chosen slots. Injectable so
  /// tests don't need the notification plugin.
  final Future<void> Function(List<TimetableClass> slots)? scheduleReminders;

  const TimetableRemindersScreen({
    super.key,
    this.repository,
    this.scheduleReminders,
  });

  @override
  State<TimetableRemindersScreen> createState() =>
      _TimetableRemindersScreenState();
}

class _TimetableRemindersScreenState extends State<TimetableRemindersScreen> {
  late final TimetableRepository _repo;

  TimetableCatalog? _catalog;
  Set<String> _selected = {};
  bool _loading = true;
  bool _loadFailed = false;

  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _departments = {};
  bool _selectedOnly = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? TimetableRepository();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final results = await Future.wait([
        _repo.fetchClasses(),
        _repo.fetchSelectedCodes(),
      ]);
      if (!mounted) return;
      setState(() {
        _catalog = TimetableCatalog.from(results[0] as List<TimetableClass>);
        _selected = results[1] as Set<String>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _toggle(String code, bool value) async {
    final catalog = _catalog!;
    final previous = _selected;
    setState(() {
      _selected = value ? {..._selected, code} : ({..._selected}..remove(code));
    });
    try {
      await _repo.setSelected(code, value);
      await (widget.scheduleReminders ?? TimetableReminderService.schedule)(
        catalog.slotsFor(_selected),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _selected = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.timetableSaveError),
        ),
      );
    }
  }

  String _slotText(BuildContext context, TimetableClass c) {
    final locale = Localizations.localeOf(context).toString();
    // 2026-10-19 is a Monday, so ISO weekday n falls on October 18 + n.
    final day = DateFormat.E(
      locale,
    ).format(DateTime(2026, 10, 18 + c.dayOfWeek));
    final time =
        '${TimetableEntry.formatTime(c.startMinutes)}'
        '–${TimetableEntry.formatTime(c.endMinutes)}';
    return c.hall == null ? '$day $time' : '$day $time · ${c.hall}';
  }

  // Departments the shared [DepartmentUIData] doesn't know about all come back
  // slate; spread them over a small palette so the list isn't one grey block.
  static const _palette = [
    Color(0xFF0EA5E9),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFF0D9488),
    Color(0xFFCA8A04),
    Color(0xFF4F46E5),
    Color(0xFF65A30D),
  ];

  ({IconData icon, Color color}) _look(
    String department,
    TimetableCatalog catalog,
  ) {
    final data = DepartmentUIData.fromDepartmentName(department);
    final isFallback = data.icon == Icons.account_balance_rounded;
    if (!isFallback) return (icon: data.icon, color: data.primaryColor);
    final i = catalog.departments.indexOf(department);
    return (
      icon: Icons.menu_book_rounded,
      color: _palette[i % _palette.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.timetableRemindersTitle,
          style: AppText.sectionTitle(context).copyWith(fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
          ? _message(
              Icons.cloud_off_rounded,
              l10n.timetableLoadError,
              retry: l10n.timetableRetry,
            )
          : _catalog!.courses.isEmpty
          ? _message(Icons.event_busy_rounded, l10n.timetableEmpty)
          : _content(context, l10n),
    );
  }

  Widget _message(IconData icon, String text, {String? retry}) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.body(
                context,
              ).copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (retry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _load, child: Text(retry)),
            ],
          ],
        ),
      ),
    );
  }

  /// The intro and the battery tip in one softly tinted card.
  Widget _introCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: primary.withOpacity(isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: primary.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.timetableRemindersIntro,
                  style: AppText.body(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.timetableBatteryNote,
                  style: AppText.cardSubtitle(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalog = _catalog!;
    final courses = catalog.filter(
      query: _query,
      departments: _departments,
      onlyCodes: _selectedOnly ? _selected : null,
    );

    // Courses arrive sorted by department; group consecutive runs.
    final groups = <String, List<TimetableCourse>>{};
    for (final c in courses) {
      groups.putIfAbsent(c.department, () => []).add(c);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        _introCard(context, l10n),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: TextField(
            controller: _searchController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: l10n.timetableSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              _FilterPill(
                key: const ValueKey('selected-only-pill'),
                label: _selected.isEmpty
                    ? l10n.timetableFilterSelected
                    : '${l10n.timetableFilterSelected} (${_selected.length})',
                icon: Icons.check_circle_outline_rounded,
                selected: _selectedOnly,
                onTap: () => setState(() => _selectedOnly = !_selectedOnly),
              ),
              for (final d in catalog.departments)
                _FilterPill(
                  key: ValueKey('dept-pill-$d'),
                  label: d,
                  color: _look(d, catalog).color,
                  selected: _departments.contains(d),
                  onTap: () => setState(() {
                    _departments.contains(d)
                        ? _departments.remove(d)
                        : _departments.add(d);
                  }),
                ),
            ],
          ),
        ),
        if (courses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 64),
            child: _message(Icons.search_off_rounded, l10n.timetableNoCourses),
          ),
        for (final entry in groups.entries) ...[
          SettingsSectionLabel(entry.key),
          // A Material (not a decorated Container) so the rows' ink and
          // selected tint paint on top of the card instead of beneath it.
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Material(
              color: isDark
                  ? theme.colorScheme.surfaceContainerLow
                  : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.15),
                ),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 72),
                    _courseTile(
                      context,
                      l10n,
                      entry.value[i],
                      _look(entry.key, catalog),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _courseTile(
    BuildContext context,
    AppLocalizations l10n,
    TimetableCourse course,
    ({IconData icon, Color color}) look,
  ) {
    final theme = Theme.of(context);
    final selected = _selected.contains(course.code);
    final extra = course.slots.length - 2;

    return CheckboxListTile(
      value: selected,
      onChanged: (v) => _toggle(course.code, v ?? false),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      tileColor: selected ? theme.colorScheme.primary.withOpacity(0.06) : null,
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      secondary: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? look.color : look.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          selected ? Icons.notifications_active_rounded : look.icon,
          size: 20,
          color: selected ? Colors.white : look.color,
        ),
      ),
      title: Text(course.code, style: AppText.cardTitle(context)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          [
            ...course.slots.take(2).map((s) => _slotText(context, s)),
            if (extra > 0) l10n.timetableMoreSlots(extra),
          ].join('\n'),
          style: AppText.cardSubtitle(context),
        ),
      ),
      isThreeLine: course.slots.length > 1,
    );
  }
}

/// Rounded filter pill matching the app's chip language: tinted fill and
/// outline in the item's colour when on, a quiet bordered pill when off.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tint = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected
            ? tint.withOpacity(isDark ? 0.22 : 0.12)
            : (isDark ? theme.colorScheme.surfaceContainerLow : Colors.white),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? tint.withOpacity(0.6)
                : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.25)),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected || icon != null) ...[
                  Icon(
                    selected ? Icons.check_rounded : icon,
                    size: 16,
                    color: selected ? tint : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppText.caption(context).copyWith(
                    fontSize: 12.5,
                    color: selected ? tint : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
