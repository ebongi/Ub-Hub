import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neo/Screens/authentication/signin.dart';
import 'package:neo/services/auth.dart';

class MockAuthentication extends Mock implements Authentication {}

void main() {
  late MockAuthentication mockAuthentication;

  setUp(() {
    mockAuthentication = MockAuthentication();
    when(() => mockAuthentication.currentUser).thenReturn(null);
  });

  Widget createSigninScreen({required Function istoggle}) {
    return MaterialApp(
      home: Signin(istoggle: istoggle, authService: mockAuthentication),
    );
  }

  testWidgets('Signin screen should render correctly', (tester) async {
    await tester.pumpWidget(createSigninScreen(istoggle: () {}));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Signin should show validation errors when fields are empty', (
    tester,
  ) async {
    await tester.pumpWidget(createSigninScreen(istoggle: () {}));

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });
}
