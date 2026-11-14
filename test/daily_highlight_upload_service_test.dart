import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_constants.dart';
import 'package:seniors_27/features/dashboard/data/daily_highlights_api_service.dart';

class _CapturingApiClient extends ApiClient {
  _CapturingApiClient() : super(dio: Dio());

  String? path;
  FormData? formData;

  @override
  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
  }) async {
    this.path = path;
    this.formData = formData;
    onSendProgress?.call(100, 100);
    return Response<T>(
      data:
          <String, dynamic>{
                'id': 42,
                'photoUrl': 'https://example.com/highlight.png',
                'createdAt': '2026-11-14T09:00:00Z',
                'captionText': 'مرحبا 👋\nسطر ثانٍ',
                'captionYPercent': 0.42,
              }
              as T,
      statusCode: 201,
      requestOptions: RequestOptions(path: path),
    );
  }
}

Future<File> _temporaryPhoto() async {
  final directory = await Directory.systemTemp.createTemp(
    'highlight-upload-test-',
  );
  addTearDown(() => directory.delete(recursive: true));
  final file = File('${directory.path}${Platform.pathSeparator}photo.png');
  await file.writeAsBytes(List<int>.generate(2048, (index) => index % 255));
  return file;
}

void main() {
  test('uploads the original photo with caption and mention fields', () async {
    final file = await _temporaryPhoto();
    final originalBytes = await file.readAsBytes();
    final client = _CapturingApiClient();
    final service = DailyHighlightsApiService(client);
    (int, int)? progress;

    final result = await service.upload(
      filePath: file.path,
      captionText: '  مرحبا 👋\nسطر ثانٍ  ',
      captionYPercent: 0.42,
      mentionUserIds: const [5, 5, 9],
      onSendProgress: (sent, total) => progress = (sent, total),
    );

    expect(client.path, ApiConstants.dailyHighlightsUpload);
    final formData = client.formData!;
    final fields = Map.fromEntries(formData.fields);
    expect(fields['captionText'], 'مرحبا 👋\nسطر ثانٍ');
    expect(fields['captionYPercent'], '0.42');
    expect(
      formData.fields
          .where((entry) => entry.key == 'mentionUserIds')
          .map((entry) => entry.value),
      ['5', '9'],
    );
    expect(formData.files, hasLength(1));
    expect(formData.files.single.key, 'photo');
    expect(formData.files.single.value.length, originalBytes.length);
    expect(progress, (100, 100));

    expect(result.id, '42');
    expect(result.captionText, 'مرحبا 👋\nسطر ثانٍ');
    expect(result.captionYPercent, 0.42);
    expect(await file.readAsBytes(), originalBytes);
  });

  test(
    'does not send stale caption fields when the caption is removed',
    () async {
      final file = await _temporaryPhoto();
      final client = _CapturingApiClient();
      final service = DailyHighlightsApiService(client);

      await service.upload(
        filePath: file.path,
        captionText: '   ',
        captionYPercent: 0.8,
      );

      final formData = client.formData!;
      expect(
        formData.fields.where((entry) => entry.key == 'captionText'),
        isEmpty,
      );
      expect(
        formData.fields.where((entry) => entry.key == 'captionYPercent'),
        isEmpty,
      );
    },
  );
}
