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

Response<dynamic> _response(dynamic data) {
  return Response<dynamic>(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(path: '/empty'),
  );
}

Announcement _announcement(String title) {
  return Announcement(
    id: 'ann-1',
    title: title,
    body: 'Hello seniors',
    createdByUsername: 'Admin',
    createdAt: '2026-11-14T09:00:00Z',
  );
}

class _ControlledDashboardApi extends DashboardApiService {
  _ControlledDashboardApi() : super(ApiClient());

  final Completer<List<Announcement>> announcements =
      Completer<List<Announcement>>();
  final Completer<Response<dynamic>> events = Completer<Response<dynamic>>();
  int announcementsCalls = 0;
  int eventsCalls = 0;

  @override
  Future<List<Announcement>> getAnnouncements() {
    announcementsCalls++;
    return announcements.future;
  }

  @override
  Future<Response<dynamic>> getEvents() {
    eventsCalls++;
    return events.future;
  }

  @override
  Future<Announcement> voteInPoll(String announcementId, String optionLabel) {
    throw UnimplementedError();
  }
}

class _ControlledHighlightsApi extends DailyHighlightsApiService {
  _ControlledHighlightsApi() : super(ApiClient());

  final Completer<Response<dynamic>> active = Completer<Response<dynamic>>();
  int activeCalls = 0;

  @override
  Future<Response<dynamic>> getActive() {
    activeCalls++;
    return active.future;
  }
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required _ControlledDashboardApi api,
  required _ControlledHighlightsApi highlights,
}) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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

void main() {
  testWidgets(
    'starts independent dashboard requests together and renders each result',
    (tester) async {
      final api = _ControlledDashboardApi();
      final highlights = _ControlledHighlightsApi();

      await _pumpDashboard(tester, api: api, highlights: highlights);

      expect(api.announcementsCalls, 1);
      expect(api.eventsCalls, 1);
      expect(highlights.activeCalls, 1);

      highlights.active.complete(_response(<dynamic>[]));
      await tester.pumpAndSettle();

      expect(find.text('No highlights yet.'), findsOneWidget);
      expect(find.text('Loading...'), findsNWidgets(2));

      api.events.completeError(ApiException(message: 'events unavailable'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load data.'), findsOneWidget);
      expect(find.text('No highlights yet.'), findsOneWidget);

      api.announcements.complete([_announcement('Parallel welcome')]);
      await tester.pumpAndSettle();

      expect(find.text('Parallel welcome'), findsOneWidget);
      expect(find.text('No highlights yet.'), findsOneWidget);
      expect(find.text('Could not load data.'), findsOneWidget);
      expect(api.announcementsCalls, 1);
      expect(api.eventsCalls, 1);
      expect(highlights.activeCalls, 1);
    },
  );

  testWidgets('ignores in-flight dashboard results after disposal', (
    tester,
  ) async {
    final api = _ControlledDashboardApi();
    final highlights = _ControlledHighlightsApi();

    await _pumpDashboard(tester, api: api, highlights: highlights);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    api.announcements.complete([_announcement('Too late')]);
    api.events.complete(_response(<dynamic>[]));
    highlights.active.complete(_response(<dynamic>[]));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
