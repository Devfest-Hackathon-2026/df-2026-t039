import '../api_client.dart';
import 'cache_manager.dart';

/// API Proxy with caching to reduce backend calls
class ApiProxy {
  ApiProxy({
    required this.apiClient,
    required this.cacheManager,
    this.enableCache = true,
    this.defaultCacheTtl = CacheManager.defaultTtl,
  });

  final ApiClient apiClient;
  final CacheManager cacheManager;
  final bool enableCache;
  final int defaultCacheTtl;

  /// Generate cache key for GET requests
  String _generateCacheKey(String method, String path, {Map<String, String>? query}) {
    String key = '$method:$path';
    if (query != null && query.isNotEmpty) {
      final sortedParams = query.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      key += '?${sortedParams.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    return key;
  }

  /// Make a GET request with caching
  Future<T> getWithCache<T>(
    String path, {
    Map<String, String>? query,
    int? cacheTtl,
    bool forceRefresh = false,
  }) async {
    if (!enableCache) {
      return apiClient.request('GET', path, query: query) as Future<T>;
    }

    final cacheKey = _generateCacheKey('GET', path, query: query);

    // Return cached data if available and not forcing refresh
    if (!forceRefresh) {
      final cached = cacheManager.get<T>(cacheKey);
      if (cached != null) return cached;
    }

    final response = await apiClient.request('GET', path, query: query) as T;

    // Store in cache
    cacheManager.set(cacheKey, response, ttlSeconds: cacheTtl ?? defaultCacheTtl);

    return response;
  }

  /// Make a POST request (not cached, but can invalidate related caches)
  Future<T> post<T>(
    String path, {
    Map<String, String>? query,
    Object? body,
    List<String>? cacheInvalidationPatterns,
  }) async {
    final response = await apiClient.request('POST', path, query: query, body: body) as T;

    // Invalidate related caches
    _invalidateCaches(cacheInvalidationPatterns);

    return response;
  }

  /// Make a PATCH/PUT request (not cached, but can invalidate related caches)
  Future<T> patch<T>(
    String path, {
    Map<String, String>? query,
    Object? body,
    List<String>? cacheInvalidationPatterns,
  }) async {
    final response = await apiClient.request('PATCH', path, query: query, body: body) as T;

    // Invalidate related caches
    _invalidateCaches(cacheInvalidationPatterns);

    return response;
  }

  /// Make a PUT request (not cached, but can invalidate related caches)
  Future<T> put<T>(
    String path, {
    Map<String, String>? query,
    Object? body,
    List<String>? cacheInvalidationPatterns,
  }) async {
    final response = await apiClient.request('PUT', path, query: query, body: body) as T;

    // Invalidate related caches
    _invalidateCaches(cacheInvalidationPatterns);

    return response;
  }

  /// Make a DELETE request (not cached, but can invalidate related caches)
  Future<T> delete<T>(
    String path, {
    Map<String, String>? query,
    List<String>? cacheInvalidationPatterns,
  }) async {
    final response = await apiClient.request('DELETE', path, query: query) as T;

    // Invalidate related caches
    _invalidateCaches(cacheInvalidationPatterns);

    return response;
  }

  /// Invalidate caches matching patterns
  void _invalidateCaches(List<String>? patterns) {
    if (patterns == null || patterns.isEmpty) return;

    for (final pattern in patterns) {
      cacheManager.removeByPattern(pattern);
    }
  }

  /// Make a raw request (without any special handling)
  Future<dynamic> request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    return apiClient.request(method, path, query: query, body: body);
  }

  /// Clear all cache
  void clearCache() {
    cacheManager.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalKeys': cacheManager.getAllKeys().length,
      'totalSize': cacheManager.getCacheSize(),
      'cacheEnabled': enableCache,
      'defaultTtl': defaultCacheTtl,
    };
  }

  void close() => apiClient.close();
}
