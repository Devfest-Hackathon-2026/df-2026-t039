import 'package:flutter/material.dart';

import '../services/user_data_handler.dart';
import '../widgets/slide_route.dart';
import 'my_trips_page.dart';
import 'personal_information_page.dart';
import 'saved_places_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userFuture = const UserDataHandler().loadUserData();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<void>(
      enabled: widget.isActive,
      onPopWithResult: (_) => _navigatorKey.currentState!.pop(),
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => _buildProfile(),
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading user: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _ProfileContent(userData: snapshot.data!);
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.userData});

  final Map<String, dynamic> userData;

  String _getValue(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = userData[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final name = _getValue([
      'name',
      'fullName',
      'username',
    ], fallback: 'Traveler');
    final email = _getValue(['email', 'emailAddress']);
    final imageUrl = _getValue([
      'photoUrl',
      'photoURL',
      'imageUrl',
      'profileImage',
    ]);
    final location = _getValue(['location', 'city', 'address']);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.person_outline, size: 52)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(email, textAlign: TextAlign.center),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 4),
                Text(location),
              ],
            ),
          ],
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Personal information'),
                  onTap: () {
                    Navigator.of(context).push(
                      slideRoute(PersonalInformationPage(userData: userData)),
                    );
                  },
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.luggage_outlined),
                  title: Text('My trips'),
                  onTap: () {
                    Navigator.of(context).push(
                      slideRoute(MyTripsPage(userData: userData)),
                    );
                  },
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.favorite_border),
                  title: Text('Saved places'),
                  onTap: () {
                    Navigator.of(context).push(
                      slideRoute(SavedPlacesPage(userData: userData)),
                    );
                  },
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
