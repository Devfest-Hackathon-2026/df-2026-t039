import 'package:flutter/material.dart';
import 'package:flutter_ui_travelling/services/service_locator.dart';

import '../widgets/slide_route.dart';
import 'trip_details_page.dart';


class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  late Future<List<dynamic>> _tripsHistory;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tripsHistory = Future.wait<dynamic>([
      ServiceLocator.tripRepository.listTrips(status: 'planned'),
      ServiceLocator.tripRepository.listTrips(status: 'completed')
    ]);
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('旅行履歴')),
      body: FutureBuilder(
        future: _tripsHistory, 
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('旅行履歴の読み込みに失敗しました: ${snapshot.error}'));
          }

          final pendingResponse = snapshot.data![0];
          final completedResponse = snapshot.data![1];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _TripSection(
                title: '計画中の旅行',
                emptyMessage: '計画中の旅行はありません',
                trips: pendingResponse['trips'],
              ),
              _TripSection(
                title: '過去の旅行',
                emptyMessage: '過去の旅行はありません',
                trips: completedResponse['trips'],
              ),
            ],
          );

        },
      )
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
  final List<dynamic> trips;

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
                title: Text('${trip['title']} '),
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
