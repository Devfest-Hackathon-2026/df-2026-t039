import 'package:flutter/material.dart';
import 'package:flutter_ui_travelling/services/service_locator.dart';

import '../services/nearby_places_handler.dart';
import '../util/geolocator.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.nearbyPlacesLoader, this.savePlace});

  final Future<List<NearbyPlace>> Function()? nearbyPlacesLoader;
  final Future<void> Function(NearbyPlace place)? savePlace;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Future<List<NearbyPlace>> _placesFuture;
  final _searchController = TextEditingController();
  String? _saveMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _placesFuture = widget.nearbyPlacesLoader?.call() ?? _loadNearbyPlaces();
  }

  Future<List<NearbyPlace>> _loadNearbyPlaces() async {
    final position = await getCurrentPosition();
    final response = await ServiceLocator.placesRepository.getNearbyPlaces(
      lat: position.latitude,
      lng: position.longitude,
    );
    final places = response['places'] as List<dynamic>;
    return places
        .map(
          (place) =>
              NearbyPlace.fromJson(Map<String, dynamic>.from(place as Map)),
        )
        .toList();
  }

  Future<List<NearbyPlace>> _searchForPlaces(String query) async {
    final response = await ServiceLocator.placesRepository.searchPlaces(
      q: query,
    );
    final places = response['places'] as List<dynamic>;
    return places
        .map(
          (place) =>
              NearbyPlace.fromJson(Map<String, dynamic>.from(place as Map)),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchPlaces() {
    setState(() {
      _placesFuture = _searchForPlaces(
        _searchController.text.trim().toLowerCase(),
      );
    });
  }

  Future<void> _savePlace(NearbyPlace place) async {
    var placeId = place.id;
    if (placeId == null) {
      final response = await ServiceLocator.placesRepository.createPlace(
        googlePlaceId: place.googlePlaceId,
        name: place.name,
        location: place.location,
        latitude: place.latitude,
        longitude: place.longitude,
      );
      placeId = response['place']['id'] as String;
    }
    await ServiceLocator.savedPlacesRepository.createSavedPlace({
      'place_id': placeId,
    });
  }

  Future<void> handleSavePlace(NearbyPlace place) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _saveMessage = null;
    });
    try {
      await (widget.savePlace ?? _savePlace)(place);
      if (mounted) setState(() => _saveMessage = 'Place saved.');
    } catch (error) {
      if (mounted) setState(() => _saveMessage = 'Error saving place: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Clear search input',
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.clear),
                  ),
                  IconButton(
                    tooltip: 'Search places',
                    onPressed: _searchPlaces,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Nearby places',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (_saveMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(_saveMessage!),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss message',
                  onPressed: () => setState(() => _saveMessage = null),
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
              final places = snapshot.data!.toList();

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
                      subtitle: Text(
                        '${place.location} · ${place.category} ',
                      ),
                      trailing: IconButton(
                        tooltip: 'Save ${place.name}',
                        icon: const Icon(Icons.favorite_border),
                        onPressed: _isSaving
                            ? null
                            : () => handleSavePlace(place),
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
