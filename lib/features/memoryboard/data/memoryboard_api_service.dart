import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../memory_model.dart';

class MemoryboardApiService {
  final ApiClient _client;

  MemoryboardApiService(this._client);

  Future<Response> getPhotos() {
    return _client.get(ApiConstants.memoryBoardPhotos);
  }

  Future<Response> getMyPhotos() {
    return _client.get(ApiConstants.memoryBoardMyPhotos);
  }

  Future<Memory> uploadPhoto({required String filePath}) async {
    final response = await _client.upload(
      ApiConstants.memoryBoardPhotos,
      filePath: filePath,
      fieldName: 'photo',
    );
    return Memory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Response> deletePhoto(String id) {
    return _client.delete('${ApiConstants.memoryBoardMyPhotos}/$id');
  }
}
