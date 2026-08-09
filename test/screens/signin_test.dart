import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_study/Screens/authentication/signin.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/auth.dart';

class MockAuthentication extends Mock implements Authentication {}

void main() {
  late MockAuthentication mockAuthentication;

  setUp(() {
    mockAuthentication = MockAuthentication();
    when(() => mockAuthentication.currentUser).thenReturn(null);
  });

  Widget createSigninScreen({required Function istoggle}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Signin(istoggle: istoggle, authService: mockAuthentication),
    );
  }

  testWidgets('Signin screen should render correctly', (tester) async {
    await tester.pumpWidget(createSigninScreen(istoggle: () {}));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Signin should show validation errors when fields are empty', (
    tester,
  ) async {
    await tester.pumpWidget(createSigninScreen(istoggle: () {}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Minimum 6 characters'), findsOneWidget);
  });
}
