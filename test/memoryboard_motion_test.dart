import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';
import 'package:seniors_27/features/memoryboard/data/memoryboard_api_service.dart';
import 'package:seniors_27/features/memoryboard/memoryboard_screen.dart';
import 'package:seniors_27/shared/widgets/retro_entrance.dart';

class _PagedMemoryboardApiService extends MemoryboardApiService {
  _PagedMemoryboardApiService() : super(ApiClient());

  @override
  Future<Response> getPhotos() async {
    return Response(
      requestOptions: RequestOptions(path: '/memoryboard/photos'),
      statusCode: 200,
      data: List<Map<String, dynamic>>.generate(
        13,
        (index) => <String, dynamic>{
          'id': index + 1,
          'username': 'Senior ${index + 1}',
          'createdAt': '2026-11-14T10:00:00Z',
          'imageUrl': 'https://example.com/memory-${index + 1}.jpg',
          'status': 'approved',
        },
      ),
    );
  }
}

void main() {
  testWidgets('memoryboard staggers visible page items and new pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemoryboardScreen(apiService: _PagedMemoryboardApiService()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstPage = tester
        .widgetList<RetroEntrance>(find.byType(RetroEntrance))
        .toList();
    expect(firstPage, hasLength(12));
    expect(firstPage.first.delay, Duration.zero);
    expect(firstPage[1].delay, RetroMotion.staggerDelay(1));
    expect(firstPage.last.delay, const Duration(milliseconds: 200));

    await tester.ensureVisible(find.text('NEXT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NEXT'));
    await tester.pump();

    final secondPage = tester
        .widgetList<RetroEntrance>(find.byType(RetroEntrance))
        .toList();
    expect(secondPage, hasLength(1));
    expect(secondPage.single.delay, Duration.zero);

    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(RetroEntrance),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, 0);

    await tester.pumpAndSettle();
    final settled = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(RetroEntrance),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(settled.opacity, 1);
  });
}
