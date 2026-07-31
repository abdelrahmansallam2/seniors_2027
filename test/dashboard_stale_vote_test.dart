import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/features/dashboard/dashboard_screen.dart';
import 'package:seniors_27/features/dashboard/data/daily_highlights_api_service.dart';
import 'package:seniors_27/features/dashboard/data/dashboard_api_service.dart';
import 'package:seniors_27/features/dashboard/models/announcement.dart';
import 'package:seniors_27/features/dashboard/models/poll_option.dart';

PollOption _option(
  String label, {
  int voteCount = 0,
  bool currentUser = false,
}) {
  return PollOption(
    label: label,
    voteCount: voteCount,
    voters: currentUser
        ? const [
            PollVoter(
              username: 'me',
              votedAt: '2026-07-31T10:00:00Z',
              isCurrentUser: true,
            ),
          ]
        : const [],
  );
}

Announcement _announcement(Poll poll) {
  return Announcement(
    id: 'ann-1',
    title: 'Welcome',
    body: 'Hello seniors',
    createdByUsername: 'Admin',
    createdAt: '2026-07-31T09:00:00Z',
    poll: poll,
  );
}

Response<dynamic> _emptyResponse() {
  return Response<dynamic>(
    data: <dynamic>[],
    statusCode: 200,
    requestOptions: RequestOptions(path: '/empty'),
  );
}

class _FakeDashboardApiService extends DashboardApiService {
  _FakeDashboardApiService() : super(ApiClient());

  final List<Future<List<Announcement>>> announcementsQueue = [];
  final List<Future<Response<dynamic>>> eventsQueue = [];
  Announcement? voteResult;
  bool failNextEvents = false;
  int announcementsCalls = 0;
  int eventsCalls = 0;
  int voteCalls = 0;

  @override
  Future<List<Announcement>> getAnnouncements() {
    announcementsCalls++;
    return announcementsQueue.removeAt(0);
  }

  @override
  Future<Response<dynamic>> getEvents() {
    eventsCalls++;
    if (failNextEvents) {
      failNextEvents = false;
      return Future.error(ApiException(message: 'fail'));
    }
    return eventsQueue.removeAt(0);
  }

  @override
  Future<Announcement> voteInPoll(String announcementId, String optionLabel) {
    voteCalls++;
    return Future.value(voteResult!);
  }
}

class _FakeHighlightsApiService extends DailyHighlightsApiService {
  _FakeHighlightsApiService() : super(ApiClient());

  final List<Future<Response<dynamic>>> activeQueue = [];
  int activeCalls = 0;

  @override
  Future<Response<dynamic>> getActive() {
    activeCalls++;
    return activeQueue.removeAt(0);
  }
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required _FakeDashboardApiService api,
  required _FakeHighlightsApiService highlights,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DashboardScreen(
          onOpenNotes: () {},
          apiService: api,
          highlightsApiService: highlights,
        ),
      ),
    ),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'slow pre-vote announcements response cannot overwrite a newer poll vote',
    (tester) async {
      _setTallViewport(tester);

      final api = _FakeDashboardApiService();
      final highlights = _FakeHighlightsApiService();
      final preVote = _announcement(
        Poll(
          title: 'Favorite subject',
          options: [_option('Option A'), _option('Option B')],
        ),
      );

      api.announcementsQueue.add(Future.value([preVote]));
      api.failNextEvents = true;
      highlights.activeQueue.add(Future.value(_emptyResponse()));

      await _pumpDashboard(tester, api: api, highlights: highlights);
      await tester.pumpAndSettle();

      expect(find.text('Favorite subject'), findsOneWidget);

      final slowAnnouncements = Completer<List<Announcement>>();
      final slowEvents = Completer<Response<dynamic>>();
      api.announcementsQueue.add(slowAnnouncements.future);
      api.eventsQueue.add(slowEvents.future);
      highlights.activeQueue.add(Future.value(_emptyResponse()));

      await tester.tap(find.text('RETRY'));
      await tester.pumpAndSettle();

      final voted = _announcement(
        Poll(
          title: 'Favorite subject',
          options: [
            _option('Option A', voteCount: 1, currentUser: true),
            _option('Option B'),
          ],
        ),
      );
      api.voteResult = voted;

      await tester.ensureVisible(find.text('Option A'));
      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(find.text('1 VOTE - 100%'), findsOneWidget);

      slowAnnouncements.complete([preVote]);
      slowEvents.complete(_emptyResponse());
      await tester.pumpAndSettle();

      expect(find.text('1 VOTE - 100%'), findsOneWidget);
      expect(find.text('Favorite subject'), findsOneWidget);
      expect(api.announcementsCalls, 2);
      expect(api.eventsCalls, 2);
      expect(api.voteCalls, 1);
      expect(highlights.activeCalls, 2);
      expect(find.text('Loading...'), findsNothing);
      expect(find.text('UPCOMING_EVENTS'), findsOneWidget);
      expect(find.text('DAILY_HIGHLIGHTS'), findsOneWidget);
    },
  );

  testWidgets(
    'announcements response applies normally when the version has not changed',
    (tester) async {
      _setTallViewport(tester);

      final api = _FakeDashboardApiService();
      final highlights = _FakeHighlightsApiService();
      final announcement = _announcement(
        Poll(
          title: 'Favorite subject',
          options: [_option('Option A'), _option('Option B')],
        ),
      );

      api.announcementsQueue.add(Future.value([announcement]));
      api.eventsQueue.add(Future.value(_emptyResponse()));
      highlights.activeQueue.add(Future.value(_emptyResponse()));

      await _pumpDashboard(tester, api: api, highlights: highlights);
      await tester.pumpAndSettle();

      expect(find.text('Favorite subject'), findsOneWidget);
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(api.announcementsCalls, 1);
      expect(find.text('Loading...'), findsNothing);
    },
  );

  testWidgets('duplicate Dashboard batches remain blocked while one is in '
      'flight', (tester) async {
    _setTallViewport(tester);

    final api = _FakeDashboardApiService();
    final highlights = _FakeHighlightsApiService();
    final preVote = _announcement(
      Poll(
        title: 'Favorite subject',
        options: [_option('Option A'), _option('Option B')],
      ),
    );

    api.announcementsQueue.add(Future.value([preVote]));
    api.failNextEvents = true;
    highlights.activeQueue.add(Future.value(_emptyResponse()));

    await _pumpDashboard(tester, api: api, highlights: highlights);
    await tester.pumpAndSettle();

    final slowAnnouncements = Completer<List<Announcement>>();
    final slowEvents = Completer<Response<dynamic>>();
    api.announcementsQueue.add(slowAnnouncements.future);
    api.eventsQueue.add(slowEvents.future);
    highlights.activeQueue.add(Future.value(_emptyResponse()));

    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      logs.add(message ?? '');
    };
    try {
      await tester.tap(find.text('RETRY'));
      await tester.tap(find.text('RETRY'));
      await tester.pumpAndSettle();

      expect(api.announcementsCalls, 2);
      expect(
        logs.any((l) => l.contains('blocked duplicate trigger=retry')),
        isTrue,
      );
    } finally {
      debugPrint = originalDebugPrint;
    }

    slowAnnouncements.complete([preVote]);
    slowEvents.complete(_emptyResponse());
    await tester.pumpAndSettle();

    expect(api.announcementsCalls, 2);
    expect(api.eventsCalls, 2);
    expect(find.text('Loading...'), findsNothing);
    expect(find.text('UPCOMING_EVENTS'), findsOneWidget);
  });
}
