import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seniors_27/core/navigation/retro_page_route.dart';
import 'package:seniors_27/core/storage/token_storage.dart';
import 'package:seniors_27/core/theme/app_theme.dart';
import 'package:seniors_27/features/app_shell/main_app_shell.dart';
import 'package:seniors_27/features/auth/login_email_screen.dart';
import 'package:seniors_27/features/splash/splash_screen.dart';
import 'package:seniors_27/shared/widgets/app_logo.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

// Cross the 1.5-second animation's completion boundary by one millisecond.
const _openingComplete = Duration(milliseconds: 1501);

class _EmptySecureStorage implements SecureStorage {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}

class _PushObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is RetroPageRoute) pushes++;
  }
}

Future<String?> _guest() async => null;

Widget _host({
  Future<String?> Function() tokenReader = _guest,
  bool reduceMotion = false,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1,
  NavigatorObserver? observer,
}) => RepaintBoundary(
  key: const ValueKey('splash_preview'),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: const bool.fromEnvironment('CAPTURE_SPLASH')
        ? AppTheme.retro.copyWith(
            textTheme: AppTheme.retro.textTheme.apply(fontFamily: 'Roboto'),
          )
        : AppTheme.retro,
    navigatorObservers: [?observer],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduceMotion,
        padding: padding,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: SplashScreen(tokenReader: tokenReader),
  ),
);

