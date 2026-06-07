import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class SeniorsApiService {
  final ApiClient _client;

  SeniorsApiService(this._client);

  Future<Response> getUsers() {
    return _client.get(ApiConstants.users);
  }

  Future<Response> getUserById(String id) {
    return _client.get('${ApiConstants.users}/$id');
  }
}
