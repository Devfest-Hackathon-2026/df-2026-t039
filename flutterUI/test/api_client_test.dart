import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('reads the base URL from dart defines when supplied', () async {
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    if (baseUrl.isEmpty) return;
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.url.host, Uri.parse(baseUrl).host);
        return http.Response('{"ok":true}', 200);
      }),
    );
    addTearDown(client.close);
    expect(await client.healthCheck(), isTrue);
  });

  test('health check uses the configured base URL', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:8080/health');
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response('{"ok":true}', 200);
      }),
    );
    addTearDown(client.close);

    expect(await client.healthCheck(), isTrue);
  });

  test('authenticated requests send the token, query and JSON body', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com/',
      tokenProvider: () async => 'firebase-token',
      client: MockClient((request) async {
        expect(request.url.path, '/api/trips');
        expect(request.url.queryParameters['status'], 'planned');
        expect(request.headers['Authorization'], 'Bearer firebase-token');
        expect(jsonDecode(request.body), {'destination': 'Tokyo'});
        return http.Response('{"trip":{"id":"123"}}', 201);
      }),
    );
    addTearDown(client.close);

    final result = await client.request(
      'POST',
      '/api/trips',
      query: {'status': 'planned'},
      body: {'destination': 'Tokyo'},
    );
    expect(result['trip']['id'], '123');
  });

  test('API errors include the status and server message', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient(
        (_) async => http.Response('{"error":{"message":"Unauthorized"}}', 401),
      ),
    );
    addTearDown(client.close);

    await expectLater(
      client.request('GET', '/me'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 401)
            .having((error) => error.message, 'message', 'Unauthorized'),
      ),
    );
  });

  test('non-JSON errors still report the HTTP status', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((_) async => http.Response('Bad gateway', 502)),
    );
    addTearDown(client.close);
    await expectLater(
      client.request('GET', '/health'),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 502),
      ),
    );
  });

  test('rejects absolute request URLs before requesting a token', () async {
    var tokenRequested = false;
    final client = ApiClient(
      baseUrl: 'https://example.com',
      tokenProvider: () async {
        tokenRequested = true;
        return 'firebase-token';
      },
    );
    addTearDown(client.close);
    await expectLater(
      client.request('GET', 'https://other.example/'),
      throwsArgumentError,
    );
    expect(tokenRequested, isFalse);
  });
}
