import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/cache/current_user_cache.dart';
import 'package:seniors_27/features/notes/data/notes_api_service.dart';
import 'package:seniors_27/features/notes/notes_open_book_screen.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';

class _FakeNotesApiService extends NotesApiService {
  _FakeNotesApiService() : super(ApiClient());

  int meCalls = 0;
  int notesCalls = 0;
  String? lastRecipientId;

  @override
  Future<Response> getMe() async {
    meCalls++;
    return Response(
      requestOptions: RequestOptions(path: '/api/Auth/me'),
      statusCode: 200,
      data: <String, dynamic>{'id': 7, 'username': 'Cached User'},
    );
  }

  @override
  Future<Response> getReceivedNotes(
    String recipientId, {
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    notesCalls++;
    lastRecipientId = recipientId;
    return Response(
      requestOptions: RequestOptions(path: '/notes/$recipientId'),
      statusCode: 200,
      data: <dynamic>[],
    );
  }
}

Future<void> _pumpNotes(
  WidgetTester tester,
  _FakeNotesApiService api, {
  Key? key,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: NotesOpenBookScreen(
        key: key,
        onBackToProfile: () {},
        apiService: api,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await CurrentUserCache.clear();
  });

  tearDown(() async {
    await CurrentUserCache.clear();
  });

  testWidgets('reuses the fresh current-user cache without calling /me', (
    tester,
  ) async {
    CurrentUserCache.set(const ProfileUser(id: '7', name: 'Cached User'));
    final api = _FakeNotesApiService();

    await _pumpNotes(tester, api);

    expect(api.meCalls, 0);
    expect(api.lastRecipientId, '7');
    expect(api.notesCalls, 1);
  });

  testWidgets('joins the shared cache and does not refetch while fresh', (
    tester,
  ) async {
    final firstApi = _FakeNotesApiService();
    await _pumpNotes(tester, firstApi, key: UniqueKey());

    expect(firstApi.meCalls, 1);
    expect(CurrentUserCache.peek()?.id, '7');

    final secondApi = _FakeNotesApiService();
    await _pumpNotes(tester, secondApi, key: UniqueKey());

    expect(secondApi.meCalls, 0);
    expect(secondApi.lastRecipientId, '7');
  });

  testWidgets('refetches after cache invalidation', (tester) async {
    final firstApi = _FakeNotesApiService();
    await _pumpNotes(tester, firstApi, key: UniqueKey());
    expect(firstApi.meCalls, 1);

    CurrentUserCache.invalidate();

    final secondApi = _FakeNotesApiService();
    await _pumpNotes(tester, secondApi, key: UniqueKey());

    expect(secondApi.meCalls, 1);
  });
}
