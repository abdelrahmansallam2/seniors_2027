import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';
import 'package:seniors_27/shared/widgets/retro_entrance.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Center(child: child),
    ),
  );
}

double _opacity(WidgetTester tester) {
  return tester.widget<Opacity>(find.byType(Opacity)).opacity;
}

void main() {
  testWidgets('entrance fades, lifts, and scales once', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RetroEntrance(
          duration: Duration(milliseconds: 100),
          child: Text('card'),
        ),
      ),
    );

    expect(_opacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 40));
    expect(_opacity(tester), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 80));
    expect(_opacity(tester), 1);

    await tester.pumpWidget(
      _wrap(
        const RetroEntrance(
          duration: Duration(milliseconds: 100),
          child: Text('card'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(_opacity(tester), 1);
  });

  testWidgets('entrance respects its stagger delay', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RetroEntrance(
          delay: Duration(milliseconds: 100),
          duration: Duration(milliseconds: 100),
          child: Text('delayed'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 60));
    expect(_opacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 80));
    expect(_opacity(tester), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 80));
    expect(_opacity(tester), 1);
  });

  testWidgets('entrance completes immediately with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const RetroEntrance(child: Text('reduced')), reduceMotion: true),
    );

    expect(_opacity(tester), 1);
  });

  testWidgets('entrance can be disposed while animating', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RetroEntrance(
          duration: Duration(milliseconds: 500),
          child: Text('card'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('stagger delay is capped', () {
    expect(RetroMotion.staggerDelay(-1), Duration.zero);
    expect(RetroMotion.staggerDelay(0), Duration.zero);
    expect(RetroMotion.staggerDelay(1), const Duration(milliseconds: 40));
    expect(RetroMotion.staggerDelay(100), const Duration(milliseconds: 200));
  });

  testWidgets('a bounce curve does not push opacity outside its valid range', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const RetroEntrance(
          duration: Duration(milliseconds: 100),
          curve: Curves.easeOutBack,
          child: Text('bounce'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    expect(tester.takeException(), isNull);
    expect(_opacity(tester), inInclusiveRange(0, 1));
    await tester.pumpAndSettle();
  });
}
