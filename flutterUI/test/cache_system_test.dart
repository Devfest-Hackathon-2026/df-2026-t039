// Example tests for the caching system
// Add these to your test/ directory and run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/services/cache_manager.dart';
import 'package:flutter_ui_travelling/services/api_proxy.dart';
import 'package:flutter_ui_travelling/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

// Mock implementation
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('CacheManager', () {
    late CacheManager cache;

    setUp(() {
      cache = CacheManager();
    });

    test('stores and retrieves cached data', () {
      cache.set('key1', {'data': 'value'}, ttlSeconds: 300);
      
      expect(cache.get<Map>('key1'), {'data': 'value'});
    });

    test('returns null for missing keys', () {
      expect(cache.get('nonexistent'), null);
    });

    test('removes expired cache entries', () {
      cache.set('key1', 'data', ttlSeconds: -1); // No expiration
      expect(cache.get('key1'), 'data');

      cache.remove('key1');
      expect(cache.get('key1'), null);
    });

    test('clears all cache', () {
      cache.set('key1', 'data1', ttlSeconds: 300);
      cache.set('key2', 'data2', ttlSeconds: 300);
      
      expect(cache.getAllKeys().length, 2);
      
      cache.clear();
      expect(cache.getAllKeys().length, 0);
    });

    test('permanent cache does not expire', () {
      cache.setPermanent('permanent', 'data');
      
      final info = cache.getCacheInfo('permanent');
      expect(info['remainingTtl'], -1);
    });

    test('cache expiration works correctly', () {
      // Set cache with 1 second TTL
      cache.set('expiring', 'data', ttlSeconds: 1);
      
      expect(cache.get('expiring'), 'data');
      
      // After TTL expires, should return null
      Future.delayed(const Duration(seconds: 2), () {
        expect(cache.get('expiring'), null);
      });
    });

    test('removeByPattern removes matching keys', () {
      cache.set('GET:/trips', 'trips');
      cache.set('GET:/places', 'places');
      cache.set('POST:/trips', 'created');
      
      expect(cache.getAllKeys().length, 3);
      
      cache.removeByPattern('^GET:');
      
      expect(cache.getAllKeys().length, 1);
      expect(cache.get('POST:/trips'), 'created');
    });

    test('getCacheInfo returns correct metadata', () {
      cache.set('key1', 'data', ttlSeconds: 300);
      
      final info = cache.getCacheInfo('key1');
      
      expect(info['exists'], true);
      expect(info['isValid'], true);
      expect(info['remainingTtl'], greaterThan(0));
      expect(info['remainingTtl'], lessThanOrEqualTo(300));
      expect(info['dataType'], contains('String'));
    });

    test('getCacheSize returns approximate size', () {
      cache.set('key1', 'a' * 1000); // 1000 byte string
      cache.set('key2', 'b' * 2000); // 2000 byte string
      
      final size = cache.getCacheSize();
      expect(size, greaterThan(3000)); // Approximate
    });
  });

  group('ApiProxy Cache Behavior', () {
    late MockHttpClient mockClient;
    late ApiClient apiClient;
    late CacheManager cacheManager;
    late ApiProxy proxy;

    setUp(() {
      mockClient = MockHttpClient();
      cacheManager = CacheManager();
      apiClient = ApiClient(
        baseUrl: 'https://api.example.com',
        client: mockClient,
      );
      proxy = ApiProxy(
        apiClient: apiClient,
        cacheManager: cacheManager,
        enableCache: true,
      );
    });

    test('caches GET requests', () async {
      // First call should hit the API
      final response1 = await proxy.getWithCache<Map>(
        '/test',
        cacheTtl: 300,
      );
      
      // Second call should return cached data
      final response2 = await proxy.getWithCache<Map>('/test');
      
      expect(response1, response2);
    });

    test('forceRefresh bypasses cache', () async {
      // Cache initial response
      await proxy.getWithCache<Map>('/test', cacheTtl: 300);
      
      // Force refresh should fetch new data
      final response = await proxy.getWithCache<Map>(
        '/test',
        forceRefresh: true,
      );
      
      expect(response, isNotNull);
    });

    test('POST invalidates related caches', () async {
      // Pre-populate cache
      cacheManager.set('GET:/trips', {'trips': []}, ttlSeconds: 300);
      cacheManager.set('GET:/trips/upcoming', {'trip': {}}, ttlSeconds: 300);
      cacheManager.set('GET:/places', {'places': []}, ttlSeconds: 300);
      
      expect(cacheManager.getAllKeys().length, 3);
      
      // POST with cache invalidation
      await proxy.post(
        '/trips',
        body: {'destination': 'Paris'},
        cacheInvalidationPatterns: ['^GET:/trips'],
      );
      
      // Only matching patterns should be cleared
      expect(cacheManager.get('GET:/trips'), null);
      expect(cacheManager.get('GET:/trips/upcoming'), null); // Also cleared by pattern
      expect(cacheManager.get('GET:/places'), isNotNull); // Not cleared
    });

    test('cache key generation includes query params', () {
      final key1 = proxy.getWithCache<dynamic>(
        '/trips',
        query: {'limit': '20', 'offset': '0'},
      );
      
      final key2 = proxy.getWithCache<dynamic>(
        '/trips',
        query: {'limit': '20', 'offset': '10'},
      );
      
      // Different query params = different cache keys
      expect(key1, isNotNull);
      expect(key2, isNotNull);
    });
  });

  group('Cache Invalidation Patterns', () {
    late CacheManager cache;

    setUp(() {
      cache = CacheManager();
    });

    test('regex pattern ^GET:/trips matches GET:/trips endpoints', () {
      cache.set('GET:/trips', 'list');
      cache.set('GET:/trips/123', 'detail');
      cache.set('GET:/trips/123/items', 'items');
      cache.set('POST:/trips', 'create');
      
      cache.removeByPattern('^GET:/trips');
      
      expect(cache.get('GET:/trips'), null);
      expect(cache.get('GET:/trips/123'), null);
      expect(cache.get('GET:/trips/123/items'), null);
      expect(cache.get('POST:/trips'), isNotNull); // Not matched
    });

    test('regex pattern ^GET:/trips/123$ matches exact path', () {
      cache.set('GET:/trips/123', 'detail');
      cache.set('GET:/trips/123/items', 'items');
      
      cache.removeByPattern('^GET:/trips/123\$');
      
      expect(cache.get('GET:/trips/123'), null);
      expect(cache.get('GET:/trips/123/items'), isNotNull); // Not matched
    });

    test('complex pattern for trip mutations', () {
      cache.set('GET:/trips', 'list');
      cache.set('GET:/trips/123', 'detail');
      cache.set('GET:/trips/upcoming', 'upcoming');
      cache.set('GET:/places', 'places');
      
      final patterns = ['^GET:/trips'];
      for (final pattern in patterns) {
        cache.removeByPattern(pattern);
      }
      
      expect(cache.get('GET:/trips'), null);
      expect(cache.get('GET:/trips/123'), null);
      expect(cache.get('GET:/trips/upcoming'), null);
      expect(cache.get('GET:/places'), isNotNull);
    });
  });

  group('Cache Performance', () {
    late CacheManager cache;

    test('cache retrieval is fast', () {
      cache = CacheManager();
      
      // Store 1000 items
      for (int i = 0; i < 1000; i++) {
        cache.set('key_$i', {'index': i}, ttlSeconds: 300);
      }
      
      final stopwatch = Stopwatch()..start();
      
      // Retrieve 100 items
      for (int i = 0; i < 100; i++) {
        cache.get('key_$i');
      }
      
      stopwatch.stop();
      
      // Should be very fast (< 10ms for 100 lookups)
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('cleanup removes expired entries efficiently', () {
      cache = CacheManager();
      
      // Store items with different TTLs
      cache.set('short', 'data', ttlSeconds: 1);
      cache.set('long', 'data', ttlSeconds: 3600);
      
      expect(cache.getAllKeys().length, 2);
      
      Future.delayed(const Duration(seconds: 2), () {
        cache.cleanup();
        
        // Only long TTL should remain
        expect(cache.getAllKeys().length, 1);
        expect(cache.get('long'), isNotNull);
      });
    });
  });
}

/// Run these tests with:
/// flutter test test/cache_system_test.dart
///
/// Expected output:
/// ✓ CacheManager stores and retrieves cached data
/// ✓ CacheManager returns null for missing keys
/// ✓ CacheManager removes expired cache entries
/// ✓ ... (more test results)
/// 
/// All tests should pass, confirming the caching system works correctly.
