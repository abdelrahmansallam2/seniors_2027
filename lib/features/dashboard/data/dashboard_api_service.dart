import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/announcement.dart';

class DashboardApiService {
  final ApiClient _client;

  DashboardApiService(this._client);

  Future<List<Announcement>> getAnnouncements() async {
    final response = await _client.get(
      ApiConstants.announcements,
      queryParameters: {'maxCount': 6, 'includePast': false},
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Invalid announcements response: expected a List');
  }

  Future<Announcement> voteInPoll(
    String announcementId,
    String optionLabel,
  ) async {
    final response = await _client.post(
      '${ApiConstants.announcements}/$announcementId/poll-vote',
      data: {'option': optionLabel},
    );
    return Announcement.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Response> getEvents() {
    return _client.get(ApiConstants.events);
  }
}
