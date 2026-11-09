import 'base_repository.dart';

/// Places Repository with caching
class PlacesRepository extends BaseRepository {
  PlacesRepository({required super.proxy});

  /// Get nearby places (cached for 15 minutes - places don't move!)
  /// Optimized for limited resources: minimal API calls since location data is stable
  Future<dynamic> getNearbyPlaces({
    required double lat,
    required double lng,
    int radius = 5000,
    bool forceRefresh = false,
  }) async {
    return proxy.getWithCache(
      '/api/places/nearby',
      query: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radius.toString(),
      },
      forceRefresh: forceRefresh,
      cacheTtl: 900, // 15 minutes - very stable data, fewer API calls
    );
  }
}
