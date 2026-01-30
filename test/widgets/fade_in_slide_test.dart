import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neo/Screens/Shared/animations.dart';

void main() {
  testWidgets('FadeInSlide should render child', (tester) async {
    const childKey = Key('child');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeInSlide(
            child: SizedBox(key: childKey, width: 10, height: 10),
          ),
        ),
      ),
    );

    expect(find.byKey(childKey), findsOneWidget);
  });

  testWidgets('FadeInSlide should animate opacity and offset', (tester) async {
    const childKey = Key('child');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeInSlide(
            duration: Duration(milliseconds: 500),
            beginOffset: 0.5,
            child: SizedBox(key: childKey, width: 10, height: 10),
          ),
        ),
      ),
    );

    // Initial state: opacity should be low
    var fadeTransition = tester.widget<FadeTransition>(
      find.byType(FadeTransition).first,
    );
    expect(fadeTransition.opacity.value, 0.0);

    // End of animation
    await tester.pumpAndSettle();
    fadeTransition = tester.widget<FadeTransition>(
      find.byType(FadeTransition).first,
    );
    expect(fadeTransition.opacity.value, 1.0);
  });
}
