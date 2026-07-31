import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class SeniorsApiService {
  final ApiClient _client;

  SeniorsApiService(this._client);

  Future<Response> getUsers({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
  }) {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    return _client.get(ApiConstants.users, queryParameters: params);
  }

  Future<Response> getUserById(String id) {
    return _client.get('${ApiConstants.users}/$id');
  }
}
