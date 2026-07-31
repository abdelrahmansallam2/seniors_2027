import 'dart:io';

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

  Future<void> updateUsername(String username) {
    return _client.put('/api/auth/me/username', data: {'username': username});
  }

  Future<Response> updateDescription(String description) {
    return _client.put(
      '/api/Auth/me/description',
      data: {'description': description},
    );
  }

  Future<String> updateProfilePhoto(String filePath) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split(Platform.pathSeparator).last,
      ),
    });
    final response = await _client.put(ApiConstants.mePhoto, data: formData);
    final data = response.data;
    final photoUrl = data is Map<String, dynamic>
        ? data['photoUrl'] as String?
        : null;
    if (photoUrl == null || photoUrl.isEmpty) {
      throw Exception('Profile photo URL was not returned.');
    }
    return photoUrl;
  }
}
