import 'package:flutter/material.dart';

import '../widgets/slide_route.dart';
import 'trip_details_page.dart';

class MyTripsPage extends StatelessWidget {
  const MyTripsPage({super.key, required this.userData});

  final Map<String, dynamic> userData;

  @override
  Widget build(BuildContext context) {
    final history = (userData['history'] as List).cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(title: const Text('My trips')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _TripSection(
            title: 'Trip history',
            emptyMessage: 'No past trips',
            trips: history,
          ),
        ],
      ),
    );
  }
}

class _TripSection extends StatelessWidget {
  const _TripSection({
    required this.title,
    required this.emptyMessage,
    required this.trips,
  });

  final String title;
  final String emptyMessage;
  final List<Map<String, dynamic>> trips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (trips.isEmpty)
          Text(emptyMessage)
        else
          for (final trip in trips)
            Card(
              child: ListTile(
                title: Text(trip['destination'] as String),
                subtitle: Text('${trip['start_date']} - ${trip['end_date']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  slideRoute(TripDetailsPage(trip: trip)),
                ),
              ),
            ),
      ],
    );
  }
}
