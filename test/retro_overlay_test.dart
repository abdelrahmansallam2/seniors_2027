import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/navigation/retro_overlay.dart';

void main() {
  testWidgets('overlay fades and scales in and dismisses from the barrier', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: TextButton(
                    onPressed: () {
                      showRetroOverlay<void>(
                        context: context,
                        builder: (_) => const Center(
                          child: Material(child: Text('overlay content')),
                        ),
                      );
                    },
                    child: const Text('open overlay'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open overlay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));

    expect(find.text('overlay content'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('overlay content'),
        matching: find.byType(FadeTransition),
      ),
      findsOneWidget,
    );
    final scale = tester.widget<ScaleTransition>(
      find.ancestor(
        of: find.text('overlay content'),
        matching: find.byType(ScaleTransition),
      ),
    );
    expect(scale.scale.value, inExclusiveRange(0.96, 1));

    final fade = tester.widget<FadeTransition>(
      find.ancestor(
        of: find.text('overlay content'),
        matching: find.byType(FadeTransition),
      ),
    );
    final curve = fade.opacity as CurvedAnimation;

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('overlay content'), findsNothing);
    expect(curve.isDisposed, isTrue);
  });

  testWidgets('overlay skips its transition with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: TextButton(
                    onPressed: () {
                      showRetroOverlay<void>(
                        context: context,
                        builder: (_) => const Center(
                          child: Material(child: Text('overlay content')),
                        ),
                      );
                    },
                    child: const Text('open overlay'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open overlay'));
    await tester.pump();

    expect(find.text('overlay content'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('overlay content'),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
  });
}
