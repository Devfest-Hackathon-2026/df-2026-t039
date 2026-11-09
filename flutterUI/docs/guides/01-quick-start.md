# Quick Start Guide - API Caching System

Get the caching system running in 5 minutes! ⚡

## ✅ Already Installed

The caching system has been installed and initialized. No additional setup needed!

### What You Have

```
lib/services/
├── cache/
│   ├── cache_manager.dart       ← Cache storage & TTL
│   ├── api_proxy.dart           ← HTTP proxy + caching
│   └── cache.dart               ← Barrel export
├── repositories/
│   ├── base_repository.dart     ← Base class
│   ├── trip_repository.dart     ← Trip API methods
│   ├── places_repository.dart   ← Places API methods
│   ├── saved_places_repository.dart
│   ├── messages_repository.dart
│   └── repositories.dart        ← Barrel export
├── api_client.dart              ← HTTP client
├── service_locator.dart         ← Dependency injection
└── services.dart                ← Main barrel export

lib/main.dart                    ← Already initialized
```

## 🚀 Basic Usage (3 Steps)

### Step 1: Import ServiceLocator

```dart
import 'package:flutter_ui_travelling/services/services.dart';
```

### Step 2: Use Repository Methods

Replace direct API calls with repositories:

```dart
// Get trips (automatically cached for 5 minutes)
final trips = await ServiceLocator.tripRepository.listTrips();

// Get specific trip detail (cached for 5 minutes)
final trip = await ServiceLocator.tripRepository.getTrip(tripId);

// Get upcoming trip (cached for 2 minutes)
final upcoming = await ServiceLocator.tripRepository.getUpcomingTrip();
```

### Step 3: Handle Create/Update/Delete

Mutations automatically invalidate related caches:

```dart
// Create trip (invalidates trips list cache)
await ServiceLocator.tripRepository.createTrip({
  'destination': 'Paris',
  'start_date': '2024-12-01',
});

// Update trip (invalidates trip list and detail cache)
await ServiceLocator.tripRepository.updateTrip(tripId, {
  'destination': 'Rome',
});

// Delete trip (invalidates all trip caches)
await ServiceLocator.tripRepository.deleteTrip(tripId);
```

## 📊 Observe Cache Behavior

Run your app and watch the debug console:

```
🔄 Cache HIT: GET:/trips?limit=20&offset=0       ← From cache
📡 Cache MISS: Fetching /trips                    ← From backend
📤 POST: /trips                                   ← Creating
🗑️ Invalidated cache pattern: ^GET:/trips       ← Clearing cache
```

## 💡 Real-World Example

### List Trips Page

```dart
import 'package:flutter/material.dart';
import 'package:flutter_ui_travelling/services/services.dart';

class TripsPage extends StatefulWidget {
  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  late Future<dynamic> _tripsFuture;

  @override
  void initState() {
    super.initState();
    // This will hit cache if within 5 minutes
    _tripsFuture = ServiceLocator.tripRepository.listTrips();
  }

  void _refreshTrips() {
    setState(() {
      // Force refresh from backend, bypasses cache
      _tripsFuture = ServiceLocator.tripRepository.listTrips(
        forceRefresh: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshTrips();
          await _tripsFuture;
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
              return const Center(child: Text('No trips yet'));
            }

            return ListView(
              children: trips
                  .map((trip) => ListTile(
                    title: Text(trip['destination']),
                    subtitle: Text('${trip['start_date']} - ${trip['end_date']}'),
                    onTap: () {
                      // Navigate to trip detail
                    },
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

### Create Trip Page

```dart
class CreateTripPage extends StatefulWidget {
  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  late TextEditingController _destinationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);

    try {
      // Create trip (cache automatically invalidated)
      await ServiceLocator.tripRepository.createTrip({
        'destination': _destinationController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Trip created!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trip')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'Destination'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🎯 Available Repositories

### TripRepository
```dart
ServiceLocator.tripRepository.listTrips()          // GET /trips
ServiceLocator.tripRepository.getTrip(id)         // GET /trips/:id
ServiceLocator.tripRepository.getUpcomingTrip()   // GET /trips/upcoming
ServiceLocator.tripRepository.createTrip(data)    // POST /trips
ServiceLocator.tripRepository.updateTrip(id, data)// PATCH /trips/:id
ServiceLocator.tripRepository.deleteTrip(id)      // DELETE /trips/:id
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

## 🔧 Configuration

### Change Default Cache Duration

Edit `lib/services/repositories/trip_repository.dart`:

```dart
// Change from 300 to 600 seconds (10 minutes)
Future<dynamic> listTrips({...}) async {
  return proxy.getWithCache(
    '/trips',
    query: {...},
    cacheTtl: 600,  // Changed
  );
}
```

### Disable Caching

In `lib/main.dart`:

```dart
ServiceLocator.initialize(
  enableCache: false,  // Disable globally
);
```

## 📊 Monitor Cache

```dart
// View cache stats
final stats = ServiceLocator.getCacheStats();
print(stats);
// Output: {totalKeys: 5, totalSize: 2048, cacheEnabled: true, ...}

// Clear all cache
ServiceLocator.clearAllCaches();

// Force refresh (bypass cache)
await ServiceLocator.tripRepository.listTrips(forceRefresh: true);
```

## 🎉 You're Ready!

The system is installed, configured, and ready to use. Start replacing your API calls with repository methods and watch your API costs drop!

**Next Steps:**
1. ✅ Review example pages (see [Complete Page Examples](./01-page-examples.md))
2. Update your pages with caching
3. Run the app and observe cache hits
4. Monitor savings with `getCacheStats()`

---

**Need more details?** → [Basic Usage Guide](./03-basic-usage.md)
