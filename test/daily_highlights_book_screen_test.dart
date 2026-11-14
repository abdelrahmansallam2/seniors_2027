import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/features/dashboard/daily_highlights_book_screen.dart';
import 'package:seniors_27/features/dashboard/data/daily_highlights_api_service.dart';
import 'package:seniors_27/features/dashboard/models/daily_highlight.dart';

class _FakeDailyHighlightsApi extends DailyHighlightsApiService {
  _FakeDailyHighlightsApi() : super(ApiClient());

  int deleteCount = 0;
  Completer<void>? deleteCompleter;

  @override
  Future<void> delete(String highlightId) {
    deleteCount++;
    return deleteCompleter?.future ?? Future.value();
  }
}

DailyHighlight _highlight(String id) {
  return DailyHighlight(
    id: id,
    photoUrl: 'https://example.com/highlight-$id.png',
    isOwnedByCurrentUser: true,
    user: const DailyHighlightUser(username: 'Tester'),
  );
}

Future<void> _openBook(
  WidgetTester tester, {
  required List<DailyHighlight> highlights,
  required DailyHighlightsApiService api,
  required VoidCallback onDashboardRefresh,
  int initialIndex = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DailyHighlightsBookScreen(
                      highlights: highlights,
                      onDashboardRefresh: onDashboardRefresh,
                      initialIndex: initialIndex,
                      apiService: api,
                    ),
                  ),
                );
              },
              child: const Text('OPEN HIGHLIGHTS'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('OPEN HIGHLIGHTS'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('deleting the final highlight pops without a range error', (
    tester,
  ) async {
    final api = _FakeDailyHighlightsApi();
    var refreshCount = 0;

    await _openBook(
      tester,
      highlights: [_highlight('1')],
      api: api,
      onDashboardRefresh: () => refreshCount++,
    );

    expect(find.text('Tester'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(api.deleteCount, 1);
    expect(refreshCount, 1);
    expect(find.byType(DailyHighlightsBookScreen), findsNothing);
    expect(find.text('OPEN HIGHLIGHTS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty highlights renders the empty state safely', (
    tester,
  ) async {
    final api = _FakeDailyHighlightsApi();

    await tester.pumpWidget(
      MaterialApp(
        home: DailyHighlightsBookScreen(
          highlights: const [],
          onDashboardRefresh: () {},
          apiService: api,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No highlights yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('out-of-range initial index is clamped safely', (tester) async {
    final api = _FakeDailyHighlightsApi();

    await _openBook(
      tester,
      highlights: [_highlight('1')],
      api: api,
      onDashboardRefresh: () {},
      initialIndex: 99,
    );

    expect(find.text('Tester'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the caption returned by the server', (tester) async {
    final api = _FakeDailyHighlightsApi();
    final highlight = DailyHighlight.fromJson({
      'id': 42,
      'photoUrl': 'https://example.com/highlight.png',
      'isOwnedByCurrentUser': true,
      'user': {'username': 'Tester'},
      'captionText': 'مرحبا 👋\nسطر ثانٍ',
      'captionYPercent': 0.42,
    });

    expect(highlight.captionYPercent, 0.42);
    await _openBook(
      tester,
      highlights: [highlight],
      api: api,
      onDashboardRefresh: () {},
    );

    expect(find.text('مرحبا 👋\nسطر ثانٍ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing during deletion does not update disposed state', (
    tester,
  ) async {
    final api = _FakeDailyHighlightsApi();
    api.deleteCompleter = Completer<void>();

    await _openBook(
      tester,
      highlights: [_highlight('1'), _highlight('2')],
      api: api,
      onDashboardRefresh: () {},
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(DailyHighlightsBookScreen), findsNothing);

    api.deleteCompleter!.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
