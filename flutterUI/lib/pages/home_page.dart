import 'package:flutter/material.dart';
import 'package:flutter_ui_travelling/customPaints/dash_border_painter.dart';

import '../services/service_locator.dart';
import '../widgets/destination_card.dart';
import '../widgets/trip_details.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<dynamic> _upcomingTrips;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _upcomingTrips = ServiceLocator.tripRepository.getUpcomingTrip();
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
              if (upcomingTrip!= null )
                TripDetails(trip: upcomingTrip as Map<String, dynamic>)
                
              else ...[
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
                        //TODO: Implement a function to move to the chat page
                        print('Add a new trip'); // FUnction to create new trip
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
