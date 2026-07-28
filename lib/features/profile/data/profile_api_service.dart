import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class ProfileApiService {
  final ApiClient _client;

  ProfileApiService(this._client);

  Future<Response> getMe() {
    return _client.get(ApiConstants.me);
  }

  Future<Response> updateSocialLinks(List<String> urls) {
    return _client.put(ApiConstants.socialLinks, data: {'links': urls});
  }

  Future<Response> updateFavoriteSong(String embedUrl) {
    return _client.put(ApiConstants.favoriteSong, data: {'input': embedUrl});
  }
}
