import 'package:flutter/material.dart';
import 'package:flutter_ui_travelling/customPaints/dash_border_painter.dart';

import '../services/user_data_handler.dart';
import '../widgets/destination_card.dart';
import '../widgets/trip_details.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Created once, rather than loading the file on every rebuild.
  final _userFuture = const UserDataHandler().loadUserData();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading user: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8.0,
            children: [
              if (user['upcoming_trips'] != null &&
                  user['upcoming_trips'].isNotEmpty)
                ...user['upcoming_trips'].map<Widget>(
                  (trip) => TripDetails(trip: trip as Map<String, dynamic>),
                )
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
