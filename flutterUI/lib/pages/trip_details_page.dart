import 'package:flutter/material.dart';

import '../widgets/trip_details.dart';

class TripDetailsPage extends StatelessWidget {
  const TripDetailsPage({super.key, required this.trip});

  final Map<String, dynamic> trip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('旅行の詳細')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: TripDetails(trip: trip),
      ),
    );
  }
}
