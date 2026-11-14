import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/cache/current_user_cache.dart';
import 'package:seniors_27/features/profile/data/profile_api_service.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';
import 'package:seniors_27/features/profile/profile_screen.dart';

class _FakeProfileApi extends ProfileApiService {
  _FakeProfileApi(this.user) : super(ApiClient());

  ProfileUser user;

  @override
  Future<Response> getMe() async {
    return Response(
      requestOptions: RequestOptions(path: '/api/Auth/me'),
      statusCode: 200,
      data: <String, dynamic>{
        'id': user.id,
        'username': user.name,
        'email': user.email,
        'role': user.role,
        'description': user.description,
        'gender': user.gender,
        'photoUrl': user.photoUrl,
        'points': user.points,
        'status': user.status,
        'favoriteSongEmbedUrl': user.favoriteSongEmbedUrl,
      },
    );
  }
}

void main() {
  setUp(() async {
    await CurrentUserCache.clear();
  });

  testWidgets('profile force refresh displays the saved favorite song', (
    tester,
  ) async {
    final fakeApi = _FakeProfileApi(
      const ProfileUser(id: '42', name: 'Old Name'),
    );
    Future<void> Function({bool force})? refresh;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            onOpenNotes: () {},
            profileApi: fakeApi,
            registerRefresh: (callback) => refresh = callback,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No favorite song yet.'), findsOneWidget);

    const savedSong = 'https://open.spotify.com/embed/track/saved-track';
    fakeApi.user = const ProfileUser(
      id: '42',
      name: 'New Name',
      favoriteSongEmbedUrl: savedSong,
    );

    await refresh!(force: true);
    await tester.pumpAndSettle();

    expect(find.text('No favorite song yet.'), findsNothing);
    expect(find.text('TAP TO PLAY'), findsOneWidget);
    expect(CurrentUserCache.peek()?.favoriteSongEmbedUrl, savedSong);
  });
}
