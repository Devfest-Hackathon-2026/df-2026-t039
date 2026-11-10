import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/widgets/trip_details.dart';

void main() {
  for (final width in [320.0, 180.0]) {
    testWidgets('trip summary fits width $width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: const TripDetails(
                  trip: {
                    'title': '旅行',
                    'start_date': '2026-11-10',
                    'end_date': '2026-11-15',
                    'budget': 12345678,
                    'itinerary': [],
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final bounds = tester.getRect(find.byType(TripDetails));
      for (final text in [
        '2026-11-10 ～ 2026-11-15 ',
        '予算： 12345678円',
      ]) {
        final rect = tester.getRect(find.text(text));
        expect(rect.left, greaterThanOrEqualTo(bounds.left + 10));
        expect(rect.right, lessThanOrEqualTo(bounds.right - 10));
      }
      if (width == 180) {
        expect(
          tester.getTopLeft(find.text('予算： 12345678円')).dy,
          greaterThanOrEqualTo(
            tester.getBottomLeft(find.text('2026-11-10 ～ 2026-11-15 ')).dy,
          ),
        );
      }
    });
  }
}
