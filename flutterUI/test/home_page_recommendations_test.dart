import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/pages/chat_page.dart';
import 'package:flutter_ui_travelling/pages/home_page.dart';
import 'package:flutter_ui_travelling/services/nearby_places_handler.dart';

void main() {
  testWidgets('empty home shows recommendations and opens a prefilled chat', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            upcomingTripLoader: () async => {'trip': null},
            nearbyPlacesLoader: () async => const [
              NearbyPlace(name: '大濠公園', location: '福岡市', category: '公園'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('人気の旅行先'), findsOneWidget);
    expect(find.text('おすすめの旅行先'), findsOneWidget);
    expect(find.text('近場の旅行先'), findsOneWidget);
    expect(find.text('現在地の近くでおすすめ'), findsOneWidget);
    expect(find.text('大濠公園'), findsOneWidget);

    await tester.tap(find.text('大阪').first);
    await tester.pumpAndSettle();

    expect(find.byType(ChatPage), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '大阪への旅行を計画したいです。',
    );
  });
}
