import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/features/memoryboard/data/memoryboard_api_service.dart';
import 'package:seniors_27/features/memoryboard/memoryboard_screen.dart';
import 'package:seniors_27/features/memoryboard/widgets/memoryboard_collage.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';

class _PagedMemoryboardApiService extends MemoryboardApiService {
  _PagedMemoryboardApiService({this.count = 25}) : super(ApiClient());

  int count;
  int calls = 0;

  @override
  Future<Response> getPhotos() async {
    calls++;
    return Response(
      requestOptions: RequestOptions(path: '/memoryboard/photos'),
      statusCode: 200,
      data: List<Map<String, dynamic>>.generate(
        count,
        (index) => <String, dynamic>{
          'id': index + 1,
          'username': 'Senior ${index + 1}',
          'createdAt': '2026-11-14T10:00:00Z',
          'status': 'approved',
        },
      ),
    );
  }
}

Future<void> _openBoard(
  WidgetTester tester,
  _PagedMemoryboardApiService api, {
  bool reduceMotion = false,
  void Function(Future<void> Function({bool force}))? registerRefresh,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: const ValueKey('memoryboard_preview'),
          child: RetroGridBackground(
            child: MemoryboardScreen(
              apiService: api,
              registerRefresh: registerRefresh,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_MEMORYBOARD')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('memoryboard_preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File('build/memoryboard-preview/$name.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  testWidgets(
    'outgoing photos stay visible while the finger drags the next board',
    (tester) async {
      await _openBoard(tester, _PagedMemoryboardApiService());
      final pages = find.byKey(const ValueKey('memoryboard_pages'));
      final gesture = await tester.startGesture(tester.getCenter(pages));
      await gesture.moveBy(const Offset(-25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-210, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final outgoing = find.byKey(const ValueKey('memoryboard_page_0'));
      final incoming = find.byKey(const ValueKey('memoryboard_page_1'));
      expect(tester.widget<MemoryboardCollage>(outgoing).isActive, isTrue);
      expect(tester.widget<MemoryboardCollage>(incoming).isActive, isFalse);
      final photo = find.byKey(const ValueKey('memory_1'));
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: photo, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, 1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(tester.widget<MemoryboardCollage>(incoming).isActive, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('horizontal swipes change boards without another API request', (
    tester,
  ) async {
    final api = _PagedMemoryboardApiService();
    await _openBoard(tester, api);
    expect(find.text('1 / 3'), findsOneWidget);
    await _capture(tester, 'first-board');

    final pages = find.byKey(const ValueKey('memoryboard_pages'));
    await tester.drag(pages, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('memory_13')), findsOneWidget);
    await _capture(tester, 'second-board');

    await tester.drag(pages, const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(api.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paging is swipe-only and the page counter follows each board', (
    tester,
  ) async {
    await _openBoard(tester, _PagedMemoryboardApiService());
    expect(find.text('NEXT'), findsNothing);
    expect(find.text('PREV.'), findsNothing);
    expect(find.text('ADD MEMORY'), findsOneWidget);
    final pages = find.byKey(const ValueKey('memoryboard_pages'));
    await tester.drag(pages, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('memoryboard_pages')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);

    await tester.drag(pages, const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('vertical scrolling over photos does not change boards', (
    tester,
  ) async {
    await _openBoard(tester, _PagedMemoryboardApiService());
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final before = scroll.position.pixels;
    await tester.drag(
      find.byKey(const ValueKey('memoryboard_pages')),
      const Offset(0, -160),
    );
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(before));
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('page limits stay valid through rapid swipes', (tester) async {
    await _openBoard(tester, _PagedMemoryboardApiService(count: 13));
    final pages = find.byKey(const ValueKey('memoryboard_pages'));
    for (var i = 0; i < 4; i++) {
      await tester.fling(pages, const Offset(-300, 0), 1600);
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.fling(pages, const Offset(300, 0), 1600);
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh clamps a removed board to the remaining page', (
    tester,
  ) async {
    final api = _PagedMemoryboardApiService();
    late Future<void> Function({bool force}) refresh;
    await _openBoard(tester, api, registerRefresh: (value) => refresh = value);
    final pages = find.byKey(const ValueKey('memoryboard_pages'));
    await tester.drag(pages, const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.drag(pages, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);

    api.count = 1;
    await refresh(force: true);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('memory_1')), findsOneWidget);
    expect(find.text('1 / 1'), findsNothing);
    expect(tester.widget<PageView>(pages).controller!.page, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty board after refresh removes the pager safely', (
    tester,
  ) async {
    final api = _PagedMemoryboardApiService(count: 13);
    late Future<void> Function({bool force}) refresh;
    await _openBoard(tester, api, registerRefresh: (value) => refresh = value);
    api.count = 0;
    await refresh(force: true);
    await tester.pumpAndSettle();
    expect(find.text('No memories yet.'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe-only paging remains usable with reduced motion', (
    tester,
  ) async {
    await _openBoard(
      tester,
      _PagedMemoryboardApiService(count: 13),
      reduceMotion: true,
    );
    expect(find.text('NEXT'), findsNothing);
    expect(find.text('PREV.'), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('memoryboard_pages')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
