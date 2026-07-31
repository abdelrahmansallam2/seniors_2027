import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/auth/session_manager.dart';
import 'package:seniors_27/core/storage/token_storage.dart';
import 'package:seniors_27/features/profile/data/profile_api_service.dart';
import 'package:seniors_27/features/profile/edit_profile_photo_screen.dart';

final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

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

class _RecordingSessionManager extends SessionManager {
  _RecordingSessionManager()
    : super(tokenStorage: TokenStorage(secure: _MapSecureStorage()));

  int unauthorizedCalls = 0;

  @override
  Future<void> handleUnauthorized() async {
    unauthorizedCalls++;
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    if (requestStream != null) {
      await requestStream.drain<void>();
    }
    return ResponseBody.fromString(
      jsonEncode({}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.type, {this.statusCode, this.responseData});

  final DioExceptionType type;
  final int? statusCode;
  final Object? responseData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = statusCode != null
        ? Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: responseData,
          )
        : null;
    throw DioException(requestOptions: options, type: type, response: response);
  }

  @override
  void close({bool force = false}) {}
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);

  final int status;
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCount++;
    return ResponseBody.fromString(
      jsonEncode({'message': 'status $status'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _clientWithAdapter(
  HttpClientAdapter adapter, {
  SessionManager? sessionManager,
}) {
  return ApiClient(
    tokenStorage: TokenStorage(secure: _MapSecureStorage()),
    dio: Dio()..httpClientAdapter = adapter,
    sessionManager: sessionManager ?? _RecordingSessionManager(),
  );
}

class _FakeImagePicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return XFile.fromData(kTransparentImage, name: 'picked.png');
  }
}

class _FakeProfileApiService extends ProfileApiService {
  _FakeProfileApiService(super.client);

  @override
  Future<String> updateProfilePhoto(String filePath) async {
    throw ApiException(
      message:
          'No internet connection. Please check your connection and try again.',
      statusCode: null,
      data: 'RAW SERVER RESPONSE BODY',
    );
  }
}

void main() {
  setUp(() {
    TokenStorage.resetCache();
  });

  group('timeout and offline error mapping', () {
    const cases = <({DioExceptionType type, String message})>[
      (
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timed out. Please try again.',
      ),
      (
        type: DioExceptionType.receiveTimeout,
        message: 'The server is taking too long to respond. Please try again.',
      ),
      (
        type: DioExceptionType.sendTimeout,
        message: 'The connection is too slow. Please try again.',
      ),
      (
        type: DioExceptionType.connectionError,
        message:
            'No internet connection. Please check your connection and try again.',
      ),
      (type: DioExceptionType.cancel, message: 'Request cancelled.'),
    ];

    for (final testCase in cases) {
      test(
        '${testCase.type.name} maps to a safe user-facing message',
        () async {
          final client = _clientWithAdapter(_ThrowingAdapter(testCase.type));

          await expectLater(
            client.post('/api/mapping-test', data: {'a': 1}),
            throwsA(
              isA<ApiException>().having(
                (e) => e.message,
                'message',
                testCase.message,
              ),
            ),
          );
        },
      );
    }
  });

  group('HTTP status code mapping', () {
    const cases = <({int status, String message})>[
      (status: 500, message: 'Something went wrong. Please try again.'),
      (status: 502, message: 'Server unavailable. Please try again later.'),
      (status: 503, message: 'Server unavailable. Please try again later.'),
      (status: 504, message: 'Server unavailable. Please try again later.'),
    ];

    for (final testCase in cases) {
      test(
        'HTTP ${testCase.status} maps to a safe user-facing message',
        () async {
          final client = _clientWithAdapter(
            _ThrowingAdapter(
              DioExceptionType.badResponse,
              statusCode: testCase.status,
              responseData: {'detail': 'raw server body'},
            ),
          );

          await expectLater(
            client.post('/api/status-${testCase.status}'),
            throwsA(
              isA<ApiException>()
                  .having((e) => e.statusCode, 'statusCode', testCase.status)
                  .having((e) => e.message, 'message', testCase.message),
            ),
          );
        },
      );
    }
  });

  test(
    'normal requests use 10s connect / 16s receive / 30s send timeouts',
    () async {
      final adapter = _RecordingAdapter();
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 16),
          sendTimeout: const Duration(seconds: 30),
        ),
      )..httpClientAdapter = adapter;
      final client = ApiClient(
        tokenStorage: TokenStorage(secure: _MapSecureStorage()),
        dio: dio,
        sessionManager: _RecordingSessionManager(),
      );

      await client.post('/api/normal-timeouts', data: {'a': 1});

      expect(adapter.lastOptions?.connectTimeout, const Duration(seconds: 10));
      expect(adapter.lastOptions?.receiveTimeout, const Duration(seconds: 16));
      expect(adapter.lastOptions?.sendTimeout, const Duration(seconds: 30));
    },
  );

  test('uploads use 10s connect / 60s receive / 60s send timeouts', () async {
    final file = File(
      '${Directory.systemTemp.path}/seniors_upload_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(const [1, 2, 3]);
    try {
      final adapter = _RecordingAdapter();
      final client = _clientWithAdapter(adapter);

      await client.upload('/api/photos', filePath: file.path);

      expect(adapter.lastOptions?.connectTimeout, const Duration(seconds: 10));
      expect(adapter.lastOptions?.receiveTimeout, const Duration(seconds: 60));
      expect(adapter.lastOptions?.sendTimeout, const Duration(seconds: 60));
    } finally {
      await file.delete();
    }
  });

  test('HTTP 401 keeps the special message and session handling', () async {
    final adapter = _StatusAdapter(401);
    final recorder = _RecordingSessionManager();
    final client = _clientWithAdapter(adapter, sessionManager: recorder);

    await expectLater(
      client.get('/api/portal-content/announcements'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Unauthorized'),
      ),
    );

    expect(recorder.unauthorizedCalls, 1);
  });

  testWidgets(
    'edit profile photo shows the safe message and never the raw response body',
    (tester) async {
      final croppedFile = File(
        '${Directory.systemTemp.path}/seniors_cropped_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await tester.runAsync(() => croppedFile.writeAsBytes(kTransparentImage));
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: EditProfilePhotoScreen(
              currentPhotoUrl: null,
              api: _FakeProfileApiService(
                _clientWithAdapter(_RecordingAdapter()),
              ),
              picker: _FakeImagePicker(),
            ),
          ),
        );

        expect(find.text('GALLERY'), findsOneWidget);

        await tester.tap(find.text('GALLERY'));
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(find.text('CROP PROFILE PHOTO'), findsOneWidget);

        tester
            .state<NavigatorState>(find.byType(Navigator))
            .pop(croppedFile.path);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(find.text('RETAKE'), findsOneWidget);
        expect(find.text('SAVE PHOTO'), findsOneWidget);

        await tester.tap(find.text('SAVE PHOTO'));
        await tester.pump();
        await tester.pump();

        expect(
          find.text(
            'Upload failed: '
            'No internet connection. Please check your connection and try again.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('RAW SERVER RESPONSE BODY'), findsNothing);
      } finally {
        await tester.runAsync(() => croppedFile.delete());
      }
    },
  );

  test('HTTP 429 keeps the special message and global GET cooldown', () async {
    final adapter = _StatusAdapter(429);
    final client = _clientWithAdapter(adapter);

    await expectLater(
      client.get('/api/cooldown-a'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having(
              (e) => e.message,
              'message',
              'Too many requests. Please wait a moment and try again.',
            ),
      ),
    );
    expect(adapter.fetchCount, 1);

    await expectLater(
      client.get('/api/cooldown-b'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having(
              (e) => e.message,
              'message',
              'Too many requests. Please wait a moment and try again.',
            ),
      ),
    );
    expect(adapter.fetchCount, 1);
  });
}
