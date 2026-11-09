import 'package:flutter/material.dart';

import '../services/nearby_places_handler.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _placesFuture = const NearbyPlacesHandler().loadNearbyPlaces();
  final _searchController = TextEditingController();
  String _query = '';
  bool _showSaveMessage = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchPlaces() {
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search places',
              prefixIcon: IconButton(
                tooltip: 'Clear search input',
                onPressed: _searchController.clear,
                icon: const Icon(Icons.clear),
              ),
              suffixIcon: IconButton(
                tooltip: 'Search places',
                onPressed: _searchPlaces,
                icon: const Icon(Icons.arrow_forward),
              ),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Nearby places (sample data)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (_showSaveMessage)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: const Text('Saving places is not connected yet.'),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss message',
                  onPressed: () => setState(() => _showSaveMessage = false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<NearbyPlace>>(
            future: _placesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading places: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final places = snapshot.data!.where((place) {
                return place.name.toLowerCase().contains(_query) ||
                    place.location.toLowerCase().contains(_query) ||
                    place.category.toLowerCase().contains(_query);
              }).toList();

              if (places.isEmpty) {
                return const Center(child: Text('No places found'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return Card(
                    child: ListTile(
                      title: Text(place.name),
                      subtitle: Text('${place.location} · ${place.category}'),
                      trailing: IconButton(
                        tooltip: 'Save ${place.name}',
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () =>
                            setState(() => _showSaveMessage = true),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
