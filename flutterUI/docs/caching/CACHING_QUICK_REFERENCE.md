# 🚀 Caching System - Quick Reference

## Installation ✅
Already done! Files are in:
- `lib/services/` - Core caching system
- `lib/main.dart` - Initialization code
- `lib/pages/EXAMPLE_CACHED_PAGES.dart` - Complete examples

## Basic Usage

### Get Cached Trips
```dart
final trips = await ServiceLocator.tripRepository.listTrips();
```

### Force Fresh Data
```dart
final trips = await ServiceLocator.tripRepository.listTrips(
  forceRefresh: true,
);
```

### Create Trip (Auto-Invalidates Cache)
```dart
await ServiceLocator.tripRepository.createTrip({
  'destination': 'Paris',
  'start_date': '2024-12-01',
  'end_date': '2024-12-10',
});
```

### Update Trip
```dart
await ServiceLocator.tripRepository.updateTrip(tripId, {
  'destination': 'Rome',
});
```

### Delete Trip
```dart
await ServiceLocator.tripRepository.deleteTrip(tripId);
```

### Get Saved Places
```dart
final places = await ServiceLocator.savedPlacesRepository.listSavedPlaces();
```

### Send Message
```dart
await ServiceLocator.messagesRepository.sendMessage({
  'content': 'Hello!',
  'tripId': tripId,
});
```

## Monitoring

### View Cache Stats
```dart
final stats = ServiceLocator.getCacheStats();
print('Total cached items: ${stats['totalKeys']}');
print('Cache size: ${stats['totalSize']} bytes');
```

### Clear All Cache
```dart
ServiceLocator.clearAllCaches();
```

### Clear Specific Pattern
```dart
// Remove all trips-related caches
ServiceLocator.cacheManager.removeByPattern('^GET:/trips');
```

### Get Cache Info
```dart
final info = ServiceLocator.cacheManager.getCacheInfo('GET:/trips');
if (info['isValid']) {
  print('Cache valid for ${info['remainingTtl']} more seconds');
}
```

## Configuration

### Change Default TTL
Edit `lib/services/repositories.dart`:
```dart
// In TripRepository.listTrips():
cacheTtl: 600,  // Change from 300 to 600 seconds
```

### Disable Cache
In `lib/main.dart`:
```dart
ServiceLocator.initialize(
  enableCache: false,  // Disable globally
);
```

## Complete Page Example

```dart
class TripsPage extends StatefulWidget {
  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  late Future<dynamic> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips({bool forceRefresh = false}) {
    setState(() {
      _tripsFuture = ServiceLocator.tripRepository.listTrips(
        forceRefresh: forceRefresh,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadTrips(forceRefresh: true);
          return await _tripsFuture;
        },
        child: FutureBuilder(
          future: _tripsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final trips = (snapshot.data?['trips'] as List?) ?? [];
            if (trips.isEmpty) {
              return const Center(child: Text('No trips'));
            }

            return ListView(
              children: trips
                  .map((trip) => ListTile(
                    title: Text(trip['destination']),
                    subtitle: Text('${trip['start_date']} - ${trip['end_date']}'),
                  ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
```

## Create Trip Example

```dart
Future<void> _createTrip(BuildContext context) async {
  try {
    await ServiceLocator.tripRepository.createTrip({
      'destination': _destination,
      'start_date': _startDate,
      'end_date': _endDate,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip created!')),
      );
      Navigator.pop(context);
    }
  } on ApiException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }
}
```

## Debug Output

When running in debug mode, you'll see cache operations:

```
🔄 Cache HIT: GET:/trips?limit=20&offset=0       ← Served from cache
📡 Cache MISS: Fetching /trips                     ← Fetched from backend
📤 POST: /trips                                    ← Creating new trip
🗑️ Invalidated cache pattern: ^GET:/trips        ← Cache cleared
```

## Available Repositories

### TripRepository
```dart
ServiceLocator.tripRepository.listTrips()
ServiceLocator.tripRepository.getUpcomingTrip()
ServiceLocator.tripRepository.getTrip(tripId)
ServiceLocator.tripRepository.createTrip(data)
ServiceLocator.tripRepository.updateTrip(tripId, data)
ServiceLocator.tripRepository.deleteTrip(tripId)
ServiceLocator.tripRepository.updateItinerary(tripId, items)
```

### PlacesRepository
```dart
ServiceLocator.placesRepository.getNearbyPlaces(lat, lng)
```

### SavedPlacesRepository
```dart
ServiceLocator.savedPlacesRepository.listSavedPlaces()
ServiceLocator.savedPlacesRepository.createSavedPlace(data)
ServiceLocator.savedPlacesRepository.updateSavedPlace(id, data)
ServiceLocator.savedPlacesRepository.deleteSavedPlace(id)
```

### MessagesRepository
```dart
ServiceLocator.messagesRepository.listMessages()
ServiceLocator.messagesRepository.sendMessage(data)
```

## Cache TTLs

```dart
Trips list     → 5 minutes (300s)
Trip detail    → 5 minutes (300s)
Upcoming trip  → 2 minutes (120s)
Nearby places  → 10 minutes (600s)
Saved places   → 5 minutes (300s)
Messages       → 2 minutes (120s)
```

## Testing

Run tests:
```bash
flutter test test/cache_system_test.dart
```

Expected output:
```
✓ CacheManager stores and retrieves cached data
✓ CacheManager returns null for missing keys
✓ ApiProxy caches GET requests
✓ POST invalidates related caches
... (more tests)

All tests passed!
```

## Common Patterns

### Pattern 1: List with Refresh
See `EXAMPLE_CACHED_PAGES.dart` → `MyTripsPageWithCache`

### Pattern 2: Create with Invalidation
See `EXAMPLE_CACHED_PAGES.dart` → `CreateTripExample`

### Pattern 3: Parallel Requests
```dart
final [trips, places, messages] = await Future.wait([
  ServiceLocator.tripRepository.listTrips(),
  ServiceLocator.savedPlacesRepository.listSavedPlaces(),
  ServiceLocator.messagesRepository.listMessages(),
]);
```

## Troubleshooting

**Stale data showing?**
```dart
// Use forceRefresh
await ServiceLocator.tripRepository.listTrips(forceRefresh: true);
```

**Cache not invalidating on create/update?**
```dart
// Manually clear
ServiceLocator.clearAllCaches();
```

**Check if cache is working?**
```dart
// Look at debug output or check stats
final stats = ServiceLocator.getCacheStats();
print(stats);
```

**Disable cache for debugging?**
In `main.dart`:
```dart
ServiceLocator.initialize(enableCache: false);
```

## Performance

- Cache hit: ~1ms ⚡
- Cache miss: ~50-200ms (HTTP)
- Expected cost reduction: 30-40% 💰

## Files Reference

| File | Purpose |
|------|---------|
| `cache_manager.dart` | TTL caching engine |
| `api_proxy.dart` | HTTP proxy + invalidation |
| `repositories.dart` | API methods (TripRepository, etc) |
| `service_locator.dart` | Dependency injection |
| `README_CACHING.md` | Full documentation |
| `CACHING_GUIDE.dart` | Detailed guide + advanced patterns |
| `EXAMPLE_CACHED_PAGES.dart` | Copy-paste implementations |

## Next Steps

1. Read `README_CACHING.md`
2. Review `EXAMPLE_CACHED_PAGES.dart`
3. Update your pages with cached repositories
4. Run app and check debug logs for cache hits
5. Monitor savings with `getCacheStats()`

---

**Ready to implement!** 🚀
