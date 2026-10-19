import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_study/Screens/UI/preview/Navigation/next_class_card.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/timetable_class.dart';
import 'package:go_study/services/timetable_repository.dart';

class FakeRepo extends TimetableRepository {
  final List<TimetableClass> classes;
  final Set<String> selected;
  final bool fail;

  FakeRepo(this.classes, {Set<String>? selected, this.fail = false})
      : selected = selected ?? {};

  @override
  Future<List<TimetableClass>> fetchClasses() async {
    if (fail) throw Exception('offline');
    return classes;
  }

  @override
  Future<Set<String>> fetchSelectedCodes() async {
    if (fail) throw Exception('offline');
    return {...selected};
  }
}

TimetableClass slot(String code, int day, int start, int end, {String? hall}) =>
    TimetableClass(
      department: 'D',
      program: 'D',
      courseCode: code,
      dayOfWeek: day,
      startMinutes: start,
      endMinutes: end,
      hall: hall,
    );

Widget app(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

Future<void> pump(WidgetTester tester, FakeRepo repo, DateTime now) async {
  await tester.pumpWidget(app(NextClassCard(repository: repo, clock: () => now)));
  await tester.pumpAndSettle();
}

Future<void> unmount(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox()); // cancels the card's ticker

void main() {
  // 2026-10-19 is a Monday.
  final classes = [
    slot('CSC301', 1, 480, 600, hall: 'AMPHI 150 E'), // Mon 08:00-10:00
    slot('PHY203', 1, 840, 960, hall: 'U-BLOCK F'), // Mon 14:00-16:00
    slot('MAT201', 2, 420, 540), // Tue 07:00-09:00, no hall
    slot('OTHER101', 1, 540, 600, hall: 'G102-G103'), // not selected
  ];

  testWidgets('shows the class in session and the next one', (tester) async {
    await pump(
      tester,
      FakeRepo(classes, selected: {'CSC301', 'PHY203', 'MAT201'}),
      DateTime(2026, 10, 19, 9), // Mon 09:00
    );

    expect(find.text('Now'), findsOneWidget);
    expect(find.text('CSC301'), findsOneWidget);
    expect(find.text('AMPHI 150 E · Ends in 1 h'), findsOneWidget);

    expect(find.text('Next'), findsOneWidget);
    expect(find.text('PHY203'), findsOneWidget);
    expect(find.text('Today 14:00 · U-BLOCK F · In 5 h'), findsOneWidget);

    expect(find.text('OTHER101'), findsNothing);
    await unmount(tester);
  });

  testWidgets('only the next class when nothing is in session', (tester) async {
    await pump(
      tester,
      FakeRepo(classes, selected: {'CSC301', 'PHY203'}),
      DateTime(2026, 10, 19, 12), // Mon 12:00, between classes
    );

    expect(find.text('Now'), findsNothing);
    expect(find.text('PHY203'), findsOneWidget);
    expect(find.text('Today 14:00 · U-BLOCK F · In 2 h'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('tomorrow\'s class with no hall omits the venue', (tester) async {
    await pump(
      tester,
      FakeRepo(classes, selected: {'MAT201'}),
      DateTime(2026, 10, 19, 20, 30), // Mon 20:30
    );

    expect(find.text('MAT201'), findsOneWidget);
    expect(find.text('Tomorrow 07:00 · In 10 h 30 min'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a class days away shows the weekday, no countdown',
      (tester) async {
    await pump(
      tester,
      FakeRepo(classes, selected: {'MAT201'}),
      DateTime(2026, 10, 20, 12), // Tue noon -> next Tue 07:00
    );

    expect(find.text('Tue 07:00'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('invites the user to pick courses when none are chosen',
      (tester) async {
    await pump(tester, FakeRepo(classes), DateTime(2026, 10, 19, 9));

    expect(find.text('Never miss a class'), findsOneWidget);
    expect(find.text('Now'), findsNothing);
    await unmount(tester);
  });

  testWidgets('stays hidden when the timetable cannot be loaded',
      (tester) async {
    await pump(tester, FakeRepo(classes, fail: true), DateTime(2026, 10, 19, 9));

    expect(find.byType(Container), findsNothing);
    expect(find.text('Never miss a class'), findsNothing);
    await unmount(tester);
  });
}
