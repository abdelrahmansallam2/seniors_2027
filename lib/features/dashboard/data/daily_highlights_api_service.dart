import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class DailyHighlightsApiService {
  final ApiClient _client;

  DailyHighlightsApiService(this._client);

  Future<Response> getActive() {
    return _client.get(ApiConstants.dailyHighlightsActive);
  }

  Future<Response> getArchive() {
    return _client.get(ApiConstants.dailyHighlightsArchive);
  }

  Future<Response> upload({required String filePath, String? description}) {
    return _client.upload(
      ApiConstants.dailyHighlightsUpload,
      filePath: filePath,
      extraFields: description != null && description.isNotEmpty
          ? {'description': description}
          : null,
    );
  }

  Future<Response> addReaction(String id) {
    return _client.post('/api/DailyHighlights/$id/reactions');
  }

  Future<Response> delete(String id) {
    return _client.delete('/api/DailyHighlights/$id');
  }
}
