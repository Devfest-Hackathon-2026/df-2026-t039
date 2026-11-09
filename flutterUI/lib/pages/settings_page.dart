import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logout is not connected yet.')),
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
      ),
    );
  }
}
