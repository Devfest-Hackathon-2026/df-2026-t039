import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/pages/chat_page.dart';
import 'package:flutter_ui_travelling/pages/saved_places_page.dart';

void main() {
  testWidgets('chat covers outer navigation from nested saved places', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            tooltip: '新しい旅行を作成',
            child: const Icon(Icons.add),
          ),
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => SavedPlacesPage(
                loadSavedPlaces: () async => {
                  'places': [
                    {'id': '1', 'name': '大濠公園', 'location': '福岡'},
                  ],
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('新しい旅行を作成'), findsOneWidget);

    await tester.tap(find.text('大濠公園 '));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);
    expect(find.byTooltip('新しい旅行を作成'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '大濠公園への旅行を計画したいです。',
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byTooltip('新しい旅行を作成'), findsOneWidget);
    expect(find.text('大濠公園 '), findsOneWidget);
  });

  testWidgets('saved place opens chat, heart confirms deletion', (tester) async {
    final places = [
      {'id': '1', 'name': '大濠公園', 'location': '福岡'},
    ];
    final deleted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SavedPlacesPage(
          loadSavedPlaces: () async => {'places': List.of(places)},
          deleteSavedPlace: (id) async {
            deleted.add(id);
            places.removeWhere((place) => place['id'] == id);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('大濠公園 '));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '大濠公園への旅行を計画したいです。',
    );
    expect(deleted, isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('大濠公園を保存した場所から削除'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsNothing);
    expect(find.text('保存した場所の削除'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(deleted, isEmpty);
    expect(find.text('大濠公園 '), findsOneWidget);

    await tester.tap(find.byTooltip('大濠公園を保存した場所から削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();
    expect(deleted, ['1']);
    expect(find.text('大濠公園 '), findsNothing);
    expect(find.text('保存した場所はありません.'), findsOneWidget);
  });

  testWidgets('deletion failure leaves the place visible and shows an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SavedPlacesPage(
          loadSavedPlaces: () async => {
            'places': [
              {'id': '1', 'name': '大濠公園', 'location': '福岡'},
            ],
          },
          deleteSavedPlace: (_) async => throw Exception('通信エラー'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('大濠公園を保存した場所から削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(find.text('大濠公園 '), findsOneWidget);
    expect(find.textContaining('場所を削除できませんでした:'), findsOneWidget);
  });
}
