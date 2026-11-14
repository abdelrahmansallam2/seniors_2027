import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/features/dashboard/add_highlight_sheet.dart';
import 'package:seniors_27/features/dashboard/data/daily_highlights_api_service.dart';
import 'package:seniors_27/features/dashboard/models/daily_highlight.dart';

class _CapturedSubmission {
  const _CapturedSubmission({
    required this.filePath,
    required this.captionText,
    required this.captionYPercent,
    required this.mentionUserIds,
    required this.onSendProgress,
  });

  final String filePath;
  final String? captionText;
  final double? captionYPercent;
  final List<int> mentionUserIds;
  final HighlightUploadProgress? onSendProgress;
}

class _FakeMentionApi extends DailyHighlightsApiService {
  _FakeMentionApi() : super(ApiClient());

  @override
  Future<List<DailyHighlightUser>> searchUsers({
    required String query,
    int pageNumber = 1,
    int pageSize = 8,
  }) async {
    return const [DailyHighlightUser(id: 7, username: 'Sara')];
  }
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required HighlightSubmitCallback onSubmit,
  DailyHighlightsApiService? api,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final imagePath = File('assets/images/app_logo.png').absolute.path;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AddHighlightSheet(
          onHighlightSubmitted: onSubmit,
          apiService: api,
          initialImage: XFile(imagePath),
          initialImageSize: const ui.Size(1080, 1080),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _captionField => find.byType(TextField).first;

Future<void> _openCaptionEditor(WidgetTester tester) async {
  await tester.tap(find.text('Tap image to add caption'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.tap(find.text('SUBMIT HIGHLIGHT'));
  await tester.pump();
}

void main() {
  testWidgets('submits the latest caption while the editor is still focused', (
    tester,
  ) async {
    late _CapturedSubmission captured;
    final completer = Completer<void>();

    Future<void> onSubmit({
      required String filePath,
      String? captionText,
      double? captionYPercent,
      List<int> mentionUserIds = const [],
      HighlightUploadProgress? onSendProgress,
    }) async {
      captured = _CapturedSubmission(
        filePath: filePath,
        captionText: captionText,
        captionYPercent: captionYPercent,
        mentionUserIds: mentionUserIds,
        onSendProgress: onSendProgress,
      );
      await completer.future;
    }

    await _pumpSheet(tester, onSubmit: onSubmit);
    await _openCaptionEditor(tester);
    await tester.enterText(_captionField, '  مرحبا 👋\nسطر ثانٍ  ');

    await _tapSubmit(tester);

    expect(captured.captionText, 'مرحبا 👋\nسطر ثانٍ');
    expect(captured.captionYPercent, 0.5);
    expect(captured.mentionUserIds, isEmpty);
    expect(captured.filePath, endsWith('app_logo.png'));

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('whitespace-only caption is submitted as no caption', (
    tester,
  ) async {
    late _CapturedSubmission captured;

    Future<void> onSubmit({
      required String filePath,
      String? captionText,
      double? captionYPercent,
      List<int> mentionUserIds = const [],
      HighlightUploadProgress? onSendProgress,
    }) async {
      captured = _CapturedSubmission(
        filePath: filePath,
        captionText: captionText,
        captionYPercent: captionYPercent,
        mentionUserIds: mentionUserIds,
        onSendProgress: onSendProgress,
      );
    }

    await _pumpSheet(tester, onSubmit: onSubmit);
    await _openCaptionEditor(tester);
    await tester.enterText(_captionField, '   \n  ');
    await _tapSubmit(tester);

    expect(captured.captionText, isNull);
    expect(captured.captionYPercent, isNull);
  });

  testWidgets('editing an existing caption immediately submits the new text', (
    tester,
  ) async {
    late _CapturedSubmission captured;

    Future<void> onSubmit({
      required String filePath,
      String? captionText,
      double? captionYPercent,
      List<int> mentionUserIds = const [],
      HighlightUploadProgress? onSendProgress,
    }) async {
      captured = _CapturedSubmission(
        filePath: filePath,
        captionText: captionText,
        captionYPercent: captionYPercent,
        mentionUserIds: mentionUserIds,
        onSendProgress: onSendProgress,
      );
    }

    await _pumpSheet(tester, onSubmit: onSubmit);
    await _openCaptionEditor(tester);
    await tester.enterText(_captionField, 'First caption');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final imageTopLeft = tester.getTopLeft(find.byType(Image).first);
    await tester.tapAt(imageTopLeft + const Offset(12, 12));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.enterText(_captionField, '  Updated caption  ');
    await _tapSubmit(tester);

    expect(captured.captionText, 'Updated caption');
  });

  testWidgets('removing a caption does not restore the previous text', (
    tester,
  ) async {
    late _CapturedSubmission captured;

    Future<void> onSubmit({
      required String filePath,
      String? captionText,
      double? captionYPercent,
      List<int> mentionUserIds = const [],
      HighlightUploadProgress? onSendProgress,
    }) async {
      captured = _CapturedSubmission(
        filePath: filePath,
        captionText: captionText,
        captionYPercent: captionYPercent,
        mentionUserIds: mentionUserIds,
        onSendProgress: onSendProgress,
      );
    }

    await _pumpSheet(tester, onSubmit: onSubmit);
    await _openCaptionEditor(tester);
    await tester.enterText(_captionField, 'Remove me');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('highlight-remove-caption')));
    await tester.pump();
    await _tapSubmit(tester);

    expect(captured.captionText, isNull);
    expect(captured.captionYPercent, isNull);
  });

  testWidgets('selected mentions are forwarded with the caption', (
    tester,
  ) async {
    late _CapturedSubmission captured;

    Future<void> onSubmit({
      required String filePath,
      String? captionText,
      double? captionYPercent,
      List<int> mentionUserIds = const [],
      HighlightUploadProgress? onSendProgress,
    }) async {
      captured = _CapturedSubmission(
        filePath: filePath,
        captionText: captionText,
        captionYPercent: captionYPercent,
        mentionUserIds: mentionUserIds,
        onSendProgress: onSendProgress,
      );
    }

    await _pumpSheet(tester, onSubmit: onSubmit, api: _FakeMentionApi());
    await tester.enterText(find.byType(TextField).last, 'sara');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sara'));
    await tester.pump();

    await _tapSubmit(tester);

    expect(captured.mentionUserIds, [7]);
  });

  testWidgets(
    'shows byte progress, processing state, and blocks double submit',
    (tester) async {
      var submitCount = 0;
      HighlightUploadProgress? sendProgress;
      final completer = Completer<void>();

      Future<void> onSubmit({
        required String filePath,
        String? captionText,
        double? captionYPercent,
        List<int> mentionUserIds = const [],
        HighlightUploadProgress? onSendProgress,
      }) async {
        submitCount++;
        sendProgress = onSendProgress;
        onSendProgress?.call(512, 1024);
        await completer.future;
      }

      await _pumpSheet(tester, onSubmit: onSubmit);
      await _tapSubmit(tester);

      expect(submitCount, 1);
      expect(find.text('UPLOADING PHOTO 50%'), findsOneWidget);
      expect(find.text('UPLOADING...'), findsOneWidget);

      await tester.tap(find.text('UPLOADING...'));
      await tester.pump();
      expect(submitCount, 1);

      sendProgress!(1024, 1024);
      await tester.pump();
      expect(find.text('PROCESSING HIGHLIGHT...'), findsOneWidget);
      expect(find.text('PROCESSING...'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.text('SUBMIT HIGHLIGHT'), findsOneWidget);
    },
  );

  testWidgets('a failed upload keeps the photo and caption available', (
    tester,
  ) async {
    Future<void> onSubmit({
      required String filePath,
      String? captionText,
      double? captionYPercent,
      List<int> mentionUserIds = const [],
      HighlightUploadProgress? onSendProgress,
    }) async {
      throw ApiException(message: 'upload failed', statusCode: 500);
    }

    await _pumpSheet(tester, onSubmit: onSubmit);
    await _openCaptionEditor(tester);
    await tester.enterText(_captionField, 'Keep this caption');
    await _tapSubmit(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Error submitting highlight. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('SUBMIT HIGHLIGHT'), findsOneWidget);
    expect(find.text('Keep this caption'), findsWidgets);
  });

  testWidgets('progress events after disposal do not update state', (
    tester,
  ) async {
    HighlightUploadProgress? sendProgress;
    final completer = Completer<void>();

    Future<void> onSubmit({
      required String filePath,
      String? captionText,
      double? captionYPercent,
      List<int> mentionUserIds = const [],
      HighlightUploadProgress? onSendProgress,
    }) async {
      sendProgress = onSendProgress;
      await completer.future;
    }

    await _pumpSheet(tester, onSubmit: onSubmit);
    await _tapSubmit(tester);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    sendProgress!(100, 100);
    completer.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
