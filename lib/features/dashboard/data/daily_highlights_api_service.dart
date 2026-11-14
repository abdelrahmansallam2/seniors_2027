import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/utils/app_log.dart';
import '../models/daily_highlight.dart';

class DailyHighlightsApiService {
  final ApiClient _client;

  DailyHighlightsApiService(this._client);

  Future<Response> getActive() {
    return _client.get(ApiConstants.dailyHighlightsActive);
  }

  Future<Response> getArchive() {
    return _client.get(ApiConstants.dailyHighlightsArchive);
  }

  Future<DailyHighlight> upload({
    required String filePath,
    String? captionText,
    double? captionYPercent,
    List<int> mentionUserIds = const [],
    ProgressCallback? onSendProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final photo = await MultipartFile.fromFile(filePath);
    final multipartPrepMs = stopwatch.elapsedMilliseconds;
    final formData = FormData.fromMap({'photo': photo});

    final trimmed = captionText?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      formData.fields.add(MapEntry('captionText', trimmed));
      formData.fields.add(
        MapEntry(
          'captionYPercent',
          captionYPercent?.clamp(0.0, 1.0).toString() ?? '0.5',
        ),
      );
    }

    final uniqueIds = mentionUserIds.toSet().toList();
    for (final userId in uniqueIds) {
      formData.fields.add(MapEntry('mentionUserIds', userId.toString()));
    }

    int? firstSendMs;
    int? lastSendMs;
    final Response response;
    try {
      response = await _client.postMultipart(
        ApiConstants.dailyHighlightsUpload,
        formData: formData,
        onSendProgress: (sent, total) {
          final elapsed = stopwatch.elapsedMilliseconds;
          firstSendMs ??= elapsed;
          lastSendMs = elapsed;
          onSendProgress?.call(sent, total);
        },
      );
    } catch (_) {
      appDebugLog(
        '[HighlightUpload] failed fileBytes=${photo.length} '
        'multipartPrepMs=$multipartPrepMs '
        'totalMs=${stopwatch.elapsedMilliseconds}',
      );
      rethrow;
    }

    final completedMs = stopwatch.elapsedMilliseconds;
    final firstSend = firstSendMs;
    final lastSend = lastSendMs;
    final transferMs = firstSend == null
        ? null
        : (lastSend ?? firstSend) - firstSend;
    final responseWaitMs = lastSend == null ? null : completedMs - lastSend;
    appDebugLog(
      '[HighlightUpload] fileBytes=${photo.length} '
      'multipartPrepMs=$multipartPrepMs '
      'transferMs=${transferMs ?? 'unknown'} '
      'responseWaitMs=${responseWaitMs ?? 'unknown'} '
      'totalMs=$completedMs',
    );
    return DailyHighlight.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DailyHighlight> addReaction(String highlightId, String type) async {
    final response = await _client.post(
      '/api/DailyHighlights/$highlightId/reactions',
      data: {'type': type},
    );
    return DailyHighlight.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String highlightId) async {
    await _client.delete('/api/DailyHighlights/$highlightId');
  }

  Future<List<DailyHighlightUser>> searchUsers({
    required String query,
    int pageNumber = 1,
    int pageSize = 8,
  }) async {
    final trimmed = query.trim();

    final response = await _client.get(
      '/api/Users',
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (trimmed.isNotEmpty) 'search': trimmed,
      },
    );

    appDebugLog('[MentionSearch] responseType=${response.data.runtimeType}');

    final data = response.data;
    if (data is Map && data['items'] is List) {
      final items = data['items'] as List;
      appDebugLog('[MentionSearch] itemCount=${items.length}');
      return items
          .map(
            (item) => DailyHighlightUser.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    appDebugLog('[MentionSearch] unexpectedResponseType=${data.runtimeType}');
    throw FormatException(
      'Unexpected server response shape: ${data.runtimeType}',
    );
  }
}
