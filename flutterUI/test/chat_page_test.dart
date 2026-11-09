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

    expect(find.text('Travel assistant'), findsOneWidget);
    expect(find.text('Plan your next trip'), findsOneWidget);
    expect(find.text('Recent conversations'), findsNothing);
    expect(find.textContaining('not connected yet'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });

  testWidgets('sends a message locally and prevents blank messages', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChatPage()));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), '  Plan a trip to Kyoto  ');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    expect(find.text('Plan a trip to Kyoto'), findsOneWidget);
    expect(find.text('Plan your next trip'), findsNothing);
    expect(
      find.text('Assistant replies are not connected yet.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });
}
