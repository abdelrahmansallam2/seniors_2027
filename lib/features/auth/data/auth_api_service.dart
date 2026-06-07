import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class AuthApiService {
  final ApiClient _client;

  AuthApiService(this._client);

  Future<Response> login(String email) {
    return _client.post(ApiConstants.login, data: {'email': email});
  }

  Future<Response> verifyOtp(String email, String otp) {
    return _client.post(
      ApiConstants.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
  }

  Future<Response> getMe() {
    return _client.get(ApiConstants.me);
  }

  Future<Response> recognizeEmail(String email) {
    return _client.get('${ApiConstants.recognize}/$email');
  }

  Future<Response> uploadPhoto(String filePath) {
    return _client.upload(ApiConstants.uploadPhoto, filePath: filePath);
  }
}
