import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/features/memoryboard/data/memoryboard_api_service.dart';
import 'package:seniors_27/features/memoryboard/memoryboard_screen.dart';

const _originalUrl = 'https://example.com/original-memory.jpg';

class _FakeMemoryboardApiService extends MemoryboardApiService {
  _FakeMemoryboardApiService() : super(ApiClient());

  @override
  Future<Response> getPhotos() async {
    return Response(
      requestOptions: RequestOptions(path: '/memoryboard/photos'),
      statusCode: 200,
      data: <dynamic>[
        <String, dynamic>{
          'id': 1,
          'username': 'Senior',
          'createdAt': '2026-11-14T10:00:00Z',
          'imageUrl': _originalUrl,
          'status': 'approved',
        },
      ],
    );
  }
}

void main() {
  testWidgets('memoryboard uses full-resolution image providers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemoryboardScreen(apiService: _FakeMemoryboardApiService()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    List<Image> networkImages() {
      return tester
          .widgetList<Image>(find.byType(Image))
          .where((image) => image.image is NetworkImage)
          .toList();
    }

    final gridImages = networkImages();
    expect(gridImages, isNotEmpty);
    for (final image in gridImages) {
      expect(image.image, isA<NetworkImage>());
      expect(image.image, isNot(isA<ResizeImage>()));
      expect((image.image as NetworkImage).url, _originalUrl);
    }

    final card = find.byKey(const ValueKey<String>('memory_1'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final allImages = networkImages();
    expect(allImages.length, greaterThan(gridImages.length));
    for (final image in allImages) {
      expect(image.image, isA<NetworkImage>());
      expect(image.image, isNot(isA<ResizeImage>()));
      expect((image.image as NetworkImage).url, _originalUrl);
    }
  });
}
