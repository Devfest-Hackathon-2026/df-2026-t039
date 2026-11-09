import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/main.dart';
import 'package:flutter_ui_travelling/pages/settings_page.dart';

void main() {
  testWidgets('settings shows a frontend-only logout button', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.byType(BottomAppBar), findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pump();
    expect(find.text('Logout is not connected yet.'), findsOneWidget);
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
