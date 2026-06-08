import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class MemoryboardApiService {
  final ApiClient _client;

  MemoryboardApiService(this._client);

  Future<Response> getPhotos() {
    return _client.get(ApiConstants.memoryBoardPhotos);
  }

  Future<Response> getMyPhotos() {
    return _client.get(ApiConstants.memoryBoardMyPhotos);
  }

  Future<Response> uploadPhoto({
    required String filePath,
    String? description,
  }) {
    return _client.upload(
      ApiConstants.memoryBoardPhotos,
      filePath: filePath,
      extraFields: description != null && description.isNotEmpty
          ? {'description': description}
          : null,
    );
  }

  Future<Response> deletePhoto(String id) {
    return _client.delete('${ApiConstants.memoryBoardMyPhotos}/$id');
  }
}
