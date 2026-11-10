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
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'radius': radius.toString(),
        'limit': '10',
        'rank': 'DISTANCE',
      },
      forceRefresh: forceRefresh,
      cacheTtl: 900, // 15 minutes - very stable data, fewer API calls
    );
  }

  /// Get nearby places (cached for 15 minutes - places don't move!)
  /// Optimized for limited resources: minimal API calls since location data is stable
  Future<dynamic> searchPlaces({
    String q = "",
    bool forceRefresh = false,
    String? pageToken,
  }) async {
    return proxy.getWithCache(
      '/api/places/search',
      query: {'q': q, 'limit': '8'},
      forceRefresh: forceRefresh,
      cacheTtl: 900, // 15 minutes - very stable data, fewer API calls
    );
  }

  Future<dynamic> createPlace({
    String? googlePlaceId,
    required String name,
    required String location,
    double? latitude,
    double? longitude,
  }) async {
    return proxy.post(
      '/api/places',
      body: {
        'google_place_id': ?googlePlaceId,
        'name': name,
        'location': location,
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
    );
  }
}
