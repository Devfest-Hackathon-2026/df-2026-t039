import 'package:flutter/material.dart';

class SavedPlacesPage extends StatelessWidget {
  const SavedPlacesPage({super.key, required this.userData});

  final Map<String, dynamic> userData;

  @override
  Widget build(BuildContext context) {
    final places = (userData['saved_places'] as List)
        .cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved places')),
      body: places.isEmpty
          ? const Center(child: Text('No saved places'))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: Text(place['name'] as String),
                    subtitle: Text(place['location'] as String),
                  ),
                );
              },
            ),
    );
  }
}
