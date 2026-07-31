import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/session_manager.dart';
import '../storage/token_storage.dart';
import '../utils/app_log.dart';
import 'api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;
  final SessionManager _sessionManager;
  static final Map<String, Future<Response<dynamic>>> _inFlightGets = {};
  static DateTime? _globalGetCooldownUntil;

  ApiClient({
    TokenStorage? tokenStorage,
    Dio? dio,
    SessionManager? sessionManager,
  }) : _tokenStorage = tokenStorage ?? TokenStorage(),
       _sessionManager = sessionManager ?? SessionManager.instance {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 16),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );
    if (dio != null) {
      _dio.options.headers.addAll(const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.extra['_startTime'] = DateTime.now();
          final qs = _sanitizeQuery(options.queryParameters);
          final logPath = qs.isNotEmpty ? '${options.path}?$qs' : options.path;
          appDebugLog('[API] ➡️ ${options.method} $logPath');
          handler.next(options);
        },
        onResponse: (response, handler) {
          final data = response.data;
          final startTime =
              response.requestOptions.extra['_startTime'] as DateTime?;
          final elapsed = startTime != null
              ? DateTime.now().difference(startTime).inMilliseconds
              : 0;
          final count = data is List ? ' count=${data.length}' : '';
          appDebugLog(
            '[API] status=${response.statusCode} elapsedMs=$elapsed$count',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          final code = error.response?.statusCode;
          final startTime =
              error.requestOptions.extra['_startTime'] as DateTime?;
          final elapsed = startTime != null
              ? DateTime.now().difference(startTime).inMilliseconds
              : 0;

          if (code == 401 && !_isPublicAuthPath(error.requestOptions.path)) {
            unawaited(_sessionManager.handleUnauthorized());
          }

          if (code == 429) {
            int cooldownSecs = 8;
            final retryAfter = error.response?.headers.value('retry-after');
            if (retryAfter != null) {
              final parsed = int.tryParse(retryAfter);
              if (parsed != null && parsed > 0) {
                cooldownSecs = parsed;
              }
            }
            _globalGetCooldownUntil = DateTime.now().add(
              Duration(seconds: cooldownSecs),
            );
            appDebugLog('[API] status=429 cooldownSeconds=$cooldownSecs');
          }

          appDebugLog('[API] request failed status=$code elapsedMs=$elapsed');
          handler.next(error);
        },
      ),
    );
  }

  String _sanitizeQuery(Map<String, dynamic> query) {
    const sensitive = [
      'token',
      'otp',
      'password',
      'email',
      'authorization',
      'secret',
      'code',
      'search',
      'query',
    ];
    final parts = <String>[];
    query.forEach((key, value) {
      if (value == null) return;
      final lower = key.toLowerCase();
      final isSensitive = sensitive.any(lower.contains);
      parts.add('$key=${isSensitive ? '<redacted>' : value}');
    });
    return parts.join('&');
  }

  static const List<String> _exactPublicAuthPaths = [
    '/api/Auth/login',
    '/api/Auth/verify-otp',
  ];
  static const String _publicRecognizePrefix = '/api/Auth/recognize/';

  bool _isPublicAuthPath(String path) {
    final normalized = path.split('?').first;
    if (_exactPublicAuthPaths.contains(normalized)) return true;
    return normalized.startsWith(_publicRecognizePrefix);
  }

  String _requestKey(
    String method,
    String path,
    Map<String, dynamic>? queryParameters,
  ) {
    final sorted = (queryParameters ?? <String, dynamic>{}).entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '$method|$path|${sorted.where((e) => e.value != null).map((e) => '${e.key}=${e.value}').join('&')}';
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (_globalGetCooldownUntil != null &&
        DateTime.now().isBefore(_globalGetCooldownUntil!)) {
      appDebugLog('[API] GET blocked by global cooldown');
      throw ApiException(
        message: 'Too many requests. Please wait a moment and try again.',
        statusCode: 429,
      );
    }
    final key = _requestKey('GET', path, queryParameters);
    final existing = _inFlightGets[key];
    if (existing != null) {
      appDebugLog('[API] duplicate GET reused');
      return await existing as Response<T>;
    }
    final future = _executeGet<T>(path, queryParameters: queryParameters);
    _inFlightGets[key] = future;
    try {
      return await future;
    } finally {
      _inFlightGets.remove(key);
    }
  }

  Future<Response<T>> _executeGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> upload<T>(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (extraFields != null) ...extraFields,
      });
      final options = Options(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      );
      return await _dio.post<T>(path, data: formData, options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout =>
        'Connection timed out. Please try again.',
      DioExceptionType.sendTimeout =>
        'The connection is too slow. Please try again.',
      DioExceptionType.receiveTimeout =>
        'The server is taking too long to respond. Please try again.',
      DioExceptionType.connectionError =>
        'No internet connection. Please check your connection and try again.',
      DioExceptionType.badResponse => _parseStatusCode(e.response?.statusCode),
      DioExceptionType.cancel => 'Request cancelled.',
      _ => 'Something went wrong. Please try again.',
    };
    return ApiException(
      message: message,
      statusCode: e.response?.statusCode,
      data: e.response?.data,
    );
  }

  String _parseStatusCode(int? statusCode) {
    return switch (statusCode) {
      400 => 'Bad request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not found',
      409 => 'Conflict',
      422 => 'Validation error',
      429 => 'Too many requests. Please wait a moment and try again.',
      500 => 'Something went wrong. Please try again.',
      502 || 503 || 504 => 'Server unavailable. Please try again later.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
