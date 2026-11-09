import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/main.dart';
import 'package:flutter_ui_travelling/pages/my_trips_page.dart';
import 'package:flutter_ui_travelling/pages/trip_details_page.dart';

void main() {
  testWidgets('My trips slides in within profile and keeps navigation visible', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Start: 2027-07-01'), findsOneWidget);
    expect(find.text('1日目'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My trips'));
    await tester.pump();
    expect(find.byType(SlideTransition), findsWidgets);
    await tester.pumpAndSettle();

    expect(find.byType(MyTripsPage), findsOneWidget);
    expect(find.text('Upcoming trips'), findsNothing);
    expect(find.text('Osaka'), findsNothing);
    expect(find.text('Trip history'), findsOneWidget);
    expect(find.text('Kyoto'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(BottomAppBar), findsOneWidget);

    await tester.tap(find.text('Kyoto'));
    await tester.pumpAndSettle();
    expect(find.byType(TripDetailsPage), findsOneWidget);
    expect(find.text('Kyoto'), findsOneWidget);
    expect(find.text('Start: 2023-12-01'), findsOneWidget);
    expect(find.text('End: 2023-12-02'), findsOneWidget);
    expect(find.text('Budget: 20000'), findsOneWidget);
    expect(find.text('1日目'), findsOneWidget);
    expect(find.text('2日目'), findsOneWidget);
    expect(find.text('09:00 - 09:30:'), findsOneWidget);
    expect(find.byType(BottomAppBar), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(MyTripsPage), findsOneWidget);

    await tester.tap(find.text('Iwate'));
    await tester.pumpAndSettle();
    expect(find.text('Iwate'), findsOneWidget);
    expect(find.text('Start: 2023-10-01'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MyTripsPage), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(MyTripsPage), findsNothing);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(MyTripsPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MyTripsPage), findsNothing);
    expect(find.text('johndoe@example.com'), findsOneWidget);
  });

  testWidgets('My trips shows empty history', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MyTripsPage(userData: {'history': []}),
      ),
    );
    expect(find.text('No upcoming trips'), findsNothing);
    expect(find.text('No past trips'), findsOneWidget);
  });
}
