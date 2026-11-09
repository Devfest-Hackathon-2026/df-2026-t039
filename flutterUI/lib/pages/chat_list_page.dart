import 'package:flutter/material.dart';

import '../services/service_locator.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late Future<dynamic> _trips;

  @override
  void initState() {
    super.initState();
    _trips = ServiceLocator.tripRepository.listTrips();
  }

  Future<void> _openChat({String? tripId, String? title}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(tripId: tripId, title: title),
      ),
    );
    if (!mounted) return;
    setState(() {
      _trips = ServiceLocator.tripRepository.listTrips(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        title: const Text(
          'チャット',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<dynamic>(
        future: _trips,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading chats: ${snapshot.error}'));
          }

          final trips = (snapshot.data?['trips'] as List?) ?? const [];

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.add)),
                title: const Text('新しいチャット'),
                onTap: () => _openChat(),
              ),
              const Divider(height: 1),
              for (final trip in trips)
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.chat_bubble_outline),
                  ),
                  title: Text(
                    '${trip['title'] ?? trip['destination'] ?? ''}'
                    '${trip['status'] == 'draft' ? '（下書き）' : ''}',
                  ),
                  subtitle: Text(
                    '${trip['start_date'] ?? ''} - ${trip['end_date'] ?? ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openChat(
                    tripId: trip['id']?.toString(),
                    title: trip['title']?.toString(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
