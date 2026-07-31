import 'package:flutter/material.dart';
import 'package:seniors_27/core/cache/current_user_cache.dart';
import 'package:seniors_27/core/storage/token_storage.dart';
import 'package:seniors_27/core/utils/app_log.dart';

class SessionManager {
  SessionManager({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  static final SessionManager instance = SessionManager();

  static const String loginRouteName = '/login';

  final TokenStorage _tokenStorage;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void>? _handling;
  bool _loginScreenVisible = false;

  bool get isHandlingUnauthorized => _handling != null;

  Future<void> handleUnauthorized() {
    final current = _handling;
    if (current != null) {
      appDebugLog('[Session] duplicate unauthorized ignored');
      return current;
    }
    appDebugLog('[Session] unauthorized handling started');
    final future = _endSession().whenComplete(() {
      _handling = null;
      appDebugLog('[Session] unauthorized handling completed');
    });
    _handling = future;
    return future;
  }

  Future<void> logout() async {
    appDebugLog('[Session] manual logout started');
    final current = _handling;
    if (current != null) {
      await current;
      return;
    }
    final future = _endSession().whenComplete(() {
      _handling = null;
      appDebugLog('[Session] unauthorized handling completed');
    });
    _handling = future;
    await future;
  }

  Future<void> _endSession() async {
    try {
      await _tokenStorage.clearToken();
    } catch (_) {
      // Best-effort token clear; continue with the rest of the cleanup.
    }
    appDebugLog('[Session] token cleared');
    try {
      await CurrentUserCache.clear();
    } catch (_) {
      // Best-effort cache clear; continue with the rest of the cleanup.
    }
    appDebugLog('[Session] current-user cache cleared');
    _requestLoginNavigation();
  }

  void _requestLoginNavigation() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      appDebugLog('[Session] navigation unavailable');
      return;
    }
    if (_loginScreenVisible) {
      appDebugLog('[Session] already on login');
      return;
    }
    _loginScreenVisible = true;
    try {
      appDebugLog('[Session] navigation requested');
      navigator.pushNamedAndRemoveUntil(loginRouteName, (route) => false);
    } catch (_) {
      // The login route must be registered on MaterialApp; do not crash if missing.
    }
  }

  void resetAfterSuccessfulLogin() {
    _handling = null;
    _loginScreenVisible = false;
    appDebugLog('[Session] session reset after login');
  }
}
