import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/pages/search_page.dart';
import 'package:flutter_ui_travelling/services/api_client.dart';
import 'package:flutter_ui_travelling/services/cache/api_proxy.dart';
import 'package:flutter_ui_travelling/services/cache/cache_manager.dart';
import 'package:flutter_ui_travelling/services/nearby_places_handler.dart';
import 'package:flutter_ui_travelling/services/repositories/places_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parses nullable IDs and numeric coordinates', () {
    final place = NearbyPlace.fromJson({
      'name': 'Park',
      'location': 'Tokyo',
      'category': 'Park',
      'id': null,
      'google_place_id': null,
      'latitude': 35,
      'longitude': 139.5,
      'is_saved': true,
    });

    expect(place.id, isNull);
    expect(place.googlePlaceId, isNull);
    expect(place.latitude, 35.0);
    expect(place.longitude, 139.5);
    expect(place.isSaved, isTrue);

    final withoutCoordinates = NearbyPlace.fromJson({
      'name': 'Park',
      'location': 'Tokyo',
      'category': 'Park',
      'latitude': null,
      'longitude': null,
    });
    expect(withoutCoordinates.latitude, isNull);
    expect(withoutCoordinates.longitude, isNull);
  });

  test('createPlace sends API field names and numeric coordinates', () async {
    final requests = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      expect(request.url.path, '/api/places');
      expect(request.method, 'POST');
      requests.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response('{"place":{"id":"place-id"}}', 201);
    });
    final repository = PlacesRepository(
      proxy: ApiProxy(
        apiClient: ApiClient(baseUrl: 'http://localhost', client: client),
        cacheManager: CacheManager(),
      ),
    );

    await repository.createPlace(
      googlePlaceId: 'google-id',
      name: 'Park',
      location: 'Tokyo',
      latitude: 35.0,
      longitude: 139.5,
    );
    await repository.createPlace(name: 'Park', location: 'Tokyo');

    expect(requests[0], {
      'google_place_id': 'google-id',
      'name': 'Park',
      'location': 'Tokyo',
      'latitude': 35.0,
      'longitude': 139.5,
    });
    expect(requests[1], {'name': 'Park', 'location': 'Tokyo'});
    client.close();
  });

  testWidgets('save handles a place without a Google ID', (tester) async {
    const place = NearbyPlace(
      name: 'Park',
      location: 'Tokyo',
      category: 'Park',
    );
    NearbyPlace? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchPage(
            nearbyPlacesLoader: () async => [place],
            savedPlacesLoader: () async => [],
            savePlace: (value) async {
              saved = value;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('保存する: Park'));
    await tester.pumpAndSettle();

    expect(saved, same(place));
    expect(find.text('場所を保存しました。'), findsOneWidget);
    expect(find.byTooltip('保存済み: Park'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('save failures are shown instead of reporting success', (
    tester,
  ) async {
    const place = NearbyPlace(
      name: 'Park',
      location: 'Tokyo',
      category: 'Park',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchPage(
            nearbyPlacesLoader: () async => [place],
            savedPlacesLoader: () async => [],
            savePlace: (_) async => throw Exception('request failed'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('保存する: Park'));
    await tester.pumpAndSettle();

    expect(find.textContaining('場所の保存に失敗しました:'), findsOneWidget);
    expect(find.text('場所を保存しました。'), findsNothing);
  });
}
