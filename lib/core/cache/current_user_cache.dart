import 'package:flutter/foundation.dart';
import 'package:seniors_27/core/utils/app_log.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';

class CurrentUserCache {
  CurrentUserCache._();

  static const Duration freshness = Duration(seconds: 60);

  static ProfileUser? _cached;
  static DateTime? _fetchedAt;
  static Future<ProfileUser>? _inFlight;

  static ProfileUser? peek() => _cached;

  static Future<ProfileUser> get({
    required Future<ProfileUser> Function() fetcher,
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _isFresh()) {
      appDebugLog('[CurrentUserCache] cache hit');
      return Future.value(_cached!);
    }
    final inFlight = _inFlight;
    if (inFlight != null) {
      appDebugLog('[CurrentUserCache] joined in-flight request');
      return inFlight;
    }
    appDebugLog('[CurrentUserCache] cache miss');
    final future = _fetch(fetcher);
    _inFlight = future;
    return future;
  }

  static Future<ProfileUser> _fetch(
    Future<ProfileUser> Function() fetcher,
  ) async {
    try {
      final user = await fetcher();
      _cached = user;
      _fetchedAt = DateTime.now();
      appDebugLog('[CurrentUserCache] cache updated');
      return user;
    } finally {
      _inFlight = null;
    }
  }

  static bool _isFresh() {
    if (_cached == null || _fetchedAt == null) return false;
    return DateTime.now().difference(_fetchedAt!) < freshness;
  }

  static void set(ProfileUser user) {
    _cached = user;
    _fetchedAt = DateTime.now();
    appDebugLog('[CurrentUserCache] cache updated');
  }

  static void invalidate() {
    _cached = null;
    _fetchedAt = null;
    appDebugLog('[CurrentUserCache] cache invalidated');
  }

  static Future<void> clear() async {
    invalidate();
  }

  @visibleForTesting
  static void debugSetFetchedAt(DateTime at) {
    _fetchedAt = at;
  }
}
