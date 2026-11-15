import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/cache/current_user_cache.dart';
import 'package:seniors_27/features/notes/data/notes_api_service.dart';
import 'package:seniors_27/features/notes/notes_open_book_screen.dart';
import 'package:seniors_27/shared/widgets/note_card.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';

Map<String, dynamic> _note(int id, {int senderId = 3}) => {
  'id': id,
  'content': 'Note $id',
  'createdAt': DateTime.utc(
    2026,
    11,
    1,
  ).add(Duration(minutes: id)).toIso8601String(),
  'sender': {'id': senderId, 'username': 'Senior'},
  'recipient': {'id': 7, 'username': 'Me'},
  'reactions': <dynamic>[],
  'canDelete': true,
};

List<Map<String, dynamic>> _notes(int count, {int start = 1}) =>
    List.generate(count, (index) => _note(start + index));

Response<dynamic> _response(Object? data) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/api/Notes/received/test'),
  statusCode: 200,
  data: data,
);

Response<dynamic> _page(
  List<Map<String, dynamic>> items, {
  int? totalCount,
  int? totalPages,
}) => _response({
  'items': items,
  'totalCount': ?totalCount,
  'totalPages': ?totalPages,
});

class _NotesApi extends NotesApiService {
  _NotesApi(this.page) : super(ApiClient());

  final Future<Response<dynamic>> Function(int page) page;
  Future<Response<dynamic>> Function()? me;
  Future<Response<dynamic>> Function()? reaction;
  Future<Response<dynamic>> Function()? deletion;
  final requestedPages = <int>[];
  final recipients = <String>[];
  int reactionCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Response<dynamic>> getMe() async =>
      me != null ? await me!() : _response({'id': 7, 'username': 'Me'});

  @override
  Future<Response<dynamic>> getReceivedNotes(
    String recipientId, {
    int pageNumber = 1,
    int pageSize = 50,
  }) {
    recipients.add(recipientId);
    requestedPages.add(pageNumber);
    return page(pageNumber);
  }

  @override
  Future<Response<dynamic>> addReaction(String noteId, String reactionType) {
    reactionCalls++;
    return reaction!();
  }

  @override
  Future<Response<dynamic>> deleteNote(String noteId) {
    deleteCalls++;
    return deletion!();
  }
}

