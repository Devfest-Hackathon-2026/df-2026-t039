import 'package:flutter/material.dart';
import 'package:flutter_ui_travelling/services/service_locator.dart';

import '../services/nearby_places_handler.dart';
import '../util/geolocator.dart';
import 'chat_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    this.nearbyPlacesLoader,
    this.placesSearchLoader,
    this.savedPlacesLoader,
    this.savePlace,
  });

  final Future<List<NearbyPlace>> Function()? nearbyPlacesLoader;
  final Future<List<NearbyPlace>> Function(String query)? placesSearchLoader;
  final Future<List<dynamic>> Function()? savedPlacesLoader;
  final Future<void> Function(NearbyPlace place)? savePlace;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Future<List<NearbyPlace>> _placesFuture;
  late Future<Set<String>> _savedPlaceKeysFuture;
  final _searchController = TextEditingController();
  final Set<String> _savedPlaceKeys = {};
  String? _saveMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _placesFuture = widget.nearbyPlacesLoader?.call() ?? _loadNearbyPlaces();
    _savedPlaceKeysFuture = _loadSavedPlaceKeys();
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
    final searchLoader = widget.placesSearchLoader;
    if (searchLoader != null) return searchLoader(query);

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

  Future<Set<String>> _loadSavedPlaceKeys() async {
    final savedPlaces =
        await (widget.savedPlacesLoader?.call() ??
            _loadSavedPlacesFromRepository());
    return {
      for (final place in savedPlaces)
        ..._placeKeys(
          id: place['id']?.toString(),
          googlePlaceId: place['google_place_id']?.toString(),
          name: place['name']?.toString(),
          location: place['location']?.toString(),
        ),
    };
  }

  Future<List<dynamic>> _loadSavedPlacesFromRepository() async {
    final response = await ServiceLocator.savedPlacesRepository.listSavedPlaces();
    return response['places'] as List<dynamic>;
  }

  Set<String> _placeKeys({
    String? id,
    String? googlePlaceId,
    String? name,
    String? location,
  }) => {
    if (id != null && id.isNotEmpty) 'id:$id',
    if (googlePlaceId != null && googlePlaceId.isNotEmpty)
      'google:$googlePlaceId',
    if (name != null && name.isNotEmpty) 'name:$name|${location ?? ''}',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchPlaces() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _placesFuture = query.isEmpty
          ? (widget.nearbyPlacesLoader?.call() ?? _loadNearbyPlaces())
          : _searchForPlaces(query);
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
      if (mounted) {
        setState(() {
          _savedPlaceKeys.addAll(
            _placeKeys(
              id: place.id,
              googlePlaceId: place.googlePlaceId,
              name: place.name,
              location: place.location,
            ),
          );
          _saveMessage = '場所を保存しました。';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _saveMessage = '場所の保存に失敗しました: $error');
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
              labelText: '場所を検索',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '検索語を消去',
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.clear),
                  ),
                  IconButton(
                    tooltip: '場所を検索',
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
            '近くの場所',
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
                  tooltip: 'メッセージを閉じる',
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
                  child: Text('場所の読み込みに失敗しました: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final places = snapshot.data!.toList();

              if (places.isEmpty) {
                return const Center(child: Text('場所が見つかりませんでした'));
              }
              return FutureBuilder<Set<String>>(
                future: _savedPlaceKeysFuture,
                builder: (context, savedPlacesSnapshot) {
                  if (savedPlacesSnapshot.hasError) {
                    return Center(
                      child: Text(
                        '保存した場所の読み込みに失敗しました: ${savedPlacesSnapshot.error}',
                      ),
                    );
                  }
                  if (!savedPlacesSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final savedPlaceKeys = {
                    ...savedPlacesSnapshot.data!,
                    ..._savedPlaceKeys,
                  };
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final place = places[index];
                      final isSaved =
                          place.isSaved ||
                          _placeKeys(
                            id: place.id,
                            googlePlaceId: place.googlePlaceId,
                            name: place.name,
                            location: place.location,
                          ).any(savedPlaceKeys.contains);
                      return Card(
                        child: ListTile(
                          title: Text(place.name),
                          subtitle: Text(
                            '${place.location} · ${place.category}',
                          ),
                          onTap: () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).push(
                            MaterialPageRoute(
                              builder: (_) => ChatPage.forDestination(
                                destination: place.name,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: isSaved
                                ? '保存済み: ${place.name}'
                                : '保存する: ${place.name}',
                            color: isSaved ? Colors.red : null,
                            icon: Icon(
                              isSaved ? Icons.favorite : Icons.favorite_border,
                            ),
                            onPressed: _isSaving || isSaved
                                ? null
                                : () => handleSavePlace(place),
                          ),
                        ),
                      );
                    },
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
