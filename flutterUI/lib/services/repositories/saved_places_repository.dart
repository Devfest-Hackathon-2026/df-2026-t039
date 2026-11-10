import 'base_repository.dart';

/// Saved Places Repository with caching
class SavedPlacesRepository extends BaseRepository {
  SavedPlacesRepository({required super.proxy});

  /// Get saved places (cached for 15 minutes - very stable user data)
  /// Only changes when user explicitly modifies - perfect for long caching
  Future<dynamic> listSavedPlaces({
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    return proxy.getWithCache(
      '/api/saved-places',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
      forceRefresh: forceRefresh,
      cacheTtl: 900, // 15 minutes - user data rarely changes without action
    );
  }

  /// Create a saved place and invalidate list cache
  Future<dynamic> createSavedPlace(Map<String, dynamic> placeData) async {
    return proxy.post(
      '/api/saved-places',
      body: placeData,
      cacheInvalidationPatterns: ['^GET:/api/saved-places'],
    );
  }

  /// Update a saved place
  Future<dynamic> updateSavedPlace(
    String placeId,
    Map<String, dynamic> placeData,
  ) async {
    return proxy.patch(
      '/api/saved-places/$placeId',
      body: placeData,
      cacheInvalidationPatterns: ['^GET:/api/saved-places'],
    );
  }

  /// Delete a saved place
  Future<dynamic> deleteSavedPlace(String placeId) async {
    return proxy.delete(
      '/api/saved-places/$placeId',
      cacheInvalidationPatterns: ['^GET:/api/saved-places'],
    );
  }
}
