import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seniors_27/core/storage/token_storage.dart';

const _tokenKey = 'auth_token';

class _MapSecureStorage implements SecureStorage {
  final _store = <String, String>{};

  @override
  Future<String?> read(String key) => Future.value(_store[key]);

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  setUp(() {
    prefs.clear();
    TokenStorage.resetCache();
  });

  group('TokenStorage with secure storage', () {
    late _MapSecureStorage secure;
    late TokenStorage storage;

    setUp(() {
      secure = _MapSecureStorage();
      storage = TokenStorage(secure: secure);
    });

    test('saves and reads a valid token', () async {
      await storage.saveToken('my-secure-token-123');
      final result = await storage.readToken();
      expect(result, 'my-secure-token-123');
    });

    test('trims whitespace on save', () async {
      await storage.saveToken('  spacey-token  ');
      final result = await storage.readToken();
      expect(result, 'spacey-token');
    });

    test('throws ArgumentError for empty token', () async {
      expect(() => storage.saveToken(''), throwsA(isA<ArgumentError>()));
    });

    test('throws ArgumentError for whitespace-only token', () async {
      expect(() => storage.saveToken('   '), throwsA(isA<ArgumentError>()));
    });

    test('returns null when no token exists', () async {
      final result = await storage.readToken();
      expect(result, isNull);
    });

    test('clears token', () async {
      await storage.saveToken('delete-me');
      await storage.clearToken();
      final result = await storage.readToken();
      expect(result, isNull);
    });

    test('secure token takes priority over legacy', () async {
      await prefs.setString(_tokenKey, 'legacy');
      await storage.saveToken('secure-value');
      final result = await storage.readToken();
      expect(result, 'secure-value');
    });
  });

  group('TokenStorage legacy migration', () {
    late _MapSecureStorage secure;
    late TokenStorage storage;

    setUp(() {
      secure = _MapSecureStorage();
      storage = TokenStorage(secure: secure);
    });

    test('migrates legacy SharedPreferences token', () async {
      await prefs.setString(_tokenKey, 'legacy-token');
      final result = await storage.readToken();
      expect(result, 'legacy-token');
      expect(secure._store[_tokenKey], 'legacy-token');
    });

    test('removes legacy key after successful migration', () async {
      await prefs.setString(_tokenKey, 'migrate-me');
      expect(prefs.getString(_tokenKey), 'migrate-me');
      await storage.readToken();
      expect(prefs.getString(_tokenKey), isNull);
    });

    test('does not migrate empty legacy token', () async {
      await prefs.setString(_tokenKey, '');
      final result = await storage.readToken();
      expect(result, isNull);
    });

    test('does not migrate whitespace-only legacy token', () async {
      await prefs.setString(_tokenKey, '   ');
      final result = await storage.readToken();
      expect(result, isNull);
    });

    test('existing secure token prevents legacy read', () async {
      await prefs.setString(_tokenKey, 'legacy-value');
      await secure.write(_tokenKey, 'secure-value');
      final result = await storage.readToken();
      expect(result, 'secure-value');
      expect(prefs.getString(_tokenKey), 'legacy-value');
    });

    test('migrated token is returned after clearToken', () async {
      await prefs.setString(_tokenKey, 'migrate-me');
      final migrated = await storage.readToken();
      expect(migrated, 'migrate-me');
      expect(secure._store[_tokenKey], 'migrate-me');
      await storage.clearToken();
      final result = await storage.readToken();
      expect(result, isNull);
    });

    test('clearToken also cleans up legacy key', () async {
      await prefs.setString(_tokenKey, 'legacy');
      await secure.write(_tokenKey, 'secure');
      await storage.clearToken();
      expect(prefs.getString(_tokenKey), isNull);
    });
  });
}
