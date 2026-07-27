import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';

class NotesApiService {
  final ApiClient _client;

  NotesApiService(this._client);

  Future<Response> getMe() {
    return _client.get(ApiConstants.me);
  }

  Future<Response> getReceivedNotes(
    String recipientId, {
    int pageNumber = 1,
    int pageSize = 50,
  }) {
    return _client.get(
      ApiConstants.notesReceived(recipientId),
      queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
    );
  }

  Future<Response> addReaction(String noteId, String reactionType) {
    return _client.post(
      ApiConstants.noteReactions(noteId),
      data: {'reactionType': reactionType},
    );
  }

  Future<Response> deleteNote(String noteId) {
    return _client.delete(ApiConstants.noteById(noteId));
  }
}
