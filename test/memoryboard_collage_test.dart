import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/features/memoryboard/memory_model.dart';
import 'package:seniors_27/features/memoryboard/widgets/memoryboard_collage.dart';

class _ManualImage extends ImageProvider<_ManualImage> {
  final Completer<ImageInfo> _frame = Completer<ImageInfo>();
  int loads = 0;

  void complete(ui.Image image) => _frame.complete(ImageInfo(image: image));
  void fail() => _frame.completeError(StateError('image unavailable'));

  @override
  Future<_ManualImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _ManualImage key,
    ImageDecoderCallback decode,
  ) {
    loads++;
    return OneFrameImageStreamCompleter(_frame.future);
  }
}

List<Memory> _memories([int count = 12]) => List.generate(
  count,
  (index) => Memory(
    id: '${index + 1}',
    name: 'Senior ${index + 1}',
    date: '2026-11-16',
  ),
);

Widget _host({
  List<Memory>? memories,
  bool active = true,
  bool reduceMotion = false,
  double width = 346,
  double textScale = 1,
  ValueChanged<Memory>? onTap,
  ImageProvider Function(Memory)? imageProviderFor,
  VoidCallback? onPhotosReady,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: reduceMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: width,
            height: MemoryboardCollage.heightForWidth(width),
            child: MemoryboardCollage(
              memories: memories ?? _memories(),
              isActive: active,
              onPhotoTap: onTap ?? (_) {},
              imageProviderFor: imageProviderFor,
              onPhotosReady: onPhotosReady,
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder _card(int id) => find.byKey(ValueKey('memory_$id'));

double _opacity(WidgetTester tester, int id) => tester
    .widget<Opacity>(
      find.ancestor(of: _card(id), matching: find.byType(Opacity)).first,
    )
    .opacity;

List<int> _visible(WidgetTester tester, int count) => [
  for (var id = 1; id <= count; id++)
    if (_opacity(tester, id) > 0) id,
];

void main() {
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets(
    'only the active fully-ready board can start background prefetch',
    (tester) async {
      var ready = 0;
      void onReady() => ready++;
      await tester.pumpWidget(_host(active: false, onPhotosReady: onReady));
      await tester.pumpAndSettle();
      expect(ready, 0);
      await tester.pumpWidget(_host(onPhotosReady: onReady));
      await tester.pumpAndSettle();
      expect(ready, 1);
      await tester.pumpWidget(_host(onPhotosReady: onReady));
      await tester.pumpAndSettle();
      expect(ready, 1);
    },
  );

  testWidgets('ready photos fall from above one by one and settle', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    expect(_visible(tester, 12), isEmpty);
    await tester.pump(const Duration(milliseconds: 17));
    await tester.pump(const Duration(milliseconds: 40));
    expect(_visible(tester, 12), [1]);

    final transforms = tester.widgetList<Transform>(
      find.ancestor(of: _card(1), matching: find.byType(Transform)),
    );
    expect(transforms.any((t) => t.transform.storage[13] < -10), isTrue);
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_visible(tester, 12), hasLength(2));
    await tester.pumpAndSettle();
    expect(_visible(tester, 12), hasLength(12));
    expect(_opacity(tester, 12), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scattered placements are stable across rebuilds', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    List<Rect> placements() => [
      for (var id = 1; id <= 12; id++)
        (() {
          final p = tester.widget<Positioned>(
            find.byKey(ValueKey('memory_placement_$id')),
          );
          return Rect.fromLTWH(p.left!, p.top!, p.width!, p.height!);
        })(),
    ];
    final before = placements();
    expect(before.map((r) => r.left).toSet().length, greaterThan(3));
    expect(before.map((r) => r.top).toSet().length, greaterThan(4));
    expect(before.first.center.dx, closeTo(346 / 2, 12));
    await tester.pumpWidget(_host(memories: _memories()));
    await tester.pump();
    expect(placements(), before);
    expect(_visible(tester, 12), hasLength(12));
  });

  testWidgets(
    'slow photo does not block ready photos and each image loads once',
    (tester) async {
      final providers = List.generate(3, (_) => _ManualImage());
      ImageProvider providerFor(Memory memory) =>
          providers[int.parse(memory.id) - 1];
      await tester.pumpWidget(
        _host(memories: _memories(3), imageProviderFor: providerFor),
      );
      await tester.pumpAndSettle();
      expect(_visible(tester, 3), isEmpty);

      final image = await tester.runAsync(
        () => createTestImage(width: 16, height: 16),
      );
      providers[1].complete(image!);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(_visible(tester, 3), [2]);

      providers[0].complete(image.clone());
      providers[2].fail();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(_visible(tester, 3), [1, 2, 3]);
      expect(providers.map((p) => p.loads), everyElement(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('inactive pages wait and replay their drop when revisited', (
    tester,
  ) async {
    await tester.pumpWidget(_host(active: false));
    await tester.pumpAndSettle();
    expect(_visible(tester, 12), isEmpty);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(_visible(tester, 12), hasLength(12));
    await tester.pumpWidget(_host(active: false));
    await tester.pumpAndSettle();
    expect(_visible(tester, 12), hasLength(12));
    await tester.pumpWidget(_host());
    await tester.pump();
    expect(_visible(tester, 12), isEmpty);
    await tester.pumpAndSettle();
    expect(_visible(tester, 12), hasLength(12));
  });

  testWidgets('reduced motion reveals ready photos without a stagger or drop', (
    tester,
  ) async {
    await tester.pumpWidget(_host(reduceMotion: true));
    await tester.pump();
    expect(_visible(tester, 12), hasLength(12));
    expect(_opacity(tester, 1), 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('enabling reduced motion during a drop settles all photos', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 17));
    await tester.pump(const Duration(milliseconds: 50));
    expect(_visible(tester, 12), hasLength(1));
    await tester.pumpWidget(_host(reduceMotion: true));
    expect(_visible(tester, 12), hasLength(12));
    expect(_opacity(tester, 1), 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'photo previews remain tappable after settling, without hover effects',
    (tester) async {
      Memory? opened;
      await tester.pumpWidget(
        _host(memories: _memories(1), onTap: (memory) => opened = memory),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(MemoryboardCollage),
          matching: find.byType(MouseRegion),
        ),
        findsNothing,
      );
      await tester.tap(_card(1));
      expect(opened?.id, '1');
    },
  );

  for (final width in [232.0, 276.0, 346.0, 600.0]) {
    testWidgets(
      'collage stays inside its board at width $width and large text',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_host(width: width, textScale: 2));
        await tester.pumpAndSettle();
        for (var id = 1; id <= 12; id++) {
          final p = tester.widget<Positioned>(
            find.byKey(ValueKey('memory_placement_$id')),
          );
          expect(p.left, greaterThanOrEqualTo(0));
          expect(p.top, greaterThanOrEqualTo(0));
          expect(p.left! + p.width!, lessThanOrEqualTo(width));
          expect(
            p.top! + p.height!,
            lessThanOrEqualTo(MemoryboardCollage.heightForWidth(width)),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('disposing during the stagger cancels pending timers', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 17));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('late decoded image after disposal does not update the collage', (
    tester,
  ) async {
    final provider = _ManualImage();
    await tester.pumpWidget(
      _host(memories: _memories(1), imageProviderFor: (_) => provider),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    final image = await tester.runAsync(
      () => createTestImage(width: 16, height: 16),
    );
    provider.complete(image!);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
