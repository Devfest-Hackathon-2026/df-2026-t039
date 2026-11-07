import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/main.dart';

void main() {
  testWidgets('profile displays the user loaded by UserDataHandler', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('johndoe@example.com'), findsOneWidget);
    expect(find.text('123 Main St'), findsOneWidget);

    await tester.tap(find.text('Personal information'));
    await tester.pumpAndSettle();
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Age: 30'), findsOneWidget);
    expect(find.text('Hobbies:'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Traveling'), findsOneWidget);
    expect(find.text('Coding'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('Personal Information')).dy,
      lessThan(tester.getTopLeft(find.byType(BottomAppBar)).dy),
    );

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Personal Information'), findsNothing);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Personal Information'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('johndoe@example.com'), findsOneWidget);

    await tester.tap(find.text('Personal information'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('johndoe@example.com'), findsOneWidget);
    expect(find.text('Personal Information'), findsNothing);
  });
}
