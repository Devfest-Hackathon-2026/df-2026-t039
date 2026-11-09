/// # API Caching System Documentation
/// 
/// This system provides transparent caching of API responses to reduce backend costs
/// while maintaining data freshness through intelligent cache invalidation.
///
/// ## Architecture Overview
///
/// ```
/// ┌─────────────────┐
/// │  Flutter App    │
/// │   (UI/Pages)    │
/// └────────┬────────┘
///          │ uses
///          ▼
/// ┌─────────────────┐
/// │ Repositories    │  ← Domain-specific API methods
/// │ (Trips, Places) │
/// └────────┬────────┘
///          │ uses
///          ▼
/// ┌─────────────────┐
/// │  ApiProxy       │  ← Caching & Cache Invalidation
/// └────────┬────────┘
///          │
///   ┌──────┴──────┐
///   │ uses        │ uses
///   ▼             ▼
/// Cache       ApiClient
/// Manager     (HTTP)
/// └──────────────────────┘
///        │ queries
///        ▼
///    Backend API
/// ```
///
/// ## Setup Instructions
///
/// ### 1. Initialize in main.dart
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'services/service_locator.dart';
///
/// void main() {
///   // Initialize the caching system
///   ServiceLocator.initialize(
///     baseUrl: 'https://api.example.com',
///     enableCache: true,
///     defaultCacheTtl: 300, // 5 minutes
///   );
///
///   runApp(const MyApp());
/// }
///
/// @override
/// void dispose() {
///   ServiceLocator.dispose();
///   super.dispose();
/// }
/// ```
///
/// ## Usage Patterns
///
/// ### Pattern 1: Read Trips (Cached)
///
/// ```dart
/// import 'services/service_locator.dart';
///
/// class TripsPage extends StatefulWidget {
///   @override
///   State<TripsPage> createState() => _TripsPageState();
/// }
///
/// class _TripsPageState extends State<TripsPage> {
///   late Future<dynamic> _tripsFuture;
///
///   @override
///   void initState() {
///     super.initState();
///     // This will hit cache if available (within 5 minutes)
///     _tripsFuture = ServiceLocator.tripRepository.listTrips();
///   }
///
///   void _refreshTrips() {
///     setState(() {
///       // forceRefresh=true bypasses cache and fetches from backend
///       _tripsFuture = ServiceLocator.tripRepository.listTrips(forceRefresh: true);
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return FutureBuilder(
///       future: _tripsFuture,
///       builder: (context, snapshot) {
///         if (snapshot.connectionState == ConnectionState.waiting) {
///           return const Center(child: CircularProgressIndicator());
///         }
///
///         if (snapshot.hasError) {
///           return Center(child: Text('Error: ${snapshot.error}'));
///         }
///
///         final trips = snapshot.data?['trips'] ?? [];
///         return ListView(
///           children: trips.map((trip) => TripCard(trip: trip)).toList(),
///         );
///       },
///     );
///   }
/// }
/// ```
///
/// ### Pattern 2: Create Trip (Invalidates Cache)
///
/// ```dart
/// Future<void> _createTrip(Map<String, dynamic> tripData) async {
///   try {
///     final result = await ServiceLocator.tripRepository.createTrip(tripData);
///     
///     // Cache is automatically invalidated:
///     // - trips list cache cleared
///     // - upcoming trip cache cleared
///
///     if (mounted) {
///       // Refresh the UI with new data from cache/backend
///       setState(() {
///         _tripsFuture = ServiceLocator.tripRepository.listTrips(forceRefresh: true);
///       });
///
///       ScaffoldMessenger.of(context).showSnackBar(
///         const SnackBar(content: Text('Trip created successfully!')),
///       );
///       Navigator.pop(context);
///     }
///   } on ApiException catch (e) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Error: ${e.message}')),
///     );
///   }
/// }
/// ```
///
/// ### Pattern 3: Update Trip (Partial Invalidation)
///
/// ```dart
/// Future<void> _updateTrip(String tripId, Map<String, dynamic> updates) async {
///   try {
///     await ServiceLocator.tripRepository.updateTrip(tripId, updates);
///
///     // Automatically invalidates:
///     // - trips list cache
///     // - trip detail cache for this specific trip
///     // - upcoming trip cache
///
///     if (mounted) {
///       setState(() {
///         _tripDetailFuture = ServiceLocator.tripRepository.getTrip(tripId, forceRefresh: true);
///       });
///     }
///   } on ApiException catch (e) {
///     print('Error updating trip: ${e.message}');
///   }
/// }
/// ```
///
/// ### Pattern 4: Delete Trip (Full Invalidation)
///
/// ```dart
/// Future<void> _deleteTrip(String tripId) async {
///   try {
///     await ServiceLocator.tripRepository.deleteTrip(tripId);
///
///     // Automatically invalidates all trip-related caches
///
///     if (mounted) {
///       setState(() {
///         _tripsFuture = ServiceLocator.tripRepository.listTrips(forceRefresh: true);
///       });
///     }
///   } on ApiException catch (e) {
///     print('Error deleting trip: ${e.message}');
///   }
/// }
/// ```
///
/// ### Pattern 5: Multiple Concurrent Requests
///
/// ```dart
/// // Both requests will hit cache if available (reduces API calls)
/// Future<void> _loadDashboard() async {
///   final results = await Future.wait([
///     ServiceLocator.tripRepository.getUpcomingTrip(),
///     ServiceLocator.savedPlacesRepository.listSavedPlaces(),
///   ]);
///
///   // Handle results[0] and results[1]
/// }
/// ```
///
/// ## Cache Configuration
///
/// ### Default TTLs (Time-To-Live)
/// - Trips list: 5 minutes (300s) - changes frequently
/// - Trip detail: 5 minutes (300s)
/// - Upcoming trip: 2 minutes (120s) - very dynamic
/// - Nearby places: 10 minutes (600s) - static data
/// - Saved places: 5 minutes (300s)
/// - Messages: 2 minutes (120s) - frequently updated
///
/// ### Custom TTLs
///
/// You can override default TTLs in repositories:
///
/// ```dart
/// // In repositories.dart, modify specific method:
/// Future<dynamic> listTrips({
///   // ... existing params ...
///   cacheTtl: 600, // Change to 10 minutes instead of 5
/// }) async {
///   // ...
/// }
/// ```
///
/// ## Debugging & Monitoring
///
/// ### View Cache Statistics
///
/// ```dart
/// final stats = ServiceLocator.getCacheStats();
/// print('Cache Stats: $stats');
/// // Output: {totalKeys: 5, totalSize: 2048, cacheEnabled: true, defaultTtl: 300}
/// ```
///
/// ### Enable Debug Logging
///
/// The system automatically logs in DEBUG mode:
/// ```
/// 🔄 Cache HIT: GET:/trips?limit=20&offset=0
/// 📡 Cache MISS: Fetching /trips
/// 📤 POST: /trips
/// 🗑️ Invalidated cache pattern: ^GET:/trips
/// ```
///
/// ### Manual Cache Cleanup
///
/// ```dart
/// // Clear all caches
/// ServiceLocator.clearAllCaches();
///
/// // Clear specific pattern
/// ServiceLocator.cacheManager.removeByPattern('^GET:/trips');
///
/// // Remove single key
/// ServiceLocator.cacheManager.remove('GET:/trips?limit=20&offset=0');
/// ```
///
/// ## Cost Optimization
///
/// ### Before Caching
/// - User opens app
/// - Load trips: 1 API call
/// - Load saved places: 1 API call
/// - Switch pages and come back: 1 API call (DUPLICATE)
/// - **Total: 3 API calls per session**
///
/// ### After Caching
/// - User opens app
/// - Load trips: 1 API call (cached for 5 min)
/// - Load saved places: 1 API call (cached for 5 min)
/// - Switch pages and come back: 0 API calls (from cache)
/// - **Total: 2 API calls per session**
/// - **Reduction: 33%** (scales with user behavior)
///
/// ### Further Optimization Tips
///
/// 1. **Increase TTLs for static data**
///   - Nearby places: 30 minutes (static location data)
///
/// 2. **Lazy loading**
///   - Load only visible content first
///   - Load related data on demand
///
/// 3. **Batch operations**
///   - Combine multiple small requests into one
///   - Reduce trip creation confirmations before request
///
/// 4. **Conditional updates**
///   - Only refresh when data is confirmed changed
///   - Use websockets for real-time updates (future)
///
/// ## Advanced Features
///
/// ### Permanent Cache (No Expiration)
///
/// ```dart
/// // Store user preferences indefinitely
/// ServiceLocator.cacheManager.setPermanent('user:preferences', preferences);
///
/// // Retrieved the same way
/// final prefs = ServiceLocator.cacheManager.get('user:preferences');
/// ```
///
/// ### Cache Info
///
/// ```dart
/// final info = ServiceLocator.cacheManager.getCacheInfo('GET:/trips');
/// // {
/// //   'exists': true,
/// //   'isValid': true,
/// //   'remainingTtl': 245,
/// //   'createdAt': '2024-11-08T20:30:00.000Z',
/// //   'dataType': 'Map<String, dynamic>'
/// // }
/// ```
///
/// ### Manual Cleanup (for long-running apps)
///
/// ```dart
/// // Periodically call this to remove expired entries
/// ServiceLocator.cacheManager.cleanup();
/// ```
///
/// ## Migration Path
///
/// If you have existing code using ApiClient directly:
///
/// ### Before (Direct API calls)
/// ```dart
/// final trips = await apiClient.request('GET', '/trips');
/// ```
///
/// ### After (Using repositories)
/// ```dart
/// final trips = await ServiceLocator.tripRepository.listTrips();
/// ```
///
/// The transition is simple: just replace direct ApiClient calls with repository methods.
///
/// ## Troubleshooting
///
/// ### Cache never expires
/// Check if TTL is set to -1 (permanent). Use `cacheManager.cleanup()` to remove expired entries.
///
/// ### Stale data showing up
/// Increase TTL is too long. Consider reducing or using `forceRefresh: true`.
///
/// ### Cache invalidation not working
/// Check pattern regex in `cacheInvalidationPatterns`. Patterns use regex, not wildcards.
/// - Wrong: `'*GET:/trips*'`
/// - Right: `'^GET:/trips'`
///
/// ### Memory usage growing
/// Call `ServiceLocator.cacheManager.cleanup()` periodically.
/// Check cache size with `ServiceLocator.getCacheStats()`.
