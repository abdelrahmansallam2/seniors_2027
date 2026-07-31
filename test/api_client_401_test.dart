import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/auth/session_manager.dart';
import 'package:seniors_27/core/storage/token_storage.dart';

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

class _Fake401Adapter implements HttpClientAdapter {
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCount++;
    return ResponseBody.fromString(
      jsonEncode({'message': 'Unauthorized'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RecordingSessionManager extends SessionManager {
  _RecordingSessionManager()
    : super(tokenStorage: TokenStorage(secure: _MapSecureStorage()));

  int unauthorizedCalls = 0;

  @override
  Future<void> handleUnauthorized() async {
    unauthorizedCalls++;
  }
}

Matcher _unauthorized401() => isA<ApiException>()
    .having((e) => e.statusCode, 'statusCode', 401)
    .having((e) => e.message, 'message', 'Unauthorized');

void main() {
  setUp(() {
    TokenStorage.resetCache();
  });

  late _Fake401Adapter adapter;
  late _RecordingSessionManager recorder;
  late ApiClient client;

  setUp(() {
    adapter = _Fake401Adapter();
    recorder = _RecordingSessionManager();
    client = ApiClient(
      tokenStorage: TokenStorage(secure: _MapSecureStorage()),
      dio: Dio()..httpClientAdapter = adapter,
      sessionManager: recorder,
    );
  });

  test(
    'protected GET /api/Auth/me triggers handling once and returns 401',
    () async {
      await expectLater(
        client.get('/api/Auth/me'),
        throwsA(_unauthorized401()),
      );

      expect(recorder.unauthorizedCalls, 1);
      expect(adapter.fetchCount, 1);
    },
  );

  test('protected GET announcements triggers handling', () async {
    await expectLater(
      client.get(
        '/api/portal-content/announcements',
        queryParameters: {'maxCount': 6},
      ),
      throwsA(_unauthorized401()),
    );

    expect(recorder.unauthorizedCalls, 1);
  });

  test('public login 401 does not trigger handling', () async {
    await expectLater(
      client.post('/api/Auth/login', data: {'email': 'x@y.com'}),
      throwsA(_unauthorized401()),
    );

    expect(recorder.unauthorizedCalls, 0);
  });

  test('public verify-otp 401 does not trigger handling', () async {
    await expectLater(
      client.post(
        '/api/Auth/verify-otp',
        data: {'email': 'x@y.com', 'otp': '123456'},
      ),
      throwsA(_unauthorized401()),
    );

    expect(recorder.unauthorizedCalls, 0);
  });

  test('public recognize 401 does not trigger handling', () async {
    await expectLater(
      client.get('/api/Auth/recognize/user@example.com'),
      throwsA(_unauthorized401()),
    );

    expect(recorder.unauthorizedCalls, 0);
  });

  test('simultaneous protected 401s each return the original error', () async {
    final futures = [
      client.get('/api/portal-content/announcements'),
      client.get('/api/portal-content/events'),
    ];
    final results = await Future.wait(
      futures.map((future) async {
        try {
          await future;
          return null;
        } catch (e) {
          return e;
        }
      }),
    );

    for (final result in results) {
      expect(
        result,
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      );
    }
    expect(adapter.fetchCount, 2);
  });
}
