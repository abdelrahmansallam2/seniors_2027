import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SecureStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStorageAdapter implements SecureStorage {
  final FlutterSecureStorage _storage;
  final AndroidOptions _androidOptions;
  final IOSOptions _iosOptions;

  FlutterSecureStorageAdapter({
    FlutterSecureStorage? storage,
    AndroidOptions? androidOptions,
    IOSOptions? iosOptions,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _androidOptions =
           androidOptions ??
           const AndroidOptions(encryptedSharedPreferences: true),
       _iosOptions =
           iosOptions ??
           const IOSOptions(
             accessibility: KeychainAccessibility.first_unlock_this_device,
           );

  @override
  Future<String?> read(String key) =>
      _storage.read(key: key, aOptions: _androidOptions, iOptions: _iosOptions);

  @override
  Future<void> write(String key, String value) => _storage.write(
    key: key,
    value: value,
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  @override
  Future<void> delete(String key) => _storage.delete(
    key: key,
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );
}

class TokenStorage {
  static const _tokenKey = 'auth_token';

  static String? _cachedToken;
  static bool _cacheInitialized = false;
  static Future<String?>? _initialReadFuture;

  final SecureStorage _secure;

  TokenStorage({SecureStorage? secure})
    : _secure = secure ?? FlutterSecureStorageAdapter();

  Future<void> saveToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Token cannot be empty.');
    }
    await _secure.write(_tokenKey, normalized);
    _cachedToken = normalized;
    _cacheInitialized = true;
  }

  Future<String?> readToken() async {
    if (_cacheInitialized) {
      if (kDebugMode) debugPrint('[TokenStorage] memory cache hit');
      return _cachedToken;
    }

    if (_initialReadFuture != null) {
      if (kDebugMode) debugPrint('[TokenStorage] shared initial read reused');
      return _initialReadFuture;
    }

    if (kDebugMode) debugPrint('[TokenStorage] persistent read started');
    _initialReadFuture = _doPersistentRead();
    try {
      return await _initialReadFuture;
    } finally {
      _initialReadFuture = null;
    }
  }

  Future<String?> _doPersistentRead() async {
    try {
      final secureToken = await _secure.read(_tokenKey);
      if (secureToken != null && secureToken.trim().isNotEmpty) {
        _cachedToken = secureToken.trim();
        _cacheInitialized = true;
        if (kDebugMode) {
          debugPrint(
            '[TokenStorage] persistent read completed tokenExists=true',
          );
        }
        return _cachedToken;
      }
      final migrated = await _migrateLegacyToken();
      _cacheInitialized = true;
      if (kDebugMode) {
        debugPrint(
          '[TokenStorage] persistent read completed tokenExists=${migrated != null}',
        );
      }
      return migrated;
    } catch (_) {
      _cacheInitialized = true;
      if (kDebugMode) debugPrint('[TokenStorage] persistent read failed');
      return null;
    }
  }

  Future<void> clearToken() async {
    await _secure.delete(_tokenKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {
      // Best-effort legacy cleanup
    }
    _cachedToken = null;
    _cacheInitialized = true;
    _initialReadFuture = null;
  }

  Future<String?> _migrateLegacyToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_tokenKey)?.trim();
      if (legacy == null || legacy.isEmpty) return null;
      await _secure.write(_tokenKey, legacy);
      await prefs.remove(_tokenKey);
      if (kDebugMode) {
        debugPrint('[TokenStorage] legacy token migrated');
      }
      return legacy;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static void resetCache() {
    _cachedToken = null;
    _cacheInitialized = false;
    _initialReadFuture = null;
  }
}
