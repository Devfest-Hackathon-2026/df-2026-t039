import 'api_proxy.dart';

/// Base repository class for common API patterns
abstract class BaseRepository {
  BaseRepository({required this.proxy});

  final ApiProxy proxy;
}

/// Trip Repository with caching
class TripRepository extends BaseRepository {
  TripRepository({required super.proxy});

  /// Get all trips with caching (default 5 minutes)
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
      cacheTtl: 300, // 5 minutes
    );
  }

  /// Get upcoming trip (cached for 2 minutes)
  Future<dynamic> getUpcomingTrip({bool forceRefresh = false}) async {
    return proxy.getWithCache(
      '/api/trips/upcoming',
      forceRefresh: forceRefresh,
      cacheTtl: 120,
    );
  }

  /// Get single trip detail (cached for 5 minutes)
  Future<dynamic> getTrip(String tripId, {bool forceRefresh = false}) async {
    return proxy.getWithCache(
      '/api/trips/$tripId',
      forceRefresh: forceRefresh,
      cacheTtl: 300,
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

/// Places Repository with caching
class PlacesRepository extends BaseRepository {
  PlacesRepository({required super.proxy});

  /// Get nearby places (cached for 10 minutes - doesn't change frequently)
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
      },
      forceRefresh: forceRefresh,
      cacheTtl: 600, // 10 minutes
    );
  }
}

/// Saved Places Repository with caching
class SavedPlacesRepository extends BaseRepository {
  SavedPlacesRepository({required super.proxy});

  /// Get saved places (cached for 5 minutes)
  Future<dynamic> listSavedPlaces({
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    return proxy.getWithCache(
      '/api/saved-places',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
      forceRefresh: forceRefresh,
      cacheTtl: 300,
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

/// Messages Repository (typically not cached or short TTL)
class MessagesRepository extends BaseRepository {
  MessagesRepository({required super.proxy});

  /// Get messages (cached for 2 minutes)
  Future<dynamic> listMessages({
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    return proxy.getWithCache(
      '/api/messages',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
      forceRefresh: forceRefresh,
      cacheTtl: 120, // 2 minutes
    );
  }

  /// Send a message and invalidate cache
  Future<dynamic> sendMessage(Map<String, dynamic> messageData) async {
    return proxy.post(
      '/api/messages',
      body: messageData,
      cacheInvalidationPatterns: ['^GET:/api/messages'],
    );
  }
}