Future<void> _pump(
  WidgetTester tester,
  _NotesApi api, {
  String? userId,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: NotesOpenBookScreen(
        onBackToProfile: () {},
        openedFromProfile: true,
        readOnly: userId != null,
        userId: userId,
        apiService: api,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  setUp(CurrentUserCache.clear);
  tearDown(CurrentUserCache.clear);

  testWidgets('renders populated pages using the live response structure', (
    tester,
  ) async {
    final api = _NotesApi(
      (page) async => _page(
        page == 1 ? _notes(20) : _notes(2, start: 21),
        totalCount: 22,
        totalPages: 2,
      ),
    );

    await _pump(tester, api);

    expect(api.requestedPages, [1, 2]);
    expect(find.byType(NoteCard), findsNWidgets(22));
    expect(find.text('Note 22'), findsOneWidget);
    expect(find.textContaining('Error:'), findsNothing);
  });

  testWidgets('keeps loaded notes visible when a later page is rate limited', (
    tester,
  ) async {
    final api = _NotesApi((page) async {
      if (page == 2) {
        throw ApiException(
          message: 'Too many requests. Please wait.',
          statusCode: 429,
        );
      }
      return _page(_notes(20), totalCount: 21, totalPages: 2);
    });

    await _pump(tester, api);

    expect(api.requestedPages, [1, 2]);
    expect(find.byType(NoteCard), findsNWidgets(20));
    expect(
      find.textContaining('Too many requests. Please wait.'),
      findsOneWidget,
    );
    expect(find.text('RETRY'), findsOneWidget);
  });

  testWidgets('retry recovers remaining pages and clears the warning', (
    tester,
  ) async {
    var failMore = true;
    final api = _NotesApi((page) async {
      if (page == 2 && failMore) {
        throw ApiException(
          message: 'The server is taking too long to respond.',
        );
      }
      return _page(
        page == 1 ? _notes(20) : _notes(1, start: 21),
        totalCount: 21,
        totalPages: 2,
      );
    });
    await _pump(tester, api);
    expect(find.byType(NoteCard), findsNWidgets(20));

    failMore = false;
    await tester.ensureVisible(find.text('RETRY'));
    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();

    expect(api.requestedPages, [1, 2, 1, 2]);
    expect(find.byType(NoteCard), findsNWidgets(21));
    expect(find.textContaining('Error:'), findsNothing);
  });

  testWidgets(
    'stops when the server repeats a page instead of requesting forever',
    (tester) async {
      final api = _NotesApi((page) async {
        if (page > 2) throw StateError('Repeated page was not detected.');
        return _page(_notes(20), totalCount: 60, totalPages: 3);
      });

      await _pump(tester, api);

      expect(api.requestedPages, [1, 2]);
      expect(find.byType(NoteCard), findsNWidgets(20));
      expect(find.textContaining('Failed to load notes.'), findsOneWidget);
    },
  );

  testWidgets('respects totalPages when the final page is full', (
    tester,
  ) async {
    final api = _NotesApi((page) async {
      if (page > 1) throw StateError('Unexpected extra request.');
      return _page(_notes(20), totalPages: 1);
    });

    await _pump(tester, api);

    expect(api.requestedPages, [1]);
    expect(find.byType(NoteCard), findsNWidgets(20));
  });

  testWidgets(
    'never requests an empty recipient when the profile cannot load',
    (tester) async {
      final api = _NotesApi((_) async => _response(<dynamic>[]))
        ..me = () async => throw ApiException(
          message: 'Connection timed out. Please try again.',
          data: {'private': 'server internals'},
        );

      await _pump(tester, api);

      expect(api.requestedPages, isEmpty);
      expect(find.textContaining('Connection timed out.'), findsOneWidget);
      expect(find.textContaining('server internals'), findsNothing);
    },
  );

  testWidgets('does not issue a request for a missing profile ID', (
    tester,
  ) async {
    final api = _NotesApi((_) async => _response(<dynamic>[]))
      ..me = () async => _response({'username': 'Missing ID'});

    await _pump(tester, api);

    expect(api.recipients, isEmpty);
    expect(find.text('RETRY'), findsOneWidget);
  });

  testWidgets('leaving during a load stops further page requests', (
    tester,
  ) async {
    final pending = Completer<Response<dynamic>>();
    final api = _NotesApi((_) => pending.future);
    await _pump(tester, api, settle: false);
    expect(api.requestedPages, [1]);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    pending.complete(_page(_notes(20), totalPages: 2));
    await tester.pumpAndSettle();

    expect(api.requestedPages, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unknown current-user identity does not grant visited-book delete actions',
    (tester) async {
      final api = _NotesApi((_) async => _page([_note(1, senderId: 23)]))
        ..me = () async =>
            throw ApiException(message: 'Temporary profile failure.');

      await _pump(tester, api, userId: '23');

      expect(api.recipients, ['23']);
      expect(tester.widget<NoteCard>(find.byType(NoteCard)).canDelete, isFalse);
    },
  );

  testWidgets(
    'reaction completion after leaving cannot update disposed state',
    (tester) async {
      final pending = Completer<Response<dynamic>>();
      final api = _NotesApi((_) async => _page([_note(1)]))
        ..reaction = () => pending.future;
      await _pump(tester, api);

      tester.widget<NoteCard>(find.byType(NoteCard)).onLove!();
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      pending.complete(_response(_note(1)));
      await tester.pumpAndSettle();

      expect(api.reactionCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('delete completion after leaving cannot update disposed state', (
    tester,
  ) async {
    final pending = Completer<Response<dynamic>>();
    final api = _NotesApi((_) async => _page([_note(1)]))
      ..deletion = () => pending.future;
    await _pump(tester, api);

    tester.widget<NoteCard>(find.byType(NoteCard)).onDelete!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();
    expect(api.deleteCalls, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    pending.complete(_response(null));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reaction failures never display raw exception details', (
    tester,
  ) async {
    final api = _NotesApi((_) async => _page([_note(1)]))
      ..reaction = () async => throw StateError('private server internals');
    await _pump(tester, api);

    tester.widget<NoteCard>(find.byType(NoteCard)).onLove!();
    await tester.pumpAndSettle();

    expect(find.text('Failed to react. Please retry.'), findsOneWidget);
    expect(find.textContaining('private server internals'), findsNothing);
  });

  testWidgets('rapid retries start only one pending request', (tester) async {
    final pending = Completer<Response<dynamic>>();
    var retrying = false;
    final api = _NotesApi((_) async {
      if (!retrying) throw ApiException(message: 'Temporary failure.');
      return pending.future;
    });
    await _pump(tester, api);
    final retry = tester.widget<RetroButton>(
      find.ancestor(of: find.text('RETRY'), matching: find.byType(RetroButton)),
    );

    retrying = true;
    retry.onPressed!();
    retry.onPressed!();
    await tester.pump();
    expect(api.requestedPages, [1, 1]);
    pending.complete(_page([_note(1)]));
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsOneWidget);
  });

  testWidgets('unexpected response data is not presented as an empty book', (
    tester,
  ) async {
    final api = _NotesApi(
      (_) async => _response({'unexpected': 'private response details'}),
    );

    await _pump(tester, api);

    expect(find.text('RETRY'), findsOneWidget);
    expect(find.text('No notes yet.'), findsNothing);
    expect(find.textContaining('private response details'), findsNothing);
  });
}
