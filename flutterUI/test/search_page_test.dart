import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/pages/search_page.dart';
import 'package:flutter_ui_travelling/services/nearby_places_handler.dart';

void main() {
  testWidgets('search filters sample places and save is a placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchPage(
            nearbyPlacesLoader: () =>
                const NearbyPlacesHandler().loadNearbyPlaces(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.text('Nearby places'), findsOneWidget);
    expect(find.text('Ohori Park'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  SHRINE  ');
    await tester.pump();
    expect(find.text('Ohori Park'), findsOneWidget);
    expect(find.text('Kushida Shrine'), findsOneWidget);

    await tester.tap(find.byTooltip('Search places'));
    await tester.pump();
    expect(find.text('Kushida Shrine'), findsOneWidget);
    expect(find.text('Ohori Park'), findsNothing);
    await tester.tap(find.byTooltip('Save Kushida Shrine'));
    await tester.pump();
    expect(find.text('Saving places is not connected yet.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.byTooltip('Dismiss message'));
    await tester.pump();
    expect(find.text('Saving places is not connected yet.'), findsNothing);

    await tester.enterText(find.byType(TextField), 'not a place');
    await tester.pump();
    expect(find.text('Kushida Shrine'), findsOneWidget);
    await tester.tap(find.byTooltip('Search places'));
    await tester.pump();
    expect(find.text('No places found'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('No places found'), findsOneWidget);
    await tester.tap(find.byTooltip('Search places'));
    await tester.pump();
    expect(find.text('Ohori Park'), findsOneWidget);
  });
}
