/// Example implementation of how to use the caching system in your pages
/// This shows best practices for integrating cached API calls into your UI

import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../services/api_client.dart';
import '../widgets/slide_route.dart';
import 'trip_details_page.dart';

class MyTripsPageWithCache extends StatefulWidget {
  const MyTripsPageWithCache({super.key});

  @override
  State<MyTripsPageWithCache> createState() => _MyTripsPageWithCacheState();
}

class _MyTripsPageWithCacheState extends State<MyTripsPageWithCache> {
  late Future<dynamic> _tripsFuture;
  bool _isRefreshing = false;

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

  void _refreshTrips() async {
    setState(() => _isRefreshing = true);
    try {
      await _tripsFuture;
      _loadTrips(forceRefresh: true);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          // Show cache stats in debug mode
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              final stats = ServiceLocator.getCacheStats();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cache: ${stats['totalKeys']} keys, ${stats['totalSize']} bytes',
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshTrips();
          await _tripsFuture;
        },
        child: FutureBuilder<dynamic>(
          future: _tripsFuture,
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting &&
                !_isRefreshing) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _refreshTrips(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Extract trips from response
            final trips = (snapshot.data?['trips'] as List?)?.cast<dynamic>() ?? [];

            // Empty state
            if (trips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.backpack, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No trips yet'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to create trip page
                      },
                      child: const Text('Create a trip'),
                    ),
                  ],
                ),
              );
            }

            // Success state - list of trips
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _TripSection(
                  title: 'Your Trips',
                  trips: trips.cast<Map<String, dynamic>>(),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create trip
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TripSection extends StatelessWidget {
  const _TripSection({
    required this.title,
    required this.trips,
  });

  final String title;
  final List<Map<String, dynamic>> trips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...trips.map((trip) => _TripCard(trip: trip)),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Map<String, dynamic> trip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          trip['destination'] ?? 'Untitled Trip',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('From: ${trip['start_date'] ?? 'TBD'}'),
            Text('To: ${trip['end_date'] ?? 'TBD'}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            slideRoute(TripDetailsPage(trip: trip)),
          );
        },
      ),
    );
  }
}

/// Example: Create Trip with Cache Invalidation
class CreateTripExample extends StatefulWidget {
  const CreateTripExample({super.key});

  @override
  State<CreateTripExample> createState() => _CreateTripExampleState();
}

class _CreateTripExampleState extends State<CreateTripExample> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _destinationController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController();
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tripData = {
        'destination': _destinationController.text,
        'start_date': _startDateController.text,
        'end_date': _endDateController.text,
      };

      // Create trip - this automatically invalidates related caches
      await ServiceLocator.tripRepository.createTrip(tripData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Trip created successfully!')),
        );

        // Return and let parent page refresh with fresh data
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'Destination'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _startDateController,
              decoration: const InputDecoration(labelText: 'Start Date'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endDateController,
              decoration: const InputDecoration(labelText: 'End Date'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Trip'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: Update Trip with Selective Cache Invalidation
class UpdateTripExample extends StatefulWidget {
  const UpdateTripExample({required this.tripId});

  final String tripId;

  @override
  State<UpdateTripExample> createState() => _UpdateTripExampleState();
}

class _UpdateTripExampleState extends State<UpdateTripExample> {
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

  Future<void> _updateTrip() async {
    setState(() => _isLoading = true);

    try {
      await ServiceLocator.tripRepository.updateTrip(
        widget.tripId,
        {'destination': _destinationController.text},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Trip updated!')),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${e.message}')),
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
      appBar: AppBar(title: const Text('Update Trip')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'New Destination'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateTrip,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Trip'),
            ),
          ],
        ),
      ),
    );
  }
}
