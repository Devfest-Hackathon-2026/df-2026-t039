import 'base_repository.dart';

/// Trip Repository with caching
class TripRepository extends BaseRepository {
  TripRepository({required super.proxy});

  /// Get all trips with caching (10 minutes - trips don't change rapidly)
  Future<dynamic> listTrips({
    int limit = 20,
    int offset = 0,
    String? status,
    bool forceRefresh = false,
  }) async {
    return proxy.getWithCache(
      '/api/trips',
      query: {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (status != null) 'status': status,
      },
      forceRefresh: forceRefresh,
      cacheTtl: 600, // 10 minutes - efficient for limited resources
    );
  }

  /// Get upcoming trip (cached for 5 minutes - checked more frequently)
  Future<dynamic> getUpcomingTrip({bool forceRefresh = false}) async {
    return proxy.getWithCache(
      '/api/trips/upcoming',
      forceRefresh: forceRefresh,
      cacheTtl: 300, // 5 minutes - higher priority data
    );
  }

  /// Get single trip detail (cached for 10 minutes - stable data)
  Future<dynamic> getTrip(String tripId, {bool forceRefresh = false}) async {
    return proxy.getWithCache(
      '/api/trips/$tripId',
      forceRefresh: forceRefresh,
      cacheTtl: 600, // 10 minutes - details don't change often
    );
  }

  /// Create a new trip and invalidate related caches
  Future<dynamic> createTrip(Map<String, dynamic> tripData) async {
    return proxy.post(
      '/api/trips',
      body: tripData,
      cacheInvalidationPatterns: [
        '^GET:/api/trips', // Invalidate all trips list caches
        '^GET:/api/trips/upcoming',
      ],
    );
  }

  /// Update a trip and invalidate related caches
  Future<dynamic> updateTrip(
    String tripId,
    Map<String, dynamic> tripData,
  ) async {
    return proxy.patch(
      '/api/trips/$tripId',
      body: tripData,
      cacheInvalidationPatterns: [
        '^GET:/api/trips', // Invalidate trips list
        '^GET:/api/trips/$tripId', // Invalidate specific trip detail
        '^GET:/api/trips/upcoming', // Invalidate upcoming trip
      ],
    );
  }

  /// Delete a trip and invalidate related caches
  Future<dynamic> deleteTrip(String tripId) async {
    return proxy.delete(
      '/api/trips/$tripId',
      cacheInvalidationPatterns: [
        '^GET:/api/trips', // Invalidate trips list
        '^GET:/api/trips/$tripId', // Invalidate specific trip detail
        '^GET:/api/trips/upcoming', // Invalidate upcoming trip
      ],
    );
  }

  /// Update trip itinerary and invalidate related caches
  Future<dynamic> updateItinerary(
    String tripId,
    List<dynamic> itinerary,
  ) async {
    return proxy.put(
      '/api/trips/$tripId/itinerary',
      body: {'itinerary': itinerary},
      cacheInvalidationPatterns: [
        '^GET:/api/trips/$tripId', // Invalidate specific trip detail
      ],
    );
  }
}
