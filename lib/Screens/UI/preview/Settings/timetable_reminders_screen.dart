import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/timetable_catalog.dart';
import 'package:go_study/services/timetable_class.dart';
import 'package:go_study/services/timetable_entry.dart';
import 'package:go_study/services/timetable_reminder_service.dart';
import 'package:go_study/services/timetable_repository.dart';

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
          catalog.slotsFor(_selected));
    } catch (_) {
      if (!mounted) return;
      setState(() => _selected = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.timetableSaveError)),
      );
    }
  }

  String _slotText(BuildContext context, TimetableClass c) {
    final locale = Localizations.localeOf(context).toString();
    // 2026-10-19 is a Monday, so ISO weekday n falls on October 18 + n.
    final day = DateFormat.E(locale).format(DateTime(2026, 10, 18 + c.dayOfWeek));
    final time = '${TimetableEntry.formatTime(c.startMinutes)}'
        '–${TimetableEntry.formatTime(c.endMinutes)}';
    return c.hall == null ? '$day $time' : '$day $time · ${c.hall}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.timetableRemindersTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? _message(l10n.timetableLoadError, retry: l10n.timetableRetry)
              : _catalog!.courses.isEmpty
                  ? _message(l10n.timetableEmpty)
                  : _content(context, l10n, theme),
    );
  }

  Widget _message(String text, {String? retry}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, textAlign: TextAlign.center),
              if (retry != null) ...[
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: Text(retry)),
              ],
            ],
          ),
        ),
      );

  Widget _content(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final catalog = _catalog!;
    final courses = catalog.filter(
      query: _query,
      departments: _departments,
      onlyCodes: _selectedOnly ? _selected : null,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(l10n.timetableRemindersIntro,
              style: theme.textTheme.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: l10n.timetableSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(_selected.isEmpty
                      ? l10n.timetableFilterSelected
                      : '${l10n.timetableFilterSelected} '
                          '(${_selected.length})'),
                  selected: _selectedOnly,
                  onSelected: (v) => setState(() => _selectedOnly = v),
                ),
              ),
              for (final d in catalog.departments)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(d),
                    selected: _departments.contains(d),
                    onSelected: (v) => setState(() {
                      v ? _departments.add(d) : _departments.remove(d);
                    }),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: courses.isEmpty
              ? Center(child: Text(l10n.timetableNoCourses))
              : ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, i) {
                    final course = courses[i];
                    final showHeader =
                        i == 0 || courses[i - 1].department != course.department;
                    final extra = course.slots.length - 2;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              course.department,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        CheckboxListTile(
                          value: _selected.contains(course.code),
                          onChanged: (v) => _toggle(course.code, v ?? false),
                          title: Text(course.code),
                          subtitle: Text([
                            ...course.slots
                                .take(2)
                                .map((s) => _slotText(context, s)),
                            if (extra > 0) l10n.timetableMoreSlots(extra),
                          ].join('\n')),
                          isThreeLine: course.slots.length > 1,
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
