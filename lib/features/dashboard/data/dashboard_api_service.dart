import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class DashboardApiService {
  final ApiClient _client;

  DashboardApiService(this._client);

  Future<Response> getAnnouncements() {
    return _client.get(ApiConstants.announcements);
  }

  Future<Response> getEvents() {
    return _client.get(ApiConstants.events);
  }
}
