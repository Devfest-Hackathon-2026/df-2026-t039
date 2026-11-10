import 'dart:math';

import 'base_repository.dart';

/// Per-trip AI chat messages. One trip has exactly one conversation.
class MessagesRepository extends BaseRepository {
  MessagesRepository({required super.proxy});

  /// Get the conversation of a trip: `{ messages: ChatMessage[] }`.
  Future<dynamic> listMessages(String tripId) async {
    return proxy.request('GET', '/api/trips/$tripId/messages');
  }

  /// Send a message. Retry with the same [clientMessageId] after a failure.
  /// Returns `{ message, trip, suggested_places }`.
  Future<dynamic> sendMessage(
    String tripId,
    String text, {
    required String clientMessageId,
  }) async {
    return proxy.post(
      '/api/trips/$tripId/messages',
      body: {'client_message_id': clientMessageId, 'text': text},
      cacheInvalidationPatterns: [
        '^GET:/api/trips', // trip plan may have changed
      ],
    );
  }

  static String newClientMessageId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
