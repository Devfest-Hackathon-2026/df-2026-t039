import 'package:flutter/foundation.dart';

/// Represents a cached item with metadata
class CachedItem<T> {
  CachedItem({
    required this.data,
    required this.timestamp,
    required this.ttlSeconds,
  });

  final T data;
  final DateTime timestamp;
  final int ttlSeconds;

  /// Check if cache is still valid
  bool get isValid {
    if (ttlSeconds == -1) return true; // -1 means no expiration
    final expiresAt = timestamp.add(Duration(seconds: ttlSeconds));
    return DateTime.now().isBefore(expiresAt);
  }

  /// Get remaining TTL in seconds
  int get remainingTtl {
    if (ttlSeconds == -1) return -1;
    final expiresAt = timestamp.add(Duration(seconds: ttlSeconds));
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

/// Cache management system with TTL support
class CacheManager extends ChangeNotifier {
  final Map<String, CachedItem> _cache = {};

  /// Default TTL in seconds (5 minutes)
  static const int defaultTtl = 300;

  /// Get cached value if valid, otherwise return null
  T? get<T>(String key) {
    final item = _cache[key];
    if (item == null) return null;

    if (!item.isValid) {
      _cache.remove(key);
      notifyListeners();
      return null;
    }

    return item.data as T;
  }

  /// Set cache value with optional TTL
  void set<T>(String key, T value, {int? ttlSeconds}) {
    _cache[key] = CachedItem(
      data: value,
      timestamp: DateTime.now(),
      ttlSeconds: ttlSeconds ?? defaultTtl,
    );
    notifyListeners();
  }

  /// Set cache with no expiration (permanent until manually cleared)
  void setPermanent<T>(String key, T value) {
    _cache[key] = CachedItem(
      data: value,
      timestamp: DateTime.now(),
      ttlSeconds: -1,
    );
    notifyListeners();
  }

  /// Remove specific cache entry
  void remove(String key) {
    if (_cache.remove(key) != null) {
      notifyListeners();
    }
  }

  /// Remove multiple cache entries by pattern
  void removeByPattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys.where((key) => regex.hasMatch(key)).toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    notifyListeners();
  }

  /// Get cache info for debugging
  Map<String, dynamic> getCacheInfo(String key) {
    final item = _cache[key];
    if (item == null) return {'exists': false};

    return {
      'exists': true,
      'isValid': item.isValid,
      'remainingTtl': item.remainingTtl,
      'createdAt': item.timestamp.toIso8601String(),
      'dataType': item.data.runtimeType.toString(),
    };
  }

  /// Get all cache keys
  List<String> getAllKeys() => _cache.keys.toList();

  /// Get cache size in bytes (approximate)
  int getCacheSize() {
    int size = 0;
    for (final item in _cache.values) {
      size += item.data.toString().length;
    }
    return size;
  }

  /// Clean up expired entries
  void cleanup() {
    final expiredKeys = _cache.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      notifyListeners();
    }
  }
}
