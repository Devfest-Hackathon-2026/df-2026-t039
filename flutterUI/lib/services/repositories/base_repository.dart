import '../cache/api_proxy.dart';

/// Base repository class for common API patterns
abstract class BaseRepository {
  BaseRepository({required this.proxy});

  final ApiProxy proxy;
}
