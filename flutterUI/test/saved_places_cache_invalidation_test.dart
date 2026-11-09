import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_travelling/services/cache/cache_manager.dart';

void main() {
  test('saved place invalidation matches API paths and query variants', () {
    final cache = CacheManager()
      ..set('GET:/api/saved-places?limit=50&offset=0', 'default list')
      ..set('GET:/api/saved-places?limit=10&offset=20', 'other page')
      ..set('GET:/api/saved-places/place-123', 'place details')
      ..set('GET:/api/places', 'unrelated');

    cache.removeByPattern('^GET:/api/saved-places');

    expect(cache.get('GET:/api/saved-places?limit=50&offset=0'), isNull);
    expect(cache.get('GET:/api/saved-places?limit=10&offset=20'), isNull);
    expect(cache.get('GET:/api/saved-places/place-123'), isNull);
    expect(cache.get('GET:/api/places'), isNotNull);
  });
}
