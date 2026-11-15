import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/features/app_shell/main_app_shell.dart';
import 'package:seniors_27/shared/widgets/retro_bottom_nav.dart';

class _TestPage extends StatefulWidget {
  const _TestPage(this.index);

  final int index;

  @override
  State<_TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<_TestPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('tab ${widget.index}'),
          SizedBox(
            width: 200,
            child: TextField(
              key: ValueKey<String>('field_${widget.index}'),
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }
}

Finder _tab(String label) {
  return find.descendant(
    of: find.byType(RetroBottomNav),
    matching: find.text(label),
  );
}

TickerMode _ticker(WidgetTester tester, int index) {
  return tester.widget<TickerMode>(
    find.byKey(ValueKey<String>('tab_ticker_$index'), skipOffstage: false),
  );
}

void main() {
  testWidgets('a non-default initial tab is created before being shown', (
    tester,
  ) async {
    final created = List<int>.filled(5, 0);
    final builders = List<Widget Function()>.generate(
      5,
      (index) => () {
        created[index]++;
        return _TestPage(index);
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MainAppShell(initialIndex: 4, screenBuilders: builders),
      ),
    );

    expect(find.text('tab 4').hitTestable(), findsOneWidget);
    expect(created, [1, 0, 0, 0, 1]);
    expect(_ticker(tester, 4).enabled, isTrue);
  });

  testWidgets('tabs stay lazy and preserve state across switches', (
    tester,
  ) async {
    final created = List<int>.filled(5, 0);
    final builders = List<Widget Function()>.generate(
      5,
      (index) => () {
        created[index]++;
        return _TestPage(index);
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: MainAppShell(screenBuilders: builders)),
    );

    expect(created, [1, 0, 0, 0, 0]);
    expect(_ticker(tester, 0).enabled, isTrue);
    expect(_ticker(tester, 1).enabled, isFalse);

    await tester.enterText(
      find.byKey(const ValueKey<String>('field_0')),
      'remember me',
    );
    await tester.tap(_tab('SENIORS'));
    await tester.pumpAndSettle();

    expect(created, [1, 1, 0, 0, 0]);
    expect(_ticker(tester, 0).enabled, isFalse);
    expect(_ticker(tester, 1).enabled, isTrue);

    await tester.tap(_tab('DASH'));
    await tester.pumpAndSettle();

    expect(created, [1, 1, 0, 0, 0]);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('field_0')),
    );
    expect(field.controller?.text, 'remember me');
  });

  testWidgets('rapid tab switches settle on the final tab', (tester) async {
    final created = List<int>.filled(5, 0);
    final builders = List<Widget Function()>.generate(
      5,
      (index) => () {
        created[index]++;
        return _TestPage(index);
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: MainAppShell(screenBuilders: builders)),
    );

    for (final label in ['SENIORS', 'MEMORY', 'BOARD', 'PROFILE', 'SENIORS']) {
      await tester.tap(_tab(label));
      await tester.pump(const Duration(milliseconds: 16));
    }

    await tester.pumpAndSettle();

    expect(find.text('tab 1').hitTestable(), findsOneWidget);
    expect(created, [1, 1, 1, 1, 1]);
    expect(_ticker(tester, 1).enabled, isTrue);
    expect(_ticker(tester, 4).enabled, isFalse);
  });

  testWidgets('reduced motion makes tab changes immediate', (tester) async {
    final builders = List<Widget Function()>.generate(
      5,
      (index) =>
          () => _TestPage(index),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MainAppShell(screenBuilders: builders),
        ),
      ),
    );

    await tester.tap(_tab('SENIORS'));
    await tester.pump();

    final opacity = tester.widget<Opacity>(
      find.byKey(const ValueKey<String>('tab_transition_opacity')),
    );
    expect(opacity.opacity, 1);
    expect(find.text('tab 1').hitTestable(), findsOneWidget);
  });

  testWidgets('system back animates the previous tab without recreating it', (
    tester,
  ) async {
    final created = List<int>.filled(5, 0);
    final builders = List<Widget Function()>.generate(
      5,
      (index) => () {
        created[index]++;
        return _TestPage(index);
      },
    );
    await tester.pumpWidget(
      MaterialApp(home: MainAppShell(screenBuilders: builders)),
    );
    await tester.tap(_tab('SENIORS'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('field_1')),
      'keep this draft',
    );
    await tester.tap(_tab('MEMORY'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();
    final opacity = tester.widget<Opacity>(
      find.byKey(const ValueKey<String>('tab_transition_opacity')),
    );
    expect(opacity.opacity, 0.9);
    await tester.pumpAndSettle();

    expect(find.text('tab 1').hitTestable(), findsOneWidget);
    expect(created, [1, 1, 1, 0, 0]);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('field_1')),
    );
    expect(field.controller?.text, 'keep this draft');
    expect(_ticker(tester, 1).enabled, isTrue);
  });

  testWidgets('tab controller is disposed while animating', (tester) async {
    final builders = List<Widget Function()>.generate(
      5,
      (index) =>
          () => _TestPage(index),
    );

    await tester.pumpWidget(
      MaterialApp(home: MainAppShell(screenBuilders: builders)),
    );

    await tester.tap(_tab('SENIORS'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
