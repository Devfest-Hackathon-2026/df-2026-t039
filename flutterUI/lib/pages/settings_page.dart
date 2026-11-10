import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログアウト機能はまだ利用できません。')),
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('ログアウト'),
      ),
    );
  }
}