Future<void> _pumpSplash(
  WidgetTester tester, {
  Future<String?> Function() tokenReader = _guest,
  bool reduceMotion = false,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1,
  NavigatorObserver? observer,
}) async {
  await tester.pumpWidget(
    _host(
      tokenReader: tokenReader,
      reduceMotion: reduceMotion,
      padding: padding,
      textScale: textScale,
      observer: observer,
    ),
  );
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/images/app_logo.png'),
      tester.element(find.byType(AppLogo)),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _finishGuestSplash(WidgetTester tester) async {
  await tester.pump(_openingComplete);
  await tester.pump(const Duration(milliseconds: 750));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

T _logoAncestor<T extends Widget>(WidgetTester tester) => tester.widget<T>(
  find
      .descendant(
        of: find.byKey(const ValueKey('splash_logo')),
        matching: find.byType(T),
      )
      .first,
);

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_SPLASH')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('splash_preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File('build/splash-preview/$name.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_SPLASH')) return;
    final config = File('.dart_tool/package_config.json').absolute;
    final json =
        jsonDecode(await config.readAsString()) as Map<String, dynamic>;
    final flutter = (json['packages'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((package) => package['name'] == 'flutter');
    final packageDirectory = Directory.fromUri(
      config.uri.resolve(flutter['rootUri'] as String),
    );
    final fontDirectory = packageDirectory.parent.parent.uri.resolve(
      'bin/cache/artifacts/material_fonts/',
    );
    final loader = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold', 'black']) {
      loader.addFont(
        File.fromUri(
          fontDirectory.resolve('roboto-$weight.ttf'),
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await loader.load();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.resetCache();
    await TokenStorage(secure: _EmptySecureStorage()).readToken();
    TestWidgetsFlutterBinding.ensureInitialized()
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets(
    'opening holds a centered logo and stickers without title or login',
    (tester) async {
      await _pumpSplash(tester);
      await tester.pump(const Duration(milliseconds: 1100));

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(RetroSticker), findsNWidgets(2));
      expect(find.text('ONE YEAR,\nA MILLION'), findsNothing);
      expect(find.byType(RetroButton), findsNothing);
      expect(_logoAncestor<ScaleTransition>(tester).scale.value, 1);
      expect(_logoAncestor<RotationTransition>(tester).turns.value, 0);
      final canvas = tester.getRect(
        find.byKey(const ValueKey('splash_canvas')),
      );
      final logo = tester.getRect(find.byKey(const ValueKey('splash_logo')));
      expect(logo.center, canvas.center);

      await tester.pump(const Duration(milliseconds: 399));
      expect(find.byKey(const ValueKey('memory_splash_stage')), findsNothing);
      await tester.pump(const Duration(milliseconds: 2));
      expect(find.byKey(const ValueKey('memory_splash_stage')), findsOneWidget);
    },
  );

  testWidgets('one settled logo glides to the corner without popping again', (
    tester,
  ) async {
    await _pumpSplash(tester);
    await tester.pump(const Duration(milliseconds: 1501));
    final canvas = tester.getRect(find.byKey(const ValueKey('splash_canvas')));
    final initial = tester.getRect(find.byKey(const ValueKey('splash_logo')));
    expect(initial.center, canvas.center);

    await tester.pump(const Duration(milliseconds: 200));
    final moving = tester.getRect(find.byKey(const ValueKey('splash_logo')));
    expect(moving.top, lessThan(initial.top));
    expect(moving.width, lessThan(initial.width));
    expect(find.byType(AppLogo), findsOneWidget);
    expect(_logoAncestor<ScaleTransition>(tester).scale.value, 1);

    await tester.pump(const Duration(milliseconds: 250));
    final settled = tester.getRect(find.byKey(const ValueKey('splash_logo')));
    expect(settled.topLeft, canvas.topLeft + const Offset(20, 15));
    expect(settled.size, const Size(120, 120));
    expect(find.text('LOGIN').hitTestable(), findsNothing);
  });

  testWidgets('login appears last and cannot be tapped during its entrance', (
    tester,
  ) async {
    final observer = _PushObserver();
    await _pumpSplash(tester, observer: observer);
    await tester.pump(const Duration(milliseconds: 1501));
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('ONE YEAR,\nA MILLION'), findsOneWidget);
    expect(find.text('LOGIN').hitTestable(), findsNothing);
    expect(observer.pushes, 0);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LOGIN').hitTestable(), findsOneWidget);
  });

  testWidgets('login still works after returning from the email screen', (
    tester,
  ) async {
    final observer = _PushObserver();
    await _pumpSplash(tester, observer: observer);
    await _finishGuestSplash(tester);
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginEmailScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginEmailScreen), findsOneWidget);
    expect(observer.pushes, 2);
  });

  testWidgets('repeated login taps push only one route', (tester) async {
    final observer = _PushObserver();
    await _pumpSplash(tester, observer: observer);
    await _finishGuestSplash(tester);
    final button = tester.widget<RetroButton>(find.byType(RetroButton));
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();

    expect(observer.pushes, 1);
    expect(find.byType(LoginEmailScreen), findsOneWidget);
  });

  testWidgets('a saved session shows both stages then navigates exactly once', (
    tester,
  ) async {
    final observer = _PushObserver();
    var reads = 0;
    await _pumpSplash(
      tester,
      observer: observer,
      tokenReader: () async {
        reads++;
        return 'saved-session';
      },
    );
    await tester.pump(const Duration(milliseconds: 1499));
    expect(find.byType(MainAppShell), findsNothing);
    expect(find.text('LOGIN'), findsNothing);
    await tester.pump(const Duration(milliseconds: 2));
    expect(find.byKey(const ValueKey('memory_splash_stage')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1150));
    await tester.pumpAndSettle();

    expect(find.byType(MainAppShell), findsOneWidget);
    expect(observer.pushes, 1);
    expect(reads, 1);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets(
    'slow session checks reserve the button area without a login flash',
    (tester) async {
      final pending = Completer<String?>();
      await _pumpSplash(tester, tokenReader: () => pending.future);
      await tester.pump(_openingComplete);
      await tester.pump(const Duration(milliseconds: 1150));
      expect(find.text('LOGIN'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete(null);
      await tester.pump();
      await tester.pump();
      expect(find.text('LOGIN').hitTestable(), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('LOGIN').hitTestable(), findsOneWidget);
    },
  );

  testWidgets('failed session reads offer login without exposing the error', (
    tester,
  ) async {
    await _pumpSplash(
      tester,
      tokenReader: () async => throw StateError('private storage details'),
    );
    await _finishGuestSplash(tester);

    expect(find.text('LOGIN').hitTestable(), findsOneWidget);
    expect(find.textContaining('private storage details'), findsNothing);
  });

  testWidgets('an empty saved token is treated as a guest session', (
    tester,
  ) async {
    await _pumpSplash(tester, tokenReader: () async => ' \t ');
    await _finishGuestSplash(tester);

    expect(find.text('LOGIN').hitTestable(), findsOneWidget);
    expect(find.byType(MainAppShell), findsNothing);
  });

  testWidgets('enabling reduced motion finishes an active stage transition', (
    tester,
  ) async {
    await _pumpSplash(tester);
    await tester.pump(_openingComplete);
    await tester.pump(const Duration(milliseconds: 200));
    final moving = tester.getRect(find.byKey(const ValueKey('splash_logo')));
    expect(moving.width, greaterThan(120));

    await tester.pumpWidget(_host(reduceMotion: true));
    await tester.pump();

    final logo = tester.getRect(find.byKey(const ValueKey('splash_logo')));
    expect(logo.size, const Size(120, 120));
    expect(find.text('LOGIN').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion keeps the opening duration but skips movement', (
    tester,
  ) async {
    await _pumpSplash(tester, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.byKey(const ValueKey('memory_splash_stage')), findsNothing);
    expect(_logoAncestor<ScaleTransition>(tester).scale.value, 1);
    expect(_logoAncestor<RotationTransition>(tester).turns.value, 0);
    expect(_logoAncestor<FadeTransition>(tester).opacity.value, 1);

    await tester.pump(const Duration(milliseconds: 201));
    expect(find.byKey(const ValueKey('memory_splash_stage')), findsOneWidget);
    expect(find.text('LOGIN').hitTestable(), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'opening pauses in the background instead of skipping on resume',
    (tester) async {
      await _pumpSplash(tester);
      await tester.pump(const Duration(milliseconds: 300));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 4));
      expect(find.byKey(const ValueKey('memory_splash_stage')), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1201));
      expect(find.byKey(const ValueKey('memory_splash_stage')), findsOneWidget);
    },
  );

  testWidgets(
    'late session results do not navigate while the app is backgrounded',
    (tester) async {
      final pending = Completer<String?>();
      final observer = _PushObserver();
      await _pumpSplash(
        tester,
        tokenReader: () => pending.future,
        observer: observer,
      );
      await tester.pump(_openingComplete);
      await tester.pump(const Duration(milliseconds: 1150));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      pending.complete('saved-session');
      await tester.pump();
      expect(observer.pushes, 0);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(observer.pushes, 1);
      expect(find.byType(MainAppShell), findsOneWidget);
    },
  );

  testWidgets('late session completion after disposal cannot navigate', (
    tester,
  ) async {
    final pending = Completer<String?>();
    final observer = _PushObserver();
    await _pumpSplash(
      tester,
      tokenReader: () => pending.future,
      observer: observer,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete('saved-session');
    await tester.pumpAndSettle();

    expect(observer.pushes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing during the memory transition cleans up all tickers', (
    tester,
  ) async {
    await _pumpSplash(tester);
    await tester.pump(_openingComplete);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(844, 390),
  ]) {
    testWidgets(
      'splash remains usable at $size with safe areas and larger text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pumpSplash(
          tester,
          padding: const EdgeInsets.only(top: 32, bottom: 20),
          textScale: 1.6,
        );
        final canvas = tester.getRect(
          find.byKey(const ValueKey('splash_canvas')),
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('splash_logo'))).center,
          canvas.center,
        );
        await _finishGuestSplash(tester);
        await tester.ensureVisible(find.text('LOGIN'));
        await tester.pumpAndSettle();

        expect(find.text('LOGIN').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('portrait splash has a stable logo and matching memory layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpSplash(tester);
    await tester.pump(const Duration(milliseconds: 1100));
    await _capture(tester, 'opening');
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pump(const Duration(milliseconds: 200));
    await _capture(tester, 'transition');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 400));
    await _capture(tester, 'memory');

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.byType(RetroSticker), findsNWidgets(2));
    expect(find.text('LOGIN').hitTestable(), findsOneWidget);
  });
}
