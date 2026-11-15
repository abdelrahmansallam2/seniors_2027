import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/shared/widgets/retro_image_reveal.dart';

class _ManualImageProvider extends ImageProvider<_ManualImageProvider> {
  _ManualImageProvider(this.id);

  final String id;
  final Completer<ImageInfo> _completer = Completer<ImageInfo>();
  int loads = 0;

  void complete(ui.Image image) {
    if (!_completer.isCompleted) {
      _completer.complete(ImageInfo(image: image));
    }
  }

  @override
  Future<_ManualImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_ManualImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _ManualImageProvider key,
    ImageDecoderCallback decode,
  ) {
    loads++;
    return OneFrameImageStreamCompleter(_completer.future);
  }

  @override
  bool operator ==(Object other) {
    return other is _ManualImageProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class _ImmediateImageProvider extends ImageProvider<_ImmediateImageProvider> {
  _ImmediateImageProvider(this.id, this.image);

  final String id;
  final ui.Image image;

  @override
  Future<_ImmediateImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_ImmediateImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _ImmediateImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return _ImmediateImageCompleter(image);
  }

  @override
  bool operator ==(Object other) {
    return other is _ImmediateImageProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class _ImmediateImageCompleter extends ImageStreamCompleter {
  _ImmediateImageCompleter(ui.Image image) {
    setImage(ImageInfo(image: image));
  }
}

class _ErrorImageProvider extends ImageProvider<_ErrorImageProvider> {
  _ErrorImageProvider(this.id);

  final String id;

  @override
  Future<_ErrorImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_ErrorImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _ErrorImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(StateError('load failed')),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _ErrorImageProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

Widget _wrap(Widget child, {bool reduceMotion = false}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Center(child: SizedBox(width: 120, height: 120, child: child)),
    ),
  );
}

Widget _image(
  ImageProvider provider, {
  Widget? placeholder,
  ImageErrorWidgetBuilder? errorBuilder,
  bool gaplessPlayback = false,
}) {
  return RetroImageReveal(
    image: provider,
    fit: BoxFit.cover,
    width: 120,
    height: 120,
    gaplessPlayback: gaplessPlayback,
    placeholder:
        placeholder ??
        const SizedBox(
          key: Key('placeholder'),
          width: 120,
          height: 120,
          child: Text('loading'),
        ),
    errorBuilder: errorBuilder,
  );
}

Opacity _revealOpacity(WidgetTester tester) {
  return tester.widget<Opacity>(find.byType(Opacity));
}

Future<ui.Image> _testImage(WidgetTester tester) async {
  final image = await tester.runAsync(
    () => createTestImage(width: 16, height: 16),
  );
  return image!;
}

void main() {
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('reveals a decoded frame without using a timer', (tester) async {
    final provider = _ManualImageProvider('delayed');
    await tester.pumpWidget(_wrap(_image(provider)));

    expect(find.byKey(const Key('placeholder')), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
    expect(provider.loads, 1);

    provider.complete(await _testImage(tester));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.byType(Image), findsOneWidget);
    expect(_revealOpacity(tester).opacity, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(_revealOpacity(tester).opacity, 1);
  });

  testWidgets('shows synchronously cached images immediately', (tester) async {
    final provider = _ImmediateImageProvider(
      'cached',
      await _testImage(tester),
    );
    await tester.pumpWidget(_wrap(_image(provider)));
    await tester.pump();

    expect(find.byType(Opacity), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('keeps image identity and does not resolve again on rebuild', (
    tester,
  ) async {
    final provider = _ManualImageProvider('rebuild');

    await tester.pumpWidget(_wrap(_image(provider)));
    expect(provider.loads, 1);

    provider.complete(await _testImage(tester));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_wrap(_image(provider)));
    await tester.pump();

    expect(provider.loads, 1);
    expect(_revealOpacity(tester).opacity, 1);
  });

  testWidgets('uses the error placeholder when loading fails', (tester) async {
    final provider = _ErrorImageProvider('error');
    await tester.pumpWidget(
      _wrap(_image(provider, errorBuilder: (_, _, _) => const Text('failed'))),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('failed'), findsOneWidget);
  });

  testWidgets('completes immediately with reduced motion', (tester) async {
    final provider = _ManualImageProvider('reduced');
    await tester.pumpWidget(_wrap(_image(provider), reduceMotion: true));

    provider.complete(await _testImage(tester));
    await tester.pump();
    await tester.pump();

    expect(_revealOpacity(tester).opacity, 1);
  });

  testWidgets('disposes its controller when removed mid reveal', (
    tester,
  ) async {
    final provider = _ManualImageProvider('dispose');
    await tester.pumpWidget(_wrap(_image(provider)));

    provider.complete(await _testImage(tester));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves Flutter image quality and the original provider', (
    tester,
  ) async {
    final provider = _ManualImageProvider('quality');
    await tester.pumpWidget(_wrap(_image(provider)));

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, same(provider));
    expect(image.image, isNot(isA<ResizeImage>()));
    expect(image.filterQuality, FilterQuality.medium);
  });

  testWidgets('loaded image is not sized by its old placeholder', (
    tester,
  ) async {
    final provider = _ManualImageProvider('intrinsic-size');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RetroImageReveal(
            image: provider,
            width: 80,
            height: 40,
            placeholder: const SizedBox(width: 240, height: 200),
          ),
        ),
      ),
    );

    provider.complete(await _testImage(tester));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(Opacity)), const Size(80, 40));
  });

  testWidgets('changing image providers reveals only the new decoded frame', (
    tester,
  ) async {
    final first = _ManualImageProvider('first');
    final second = _ManualImageProvider('second');
    await tester.pumpWidget(_wrap(_image(first)));
    first.complete(await _testImage(tester));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_wrap(_image(second)));
    expect(find.byKey(const Key('placeholder')), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);

    second.complete(await _testImage(tester));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(_revealOpacity(tester).opacity, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(_revealOpacity(tester).opacity, 1);
    expect(first.loads, 1);
    expect(second.loads, 1);
  });

  testWidgets('gapless playback keeps the previous image visible', (
    tester,
  ) async {
    final first = _ManualImageProvider('gapless-first');
    final second = _ManualImageProvider('gapless-second');
    await tester.pumpWidget(_wrap(_image(first, gaplessPlayback: true)));
    first.complete(await _testImage(tester));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_wrap(_image(second, gaplessPlayback: true)));
    expect(find.byKey(const Key('placeholder')), findsNothing);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);

    second.complete(await _testImage(tester));
    await tester.pump();
    await tester.pump();
    expect(_revealOpacity(tester).opacity, 1);
  });

  testWidgets('gapless playback also preserves synchronously cached frames', (
    tester,
  ) async {
    final first = _ImmediateImageProvider(
      'cached-gapless',
      await _testImage(tester),
    );
    final second = _ManualImageProvider('after-cached');
    await tester.pumpWidget(_wrap(_image(first, gaplessPlayback: true)));
    await tester.pump();

    await tester.pumpWidget(_wrap(_image(second, gaplessPlayback: true)));
    expect(find.byKey(const Key('placeholder')), findsNothing);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);

    second.complete(await _testImage(tester));
    await tester.pump();
    await tester.pump();
    expect(_revealOpacity(tester).opacity, 1);
  });

  testWidgets('enabling reduced motion finishes an in-progress reveal', (
    tester,
  ) async {
    final provider = _ManualImageProvider('toggle-reduced');
    await tester.pumpWidget(_wrap(_image(provider)));
    provider.complete(await _testImage(tester));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(_revealOpacity(tester).opacity, inExclusiveRange(0, 1));

    await tester.pumpWidget(_wrap(_image(provider), reduceMotion: true));
    expect(_revealOpacity(tester).opacity, 1);
  });
}
