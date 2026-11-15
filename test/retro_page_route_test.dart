import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';
import 'package:seniors_27/core/navigation/retro_page_route.dart';

void main() {
  test('retro route exposes motion timing and route settings', () {
    final route = RetroPageRoute<String>(
      settings: const RouteSettings(name: 'details'),
      fullscreenDialog: true,
      builder: (_) => const SizedBox.shrink(),
    );

    expect(route.settings.name, 'details');
    expect(route.fullscreenDialog, isTrue);
    expect(route.transitionDuration, RetroMotion.pageForward);
    expect(route.reverseTransitionDuration, RetroMotion.pageReverse);
  });

  testWidgets('retro route preserves its pop result', (tester) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<String>(
                  RetroPageRoute<String>(
                    settings: const RouteSettings(name: 'details'),
                    builder: (context) {
                      return Scaffold(
                        body: Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop('done'),
                            child: const Text('pop result'),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('pop result'), findsOneWidget);

    final curve = tester
        .widgetList<FadeTransition>(
          find.ancestor(
            of: find.text('pop result'),
            matching: find.byType(FadeTransition),
          ),
        )
        .map((fade) => fade.opacity)
        .whereType<CurvedAnimation>()
        .single;

    await tester.tap(find.text('pop result'));
    await tester.pumpAndSettle();
    expect(result, 'done');
    expect(curve.isDisposed, isTrue);
  });

  testWidgets('retro route skips its transition with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  RetroPageRoute<void>(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('reduced route')),
                    ),
                  ),
                );
              },
              child: const Text('open reduced'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open reduced'));
    await tester.pumpAndSettle();

    expect(find.text('reduced route'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('reduced route'),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('reduced route'),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
  });
}
