import 'package:flutter/material.dart';
import 'package:flutter_ui_travelling/customPaints/dash_border_painter.dart';

import '../services/service_locator.dart';
import '../widgets/destination_card.dart';
import '../widgets/trip_details.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  /// Bump to make the home page reload the upcoming trip.
  static final ValueNotifier<int> refreshSignal = ValueNotifier<int>(0);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<dynamic> _upcomingTrips;
  static const double _bottomNavHeight = 65;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _upcomingTrips = ServiceLocator.tripRepository.getUpcomingTrip();
    HomePage.refreshSignal.addListener(_reload);
  }

  @override
  void dispose() {
    HomePage.refreshSignal.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    setState(() {
      _upcomingTrips = ServiceLocator.tripRepository.getUpcomingTrip(
        forceRefresh: true,
      );
    });
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
      await ServiceLocator.tripRepository.updateTrip(
        trip['id'].toString(),
        {'status': 'completed'},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
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
          return Center(child: Text('Error loading user: ${snapshot.error}'));
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
                        'Add a new trip',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const Text(
                  '人気の旅行先',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      destinationCard('Tokyo'),
                      destinationCard('Kyoto'),
                      destinationCard('Osaka'),
                    ],
                  ),
                ),
                const Text(
                  'あなたにおすすめ！！',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      destinationCard('Tokyo'),
                      destinationCard('Kyoto'),
                      destinationCard('Nara'),
                    ],
                  ),
                ),
                const Text(
                  '近場なら…',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      destinationCard('Iwate'),
                      destinationCard('Aomori'),
                      destinationCard('Sendai'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
