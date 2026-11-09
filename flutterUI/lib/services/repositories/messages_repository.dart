import '../cache/api_proxy.dart';
import 'base_repository.dart';

/// Messages Repository (typically not cached or short TTL)
class MessagesRepository extends BaseRepository {
  MessagesRepository({required super.proxy});

  /// Get messages (cached for 2 minutes)
  Future<dynamic> listMessages({
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    return proxy.getWithCache(
      '/messages',
      query: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
      forceRefresh: forceRefresh,
      cacheTtl: 120, // 2 minutes
    );
  }

  /// Send a message and invalidate cache
  Future<dynamic> sendMessage(Map<String, dynamic> messageData) async {
    return proxy.post(
      '/messages',
      body: messageData,
      cacheInvalidationPatterns: ['^GET:/messages'],
    );
  }
}
