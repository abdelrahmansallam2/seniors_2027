import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';
import 'api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('[API] ➡️ ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          final path = response.requestOptions.path;
          final code = response.statusCode;
          final data = response.data;

          debugPrint('[API] ⬅️ $code $path');

          void printFirstItem(List list, String label) {
            if (list.isEmpty) {
              debugPrint('[API]   $label → EMPTY list');
              return;
            }
            final first = list.first;
            if (first is Map) {
              final keys = first.keys.toList();
              debugPrint('[API]   $label → length=${list.length}, keys=$keys');
              final Map<String, dynamic> safe = {};
              for (final k in keys) {
                final kLower = k.toString().toLowerCase();
                if (kLower.contains('token') ||
                    kLower.contains('password') ||
                    kLower.contains('otp') ||
                    kLower.contains('secret') ||
                    kLower.contains('pin')) {
                  safe[k.toString()] = '***';
                } else {
                  safe[k.toString()] = first[k];
                }
              }
              debugPrint('[API]   $label → sample=$safe');
            } else {
              debugPrint('[API]   $label → first=$first');
            }
          }

          void printTopLevelKeys(Map map, String label) {
            debugPrint('[API]   $label → Map keys=${map.keys}');
          }

          if (path.contains('/api/Users')) {
            debugPrint('[API] --- BEGIN /api/Users ---');
            debugPrint('[API]   status=$code');
            if (data is Map) {
              printTopLevelKeys(data, 'response');
              if (data.containsKey('totalCount')) {
                debugPrint('[API]   totalCount=${data['totalCount']}');
              }
              // Check for items array
              for (final key in ['items', 'data', 'results', 'users']) {
                final val = data[key];
                if (val is List) {
                  printFirstItem(val, 'items ($key)');
                  break;
                }
              }
            } else if (data is List) {
              debugPrint('[API]   response is List length=${data.length}');
              printFirstItem(data, 'items');
            } else {
              debugPrint('[API]   response type=${data.runtimeType}');
            }
            debugPrint('[API] --- END /api/Users ---');
          } else if (path.contains('/api/memoryboard/photos')) {
            debugPrint('[API] --- BEGIN /api/memoryboard/photos ---');
            debugPrint('[API]   status=$code');
            if (data is List) {
              debugPrint('[API]   list length=${data.length}');
              if (data.isNotEmpty && data.first is Map) {
                final first = data.first as Map;
                debugPrint('[API]   first item keys=${first.keys}');
                // Check image fields
                final imageFields = [
                  'imageUrl',
                  'photoUrl',
                  'url',
                  'fileUrl',
                  'imagePath',
                  'path',
                  'image',
                  'photo',
                  'picture',
                  'thumbnailUrl',
                ];
                for (final f in imageFields) {
                  if (first.containsKey(f)) {
                    debugPrint('[API]   image field "$f"=${first[f]}');
                  }
                }
                // Safe print sample
                final Map<String, dynamic> safe = {};
                for (final k in first.keys) {
                  final kLower = k.toString().toLowerCase();
                  if (kLower.contains('token') ||
                      kLower.contains('password') ||
                      kLower.contains('otp') ||
                      kLower.contains('secret') ||
                      kLower.contains('pin')) {
                    safe[k.toString()] = '***';
                  } else {
                    safe[k.toString()] = first[k];
                  }
                }
                debugPrint('[API]   first item sample=$safe');
              }
            } else if (data is Map) {
              printTopLevelKeys(data, 'response');
              for (final key in ['items', 'data', 'results', 'photos']) {
                final val = data[key];
                if (val is List) {
                  debugPrint('[API]   $key length=${val.length}');
                  printFirstItem(val, 'first $key');
                  if (val.isNotEmpty && val.first is Map) {
                    final first = val.first as Map;
                    for (final f in [
                      'imageUrl',
                      'photoUrl',
                      'url',
                      'fileUrl',
                      'imagePath',
                      'path',
                    ]) {
                      if (first.containsKey(f)) {
                        debugPrint('[API]   image field "$f"=${first[f]}');
                      }
                    }
                  }
                  break;
                }
              }
            } else {
              debugPrint('[API]   response type=${data.runtimeType}');
            }
            debugPrint('[API] --- END /api/memoryboard/photos ---');
          } else if (path.contains('/api/portal-content/announcements')) {
            debugPrint('[API] --- BEGIN /api/portal-content/announcements ---');
            debugPrint('[API]   status=$code');
            if (data is List) {
              debugPrint('[API]   list length=${data.length}');
              if (data.isNotEmpty && data.first is Map) {
                final first = data.first as Map;
                debugPrint('[API]   first item keys=${first.keys}');
                final Map<String, dynamic> safe = {};
                for (final k in first.keys) {
                  final kLower = k.toString().toLowerCase();
                  if (kLower.contains('token') ||
                      kLower.contains('password') ||
                      kLower.contains('otp') ||
                      kLower.contains('secret') ||
                      kLower.contains('pin')) {
                    safe[k.toString()] = '***';
                  } else {
                    safe[k.toString()] = first[k];
                  }
                }
                debugPrint('[API]   first item sample=$safe');
                // Check for challenge/poll fields
                final pollKeys = [
                  'type',
                  'pollTitle',
                  'options',
                  'choices',
                  'pollOptions',
                  'votes',
                  'voteCount',
                  'poll',
                  'polls',
                  'challenge',
                  'question',
                ];
                for (final pk in pollKeys) {
                  if (first.containsKey(pk)) {
                    debugPrint(
                      '[API]   POLL/CHALLENGE field "$pk"=${first[pk]}',
                    );
                  }
                }
              }
            } else if (data is Map) {
              printTopLevelKeys(data, 'response');
              for (final key in ['items', 'data', 'results', 'announcements']) {
                final val = data[key];
                if (val is List) {
                  debugPrint('[API]   $key length=${val.length}');
                  printFirstItem(val, 'first $key');
                  break;
                }
              }
            } else {
              debugPrint('[API]   response type=${data.runtimeType}');
            }
            debugPrint('[API] --- END /api/portal-content/announcements ---');
          } else if (path.contains('/api/portal-content/events')) {
            debugPrint('[API] --- BEGIN /api/portal-content/events ---');
            debugPrint('[API]   status=$code');
            if (data is List) {
              debugPrint('[API]   list length=${data.length}');
              if (data.isEmpty) {
                debugPrint('[API]   backend returned empty list');
              } else if (data.first is Map) {
                final first = data.first as Map;
                debugPrint('[API]   first item keys=${first.keys}');
                final Map<String, dynamic> safe = {};
                for (final k in first.keys) {
                  final kLower = k.toString().toLowerCase();
                  if (kLower.contains('token') ||
                      kLower.contains('password') ||
                      kLower.contains('otp') ||
                      kLower.contains('secret') ||
                      kLower.contains('pin')) {
                    safe[k.toString()] = '***';
                  } else {
                    safe[k.toString()] = first[k];
                  }
                }
                debugPrint('[API]   first item sample=$safe');
              }
            } else if (data is Map) {
              printTopLevelKeys(data, 'response');
              for (final key in ['items', 'data', 'results', 'events']) {
                final val = data[key];
                if (val is List) {
                  debugPrint('[API]   $key length=${val.length}');
                  if (val.isEmpty) {
                    debugPrint('[API]   backend returned empty list');
                  } else {
                    printFirstItem(val, 'first $key');
                  }
                  break;
                }
              }
            } else {
              debugPrint('[API]   response type=${data.runtimeType}');
            }
            debugPrint('[API] --- END /api/portal-content/events ---');
          } else if (path.contains('/api/DailyHighlights/active')) {
            debugPrint('[API] --- BEGIN /api/DailyHighlights/active ---');
            debugPrint('[API]   status=$code');
            if (data is List) {
              debugPrint('[API]   list length=${data.length}');
              if (data.isEmpty) {
                debugPrint('[API]   backend returned empty list');
              } else if (data.first is Map) {
                final first = data.first as Map;
                debugPrint('[API]   first item keys=${first.keys}');
                final Map<String, dynamic> safe = {};
                for (final k in first.keys) {
                  final kLower = k.toString().toLowerCase();
                  if (kLower.contains('token') ||
                      kLower.contains('password') ||
                      kLower.contains('otp') ||
                      kLower.contains('secret') ||
                      kLower.contains('pin')) {
                    safe[k.toString()] = '***';
                  } else {
                    safe[k.toString()] = first[k];
                  }
                }
                debugPrint('[API]   first item sample=$safe');
              }
            } else if (data is Map) {
              printTopLevelKeys(data, 'response');
              for (final key in ['items', 'data', 'results', 'highlights']) {
                final val = data[key];
                if (val is List) {
                  debugPrint('[API]   $key length=${val.length}');
                  if (val.isEmpty) {
                    debugPrint('[API]   backend returned empty list');
                  } else {
                    printFirstItem(val, 'first $key');
                  }
                  break;
                }
              }
            } else {
              debugPrint('[API]   response type=${data.runtimeType}');
            }
            debugPrint('[API] --- END /api/DailyHighlights/active ---');
          }

          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint(
            '[API] ❌ ${error.response?.statusCode} '
            '${error.requestOptions.path} '
            '${error.message}',
          );
          if (error.response?.data is Map) {
            final d = error.response!.data as Map;
            debugPrint('[API] ❌ error data keys: ${d.keys}');
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(
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
      return await _dio.post<T>(path, data: formData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout => 'Connection timeout',
      DioExceptionType.sendTimeout => 'Send timeout',
      DioExceptionType.receiveTimeout => 'Receive timeout',
      DioExceptionType.connectionError => 'No internet connection',
      DioExceptionType.badResponse => _parseStatusCode(e.response?.statusCode),
      DioExceptionType.cancel => 'Request cancelled',
      _ => 'An unexpected error occurred',
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
      500 => 'Internal server error',
      _ => 'Request failed with status code $statusCode',
    };
  }
}
