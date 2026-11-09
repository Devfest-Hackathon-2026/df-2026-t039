import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/main.dart';
import 'package:flutter_ui_travelling/pages/saved_places_page.dart';
import 'package:flutter_ui_travelling/services/user_data_handler.dart';

void main() {
  testWidgets('profile opens saved places and preserves bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved places'));
    await tester.pump();
    expect(find.byType(SlideTransition), findsWidgets);
    await tester.pumpAndSettle();

    expect(find.byType(SavedPlacesPage), findsOneWidget);
    expect(find.text('Fushimi Inari Taisha'), findsOneWidget);
    expect(find.text('Kyoto'), findsOneWidget);
    expect(find.text('Osaka Castle'), findsOneWidget);
    expect(find.byType(BottomAppBar), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SavedPlacesPage), findsNothing);
    expect(find.text('johndoe@example.com'), findsOneWidget);
  });

  testWidgets('displays an empty saved places list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SavedPlacesPage(userData: {'saved_places': []}),
      ),
    );
    expect(find.text('No saved places'), findsOneWidget);
  });

  testWidgets('the second user has saved places', (tester) async {
    final user = await const UserDataHandler().loadUserData(
      assetPath: 'lib/data/example_user_2_data.json',
    );
    await tester.pumpWidget(MaterialApp(home: SavedPlacesPage(userData: user)));
    expect(find.text('Ohori Park'), findsOneWidget);
    expect(find.text('Fukuoka'), findsOneWidget);
  });
}
