import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/Screens/UI/preview/Settings/timetable_reminders_screen.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/timetable_class.dart';
import 'package:go_study/services/timetable_repository.dart';

class FakeRepo extends TimetableRepository {
  final List<TimetableClass> classes;
  final Set<String> selected;
  final bool failWrites;
  final writes = <String>[];

  FakeRepo(this.classes, {Set<String>? selected, this.failWrites = false})
      : selected = selected ?? {};

  @override
  Future<List<TimetableClass>> fetchClasses() async => classes;

  @override
  Future<Set<String>> fetchSelectedCodes() async => {...selected};

  @override
  Future<void> setSelected(String courseCode, bool value) async {
    if (failWrites) throw Exception('boom');
    writes.add('${value ? '+' : '-'}$courseCode');
  }
}

TimetableClass slot(String dept, String code, int day, int start) =>
    TimetableClass(
      department: dept,
      program: dept,
      courseCode: code,
      dayOfWeek: day,
      startMinutes: start,
      endMinutes: start + 120,
      hall: 'AMPHI 600',
    );

Widget app(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  final classes = [
    slot('COMPUTER SCIENCE', 'CSC301', 4, 420),
    slot('COMPUTER SCIENCE', 'CSC205', 1, 900),
    slot('PHYSICS', 'PHY203', 2, 420),
  ];

  testWidgets('lists departments and courses, search and filter narrow them',
      (tester) async {
    await tester.pumpWidget(app(TimetableRemindersScreen(
      repository: FakeRepo(classes),
      scheduleReminders: (_) async {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('CSC301'), findsOneWidget);
    expect(find.text('PHY203'), findsOneWidget);
    expect(find.byKey(const ValueKey('dept-pill-PHYSICS')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dept-pill-PHYSICS')));
    await tester.pumpAndSettle();
    expect(find.text('PHY203'), findsOneWidget);
    expect(find.text('CSC301'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dept-pill-PHYSICS')));
    await tester.enterText(find.byType(TextField), 'csc2');
    await tester.pumpAndSettle();
    expect(find.text('CSC205'), findsOneWidget);
    expect(find.text('CSC301'), findsNothing);
  });

  testWidgets('ticking a course saves it and reschedules reminders',
      (tester) async {
    final repo = FakeRepo(classes);
    List<TimetableClass>? scheduled;
    await tester.pumpWidget(app(TimetableRemindersScreen(
      repository: repo,
      scheduleReminders: (slots) async => scheduled = slots,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CheckboxListTile, 'CSC301'));
    await tester.pumpAndSettle();

    expect(repo.writes, ['+CSC301']);
    expect(scheduled!.map((s) => s.courseCode), ['CSC301']);
    expect(tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'CSC301')).value, isTrue);
  });

  testWidgets('a failed save reverts the tick and shows a message',
      (tester) async {
    await tester.pumpWidget(app(TimetableRemindersScreen(
      repository: FakeRepo(classes, failWrites: true),
      scheduleReminders: (_) async {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CheckboxListTile, 'CSC301'));
    await tester.pumpAndSettle();

    expect(tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'CSC301')).value, isFalse);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('selected-only filter shows just the chosen courses',
      (tester) async {
    await tester.pumpWidget(app(TimetableRemindersScreen(
      repository: FakeRepo(classes, selected: {'PHY203'}),
      scheduleReminders: (_) async {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Selected only (1)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('selected-only-pill')));
    await tester.pumpAndSettle();
    expect(find.text('PHY203'), findsOneWidget);
    expect(find.text('CSC301'), findsNothing);
  });

  testWidgets('shows the empty state when no timetable is published',
      (tester) async {
    await tester.pumpWidget(app(TimetableRemindersScreen(
      repository: FakeRepo(const []),
      scheduleReminders: (_) async {},
    )));
    await tester.pumpAndSettle();
    expect(find.text("The timetable hasn't been published yet."), findsOneWidget);
  });
}
