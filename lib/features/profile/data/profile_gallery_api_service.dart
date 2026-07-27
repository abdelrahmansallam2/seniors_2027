import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class ProfileGalleryApiService {
  final ApiClient _client;

  ProfileGalleryApiService(this._client);

  Future<Response> getUserGallery(String userId) {
    return _client.get(ApiConstants.galleryUser(userId));
  }
}
