import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'cache/api_proxy.dart';
import 'cache/cache_manager.dart';
import 'repositories/repositories.dart';

/// Service locator for managing dependencies
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  late ApiClient _apiClient;
  late CacheManager _cacheManager;
  late ApiProxy _proxy;
  late TripRepository _tripRepository;
  late PlacesRepository _placesRepository;
  late SavedPlacesRepository _savedPlacesRepository;
  late MessagesRepository _messagesRepository;

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  /// Initialize services (call this in main.dart)
  static void initialize({
    String baseUrl = const String.fromEnvironment('API_BASE_URL'),
    bool enableCache = true,
    int defaultCacheTtl = CacheManager.defaultTtl,
  }) {
    _instance
      .._apiClient = ApiClient(baseUrl: baseUrl, client: http.Client())
      .._cacheManager = CacheManager()
      .._proxy = ApiProxy(
        apiClient: _instance._apiClient,
        cacheManager: _instance._cacheManager,
        enableCache: enableCache,
        defaultCacheTtl: defaultCacheTtl,
      )
      .._tripRepository = TripRepository(proxy: _instance._proxy)
      .._placesRepository = PlacesRepository(proxy: _instance._proxy)
      .._savedPlacesRepository = SavedPlacesRepository(proxy: _instance._proxy)
      .._messagesRepository = MessagesRepository(proxy: _instance._proxy);
  }

  /// Get API client
  static ApiClient get apiClient => _instance._apiClient;

  /// Get cache manager
  static CacheManager get cacheManager => _instance._cacheManager;

  /// Get API proxy
  static ApiProxy get proxy => _instance._proxy;

  /// Get repositories
  static TripRepository get tripRepository => _instance._tripRepository;
  static PlacesRepository get placesRepository => _instance._placesRepository;
  static SavedPlacesRepository get savedPlacesRepository => _instance._savedPlacesRepository;
  static MessagesRepository get messagesRepository => _instance._messagesRepository;

  /// Cleanup resources
  static void dispose() {
    _instance._apiClient.close();
    _instance._cacheManager.clear();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return _instance._proxy.getCacheStats();
  }

  /// Clear all caches
  static void clearAllCaches() {
    _instance._proxy.clearCache();
  }
}
