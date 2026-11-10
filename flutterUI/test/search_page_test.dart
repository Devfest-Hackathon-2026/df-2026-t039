import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/pages/chat_page.dart';
import 'package:flutter_ui_travelling/pages/search_page.dart';
import 'package:flutter_ui_travelling/services/nearby_places_handler.dart';

void main() {
  testWidgets('search, save status, and empty-query nearby results work', (
    tester,
  ) async {
    const nearbyPlaces = NearbyPlacesHandler();
    var nearbyLoads = 0;
    final places = await nearbyPlaces.loadNearbyPlaces();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchPage(
            nearbyPlacesLoader: () async {
              nearbyLoads++;
              return places;
            },
            placesSearchLoader: (query) async => places
                .where((place) => place.name.toLowerCase().contains(query))
                .toList(),
            savedPlacesLoader: () async => [
              {'name': 'Ohori Park', 'location': 'Fukuoka'},
            ],
            savePlace: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
    expect(find.text('近くの場所'), findsOneWidget);
    expect(find.text('Ohori Park'), findsOneWidget);
    final savedParkButton = find
        .ancestor(
          of: find.byTooltip('保存済み: Ohori Park'),
          matching: find.byType(IconButton),
        )
        .first;
    expect(tester.widget<IconButton>(savedParkButton).color, Colors.red);
    expect(
      find.descendant(
        of: savedParkButton,
        matching: find.byIcon(Icons.favorite),
      ),
      findsOneWidget,
    );
    expect(nearbyLoads, 1);

    await tester.enterText(find.byType(TextField), '  SHRINE  ');
    await tester.pump();
    expect(find.text('Ohori Park'), findsOneWidget);
    expect(find.text('Kushida Shrine'), findsOneWidget);

    await tester.tap(find.byTooltip('場所を検索'));
    await tester.pumpAndSettle();
    expect(find.text('Kushida Shrine'), findsOneWidget);
    expect(find.text('Ohori Park'), findsNothing);
    await tester.tap(find.byTooltip('保存する: Kushida Shrine'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsNothing);
    expect(find.text('場所を保存しました。'), findsOneWidget);
    final savedShrineButton = find
        .ancestor(
          of: find.byTooltip('保存済み: Kushida Shrine'),
          matching: find.byType(IconButton),
        )
        .first;
    expect(tester.widget<IconButton>(savedShrineButton).color, Colors.red);
    expect(
      find.descendant(
        of: savedShrineButton,
        matching: find.byIcon(Icons.favorite),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Kushida Shrine'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Kushida Shrineへの旅行を計画したいです。',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byTooltip('保存済み: Kushida Shrine'), findsOneWidget);
    await tester.tap(find.byTooltip('メッセージを閉じる'));
    await tester.pump();
    expect(find.text('場所を保存しました。'), findsNothing);

    await tester.enterText(find.byType(TextField), 'not a place');
    await tester.pump();
    expect(find.text('Kushida Shrine'), findsOneWidget);
    await tester.tap(find.byTooltip('場所を検索'));
    await tester.pumpAndSettle();
    expect(find.text('場所が見つかりませんでした'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('場所が見つかりませんでした'), findsOneWidget);
    await tester.tap(find.byTooltip('場所を検索'));
    await tester.pumpAndSettle();
    expect(find.text('Ohori Park'), findsOneWidget);
    expect(nearbyLoads, 2);
    await tester.tap(find.text('Ohori Park'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Ohori Parkへの旅行を計画したいです。',
    );
  });
}
