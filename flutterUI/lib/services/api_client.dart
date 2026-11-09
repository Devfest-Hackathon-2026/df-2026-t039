import 'dart:convert';

import 'package:http/http.dart' as http;

typedef ApiTokenProvider = Future<String?> Function();

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'API error $statusCode: $message';
}

class ApiClient {
  ApiClient({
    String baseUrl = const String.fromEnvironment('API_BASE_URL'),
    http.Client? client,
    this.tokenProvider,
  }) : _baseUri = _parseBaseUrl(baseUrl),
       _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final ApiTokenProvider? tokenProvider;

  static Uri _parseBaseUrl(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError('API_BASE_URL must be an absolute HTTP(S) URL.');
    }
    return uri.replace(path: '${uri.path.replaceAll(RegExp(r'/+$'), '')}/');
  }

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final relativePath = Uri.parse(path.replaceFirst(RegExp(r'^/+'), ''));
    if (relativePath.hasScheme ||
        relativePath.hasAuthority ||
        relativePath.hasQuery ||
        relativePath.hasFragment ||
        relativePath.pathSegments.any((segment) => segment == '..')) {
      throw ArgumentError('API path must be a relative path without a query.');
    }
    final uri = _baseUri
        .resolveUri(relativePath)
        .replace(queryParameters: query);
    final token = await tokenProvider?.call();
    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    final text = utf8.decode(response.bodyBytes);
    dynamic data;
    if (text.isNotEmpty) {
      try {
        data = jsonDecode(text);
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) rethrow;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = data is Map<String, dynamic> ? data['error'] : null;
      final message = error is Map<String, dynamic> ? error['message'] : null;
      throw ApiException(
        response.statusCode,
        message?.toString() ?? 'Request failed',
      );
    }
    return data;
  }

  Future<bool> healthCheck() async {
    final data = await request('GET', '/health');
    return data is Map<String, dynamic> && data['ok'] == true;
  }

  void close() => _client.close();
}
