// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ui_travelling/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0 times'), findsOneWidget);
    expect(find.text('1 times'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0 times'), findsNothing);
    expect(find.text('1 times'), findsOneWidget);
  });

  testWidgets('Bottom navigation has a centered docked add button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final bar = tester.widget<BottomAppBar>(find.byType(BottomAppBar));
    expect(bar.shape, isA<CircularNotchedRectangle>());
    expect(
      tester.getCenter(find.byType(FloatingActionButton)).dx,
      tester.getCenter(find.byType(BottomAppBar)).dx,
    );
    expect(
      tester.getCenter(find.byType(FloatingActionButton)).dy,
      lessThan(tester.getCenter(find.byType(BottomAppBar)).dy),
    );

    await tester.tap(find.text('Search'));
    await tester.pump();
    expect(
      tester
          .widgetList<Semantics>(
            find.ancestor(
              of: find.text('Search'),
              matching: find.byType(Semantics),
            ),
          )
          .any((semantics) => semantics.properties.selected == true),
      isTrue,
    );
  });
}
