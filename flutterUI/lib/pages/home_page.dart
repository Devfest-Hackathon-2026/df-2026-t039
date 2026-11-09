import 'package:flutter/material.dart';
import 'package:flutter_ui_travelling/customPaints/dash_border_painter.dart';

import '../util/geolocator.dart';
import '../services/nearby_places_handler.dart';
import '../services/service_locator.dart';
import '../widgets/destination_card.dart';
import '../widgets/trip_details.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.upcomingTripLoader, this.nearbyPlacesLoader});

  final Future<dynamic> Function()? upcomingTripLoader;
  final Future<List<NearbyPlace>> Function()? nearbyPlacesLoader;

  /// Bump to make the home page reload the upcoming trip.
  static final ValueNotifier<int> refreshSignal = ValueNotifier<int>(0);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<dynamic> _upcomingTrips;
  Future<List<NearbyPlace>>? _nearbyPlaces;
  static const double _bottomNavHeight = 65;

  static const _popularDestinations = [
    (
      name: '東京',
      imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=700&q=80',
    ),
    (
      name: '京都',
      imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=700&q=80',
    ),
    (
      name: '大阪',
      imageUrl: 'https://images.unsplash.com/photo-1590559899731-a382839e5549?auto=format&fit=crop&w=700&q=80',
    ),
  ];

  static const _recommendedDestinations = [
    (
      name: '東京',
      imageUrl: 'https://images.unsplash.com/photo-1513407030348-c983a97b98d8?auto=format&fit=crop&w=700&q=80',
    ),
    (
      name: '京都',
      imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?auto=format&fit=crop&w=700&q=80',
    ),
    (
      name: '奈良',
      imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?auto=format&fit=crop&w=700&q=80',
    ),
  ];

  static const _nearbyDestinations = [
    (
      name: '岩手',
      imageUrl: 'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?auto=format&fit=crop&w=700&q=80',
    ),
    (
      name: '青森',
      imageUrl: 'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?auto=format&fit=crop&w=700&q=80',
    ),
    (
      name: '仙台',
      imageUrl: 'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=700&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _upcomingTrips =
        widget.upcomingTripLoader?.call() ??
        ServiceLocator.tripRepository.getUpcomingTrip();
    HomePage.refreshSignal.addListener(_reload);
  }

  @override
  void dispose() {
    HomePage.refreshSignal.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    setState(() {
      _upcomingTrips =
          widget.upcomingTripLoader?.call() ??
          ServiceLocator.tripRepository.getUpcomingTrip(forceRefresh: true);
    });
  }

  Future<List<NearbyPlace>> _loadNearbyPlaces() async {
    final position = await getCurrentPosition();
    final response = await ServiceLocator.placesRepository.getNearbyPlaces(
      lat: position.latitude,
      lng: position.longitude,
    );
    return (response['places'] as List<dynamic>)
        .map(
          (place) =>
              NearbyPlace.fromJson(Map<String, dynamic>.from(place as Map)),
        )
        .toList();
  }

  void _openTripChat(String destination) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(initialMessage: '$destinationへの旅行を計画したいです。'),
      ),
    );
  }

  Widget _buildDestinationSection(
    String title,
    List<({String name, String imageUrl})> destinations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        _buildDestinationCards(destinations),
      ],
    );
  }

  Widget _buildDestinationCards(
    List<({String name, String imageUrl})> destinations,
  ) {
    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final destination in destinations)
            DestinationCard(
              name: destination.name,
              subtitle: 'タップして旅行を計画',
              imageUrl: destination.imageUrl,
              onTap: () => _openTripChat(destination.name),
            ),
        ],
      ),
    );
  }

  Widget _buildNearbySection() {
    final placesFuture = _nearbyPlaces ??=
        widget.nearbyPlacesLoader?.call() ?? _loadNearbyPlaces();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '現在地の近くでおすすめ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<NearbyPlace>>(
          future: placesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Row(
                children: [
                  Expanded(child: Text('近くの場所を読み込めませんでした: ${snapshot.error}')),
                  IconButton(
                    tooltip: '再読み込み',
                    onPressed: () {
                      setState(() {
                        _nearbyPlaces =
                            widget.nearbyPlacesLoader?.call() ??
                            _loadNearbyPlaces();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 170,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.data!.isEmpty) {
              return const Text('近くにおすすめの場所が見つかりませんでした');
            }
            return SizedBox(
              height: 170,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final place in snapshot.data!)
                    DestinationCard(
                      name: place.name,
                      subtitle: [
                        place.location,
                        if (place.category.isNotEmpty) place.category,
                      ].where((part) => part.isNotEmpty).join(' · '),
                      width: 240,
                      onTap: () => _openTripChat(place.name),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmCompleteTrip(Map<String, dynamic> trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('旅行の完了'),
        content: const Text('この旅行を完了として記録しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('はい'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _completeTrip(trip);
    }
  }

  Future<void> _completeTrip(Map<String, dynamic> trip) async {
    try {
      await ServiceLocator.tripRepository.updateTrip(trip['id'].toString(), {
        'status': 'completed',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
      return;
    }
    if (!mounted) return;
    setState(() {
      _upcomingTrips = ServiceLocator.tripRepository.getUpcomingTrip(
        forceRefresh: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _upcomingTrips,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('旅行情報の読み込みに失敗しました: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final upcomingTrip = snapshot.data['trip'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8.0,
            children: [
              if (upcomingTrip != null) ...[
                TripDetails(trip: upcomingTrip as Map<String, dynamic>),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _confirmCompleteTrip(upcomingTrip),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('完了'),
                  ),
                ),
                const SizedBox(height: _bottomNavHeight),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: CustomPaint(
                    painter: DashedBorderPainter(),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        fixedSize: Size.fromHeight(
                          MediaQuery.of(context).size.height * 0.15,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.all(
                            Radius.circular(8),
                          ),
                        ),
                        side: BorderSide.none,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChatPage()),
                        );
                      },
                      child: const Text(
                        '新しい旅行を追加',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                _buildDestinationSection('人気の旅行先', _popularDestinations),
                _buildDestinationSection('おすすめの旅行先', _recommendedDestinations),
                _buildDestinationSection('近場の旅行先', _nearbyDestinations),
                _buildNearbySection(),
              ],
            ],
          ),
        );
      },
    );
  }
}
