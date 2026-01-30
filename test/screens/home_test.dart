import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'package:neo/Screens/UI/preview/Navigation/home.dart';
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:neo/services/department.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakeSupabaseStreamFilterBuilder extends Fake
    implements SupabaseStreamFilterBuilder {
  @override
  StreamSubscription<List<Map<String, dynamic>>> listen(
    void Function(List<Map<String, dynamic>> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<Map<String, dynamic>>>.fromIterable([
      <Map<String, dynamic>>[],
    ]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    final mockQueryBuilder = MockSupabaseQueryBuilder();
    when(() => mockSupabase.from('departments')).thenReturn(mockQueryBuilder);
    when(
      () => mockQueryBuilder.stream(primaryKey: any(named: 'primaryKey')),
    ).thenReturn(FakeSupabaseStreamFilterBuilder());
  });

  Widget createHomeScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserModel(name: 'TEST USER')),
        Provider<List<Department>?>(
          create: (_) => [], // Empty department list for simulation
        ),
      ],
      child: MaterialApp(home: Home(supabaseClient: mockSupabase)),
    );
  }

  testWidgets('Home screen should render AppBar and IntroWidget', (
    tester,
  ) async {
    await tester.pumpWidget(createHomeScreen());

    expect(find.text('Hello, TEST USER'), findsOneWidget);
    expect(find.text('What will you learn today?'), findsOneWidget);
    expect(find.text('Departments'), findsOneWidget);
    expect(find.text('Toolbox'), findsOneWidget);
  });

  testWidgets('Home screen should show chat and add fab icons', (tester) async {
    await tester.pumpWidget(createHomeScreen());

    expect(find.byIcon(Icons.chat_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Tapping on a tool should attempt navigation', (tester) async {
    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    // Tap on GPA Calculator
    final toolFinder = find.text('GPA Calculator');
    expect(toolFinder, findsOneWidget);
    await tester.tap(toolFinder);
    await tester.pumpAndSettle();

    // Verify it navigated away from home
    expect(find.byType(Home), findsNothing);
  });
}
