import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/pages/chat_page.dart';

void main() {
  testWidgets('empty chat fits a short viewport', (tester) async {
    tester.view.physicalSize = const Size(400, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ChatPage()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an assistant chat without recent conversations', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChatPage()));

    expect(find.text('旅行アシスタント'), findsOneWidget);
    expect(find.text('次の旅行を計画しましょう'), findsOneWidget);
    expect(find.text('最近の会話'), findsNothing);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.arrow_upward),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('prevents blank messages', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatPage()));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.arrow_upward),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), 'Plan a trip to Kyoto');
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.arrow_upward),
          )
          .onPressed,
      isNotNull,
    );
  });
}
