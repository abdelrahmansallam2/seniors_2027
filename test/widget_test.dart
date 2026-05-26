import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/auth/login_email_screen.dart';
import 'package:seniors_27/features/app_shell/main_app_shell.dart';
import 'package:seniors_27/main.dart';
import 'package:seniors_27/shared/widgets/app_logo.dart';
import 'package:seniors_27/shared/widgets/retro_bottom_nav.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';

void main() {
  testWidgets('validates and completes the authentication flow', (
    tester,
  ) async {
    await tester.pumpWidget(const SeniorsApp());

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('ONE YEAR,\nA MILLION'), findsNothing);
    expect(find.text('MEMORIES'), findsNothing);
    expect(find.text('LOGIN'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('ONE YEAR,\nA MILLION'), findsOneWidget);
    expect(find.text('MEMORIES'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);

    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(find.text('STEP 1 / 5'), findsOneWidget);
    expect(find.text('EMAIL IS REQUIRED.'), findsNothing);

    await tester.tap(find.text('SEND OTP'));
    await tester.pumpAndSettle();
    expect(find.text('EMAIL IS REQUIRED.'), findsOneWidget);
    expect(find.text('ENTER OTP'), findsNothing);

    await tester.enterText(find.byType(TextField), 'bad-email');
    await tester.pump();
    expect(find.text('ENTER A VALID EMAIL ADDRESS.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'senior@example.com');
    await tester.pump();
    expect(find.text('ENTER A VALID EMAIL ADDRESS.'), findsNothing);

    await tester.tap(find.text('SEND OTP'));
    await tester.pump(const Duration(milliseconds: 510));
    expect(
      find.text('OTP sent successfully. Please check your email.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pumpAndSettle();
    expect(find.text('ENTER OTP'), findsOneWidget);
    expect(find.text('STEP 2 / 5'), findsOneWidget);
    expect(find.text('OTP IS REQUIRED.'), findsNothing);

    await tester.tap(find.text('VERIFY'));
    await tester.pumpAndSettle();
    expect(find.text('OTP IS REQUIRED.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    expect(find.text('OTP MUST BE EXACTLY 6 DIGITS.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(find.text('OTP MUST BE EXACTLY 6 DIGITS.'), findsNothing);

    await tester.tap(find.text('VERIFY'));
    await tester.pumpAndSettle();
    expect(find.text('USERNAME'), findsAtLeastNWidgets(1));
    expect(find.text('STEP 3 / 5'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('USERNAME IS REQUIRED.'), findsOneWidget);
    expect(find.text('GENDER'), findsNothing);

    await tester.enterText(find.byType(TextField), 'AB');
    await tester.pump();
    expect(
      find.text('USERNAME MUST BE AT LEAST 3 CHARACTERS.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'SAM');
    await tester.pump();
    expect(find.text('USERNAME MUST BE AT LEAST 3 CHARACTERS.'), findsNothing);

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('GENDER'), findsOneWidget);
    expect(find.text('STEP 4 / 5'), findsOneWidget);
    expect(find.text('SELECT A GENDER TO CONTINUE.'), findsNothing);

    BoxDecoration optionDecoration(Key key) {
      final option = tester.widget<AnimatedContainer>(find.byKey(key));
      return option.decoration! as BoxDecoration;
    }

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('SELECT A GENDER TO CONTINUE.'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);

    await tester.tap(find.text('MALE'));
    await tester.pumpAndSettle();
    expect(find.text('SELECT A GENDER TO CONTINUE.'), findsNothing);
    expect(
      optionDecoration(const Key('male_gender_option')).color,
      AppColors.cyan,
    );
    expect(
      optionDecoration(const Key('female_gender_option')).color,
      AppColors.paper,
    );

    await tester.tap(find.text('FEMALE'));
    await tester.pumpAndSettle();
    expect(
      optionDecoration(const Key('male_gender_option')).color,
      AppColors.paper,
    );
    expect(
      optionDecoration(const Key('female_gender_option')).color,
      AppColors.pink,
    );

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('BUILT TO BE'), findsOneWidget);
    expect(find.text('REMEMBERED'), findsOneWidget);
  });

  testWidgets('main shell navigates between yearbook sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainAppShell()));

    Finder tab(String label) => find.descendant(
      of: find.byType(RetroBottomNav),
      matching: find.text(label),
    );

    expect(find.text('Dashboard'), findsOneWidget);

    await tester.tap(tab('SENIORS'));
    await tester.pumpAndSettle();
    expect(find.text('Senior Directory'), findsOneWidget);

    await tester.tap(tab('MEMORY'));
    await tester.pumpAndSettle();
    expect(find.text('Memoryboard'), findsOneWidget);

    await tester.tap(tab('BOARD'));
    await tester.pumpAndSettle();
    expect(find.text('Leaderboard'), findsOneWidget);

    await tester.tap(tab('PROFILE'));
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);

    await tester.ensureVisible(find.text('OPEN FULL BOOK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN FULL BOOK'));
    await tester.pumpAndSettle();
    expect(find.text('Open Book'), findsOneWidget);

    await tester.tap(tab('PROFILE'));
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
  });

  testWidgets('email approval responses stay on the email step', (
    tester,
  ) async {
    const cases = <EmailAuthStatus, String>{
      EmailAuthStatus.pendingApproval:
          'Your request is waiting for admin approval. Please try again after approval.',
      EmailAuthStatus.deletedOrInactive:
          'This account request is no longer active. Please contact the admin or submit a new request.',
      EmailAuthStatus.rejected:
          'Your request was rejected. Please contact the admin.',
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginEmailScreen(otpRequester: (_) async => entry.key),
        ),
      );
      await tester.enterText(find.byType(TextField), 'senior@example.com');
      await tester.tap(find.text('SEND OTP'));
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('ENTER OTP'), findsNothing);
      expect(
        find.text(
          'Approval still pending. Your OTP expired, request a new OTP from Email.',
        ),
        findsNothing,
      );
    }
  });

  testWidgets('email request disables repeated submission while loading', (
    tester,
  ) async {
    final completer = Completer<EmailAuthStatus>();
    var requestCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginEmailScreen(
          otpRequester: (_) {
            requestCount++;
            return completer.future;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'senior@example.com');
    await tester.tap(find.text('SEND OTP'));
    await tester.pump();

    expect(find.text('SENDING...'), findsOneWidget);
    await tester.tap(find.text('SENDING...'));
    await tester.pump();
    expect(requestCount, 1);

    completer.complete(EmailAuthStatus.pendingApproval);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your request is waiting for admin approval. Please try again after approval.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('retro buttons flash yellow and depress while pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RetroButton(label: 'Next', onPressed: () {}),
        ),
      ),
    );

    BoxDecoration decoration() {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(RetroButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return container.decoration! as BoxDecoration;
    }

    expect(decoration().color, AppColors.paper);
    expect(decoration().boxShadow, isNotEmpty);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('NEXT')));
    await tester.pump(const Duration(milliseconds: 160));

    expect(decoration().color, AppColors.paper);
    expect(decoration().boxShadow!.single.offset, const Offset(7, 9));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('NEXT')),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(decoration().color, AppColors.yellowWarm);
    expect(decoration().boxShadow, isEmpty);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 120));

    expect(decoration().color, AppColors.paper);
    expect(decoration().boxShadow!.single.offset, const Offset(7, 9));

    await mouse.moveTo(const Offset(20, 400));
    await tester.pump(const Duration(milliseconds: 160));

    expect(decoration().boxShadow!.single.offset, const Offset(5, 6));
  });
}
