import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seniors_27/core/auth/session_manager.dart';
import 'package:seniors_27/core/cache/current_user_cache.dart';
import 'package:seniors_27/core/storage/token_storage.dart';
import 'package:seniors_27/features/auth/login_email_screen.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';

class _MapSecureStorage implements SecureStorage {
  final _store = <String, String>{};
  int deleteCount = 0;

  @override
  Future<String?> read(String key) => Future.value(_store[key]);

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deleteCount++;
    _store.remove(key);
  }
}

class _LoginPushCounter extends NavigatorObserver {
  int loginPushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == SessionManager.loginRouteName) {
      loginPushes++;
    }
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    TokenStorage.resetCache();
  });

  late _MapSecureStorage secure;
  late TokenStorage tokenStorage;
  late SessionManager sessionManager;

  setUp(() async {
    secure = _MapSecureStorage();
    tokenStorage = TokenStorage(secure: secure);
    sessionManager = SessionManager(tokenStorage: tokenStorage);
    await CurrentUserCache.clear();
  });

  Future<void> seedSession() async {
    await tokenStorage.saveToken('session-token');
    CurrentUserCache.set(const ProfileUser(id: '42', name: 'S'));
  }

  Future<void> pumpHostApp(
    WidgetTester tester, {
    List<NavigatorObserver> observers = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: sessionManager.navigatorKey,
        navigatorObservers: observers,
        routes: {
          SessionManager.loginRouteName: (_) => const LoginEmailScreen(),
        },
        home: const Scaffold(body: Center(child: Text('host'))),
      ),
    );
  }

  group('SessionManager', () {
    testWidgets('single 401 clears token and cache once and navigates once', (
      tester,
    ) async {
      await seedSession();
      expect(await tokenStorage.readToken(), 'session-token');
      expect(CurrentUserCache.peek(), isNotNull);

      final counter = _LoginPushCounter();
      await pumpHostApp(tester, observers: [counter]);

      await sessionManager.handleUnauthorized();
      await tester.pumpAndSettle();

      expect(secure.deleteCount, 1);
      expect(await tokenStorage.readToken(), isNull);
      expect(CurrentUserCache.peek(), isNull);
      expect(counter.loginPushes, 1);
      expect(find.byType(LoginEmailScreen), findsOneWidget);
    });

    testWidgets('simultaneous 401s run one cleanup and one navigation', (
      tester,
    ) async {
      await seedSession();
      final counter = _LoginPushCounter();
      await pumpHostApp(tester, observers: [counter]);

      final first = sessionManager.handleUnauthorized();
      expect(sessionManager.isHandlingUnauthorized, isTrue);
      final second = sessionManager.handleUnauthorized();
      final third = sessionManager.handleUnauthorized();

      await Future.wait([first, second, third]);
      await tester.pumpAndSettle();

      expect(secure.deleteCount, 1);
      expect(await tokenStorage.readToken(), isNull);
      expect(CurrentUserCache.peek(), isNull);
      expect(counter.loginPushes, 1);
      expect(find.byType(LoginEmailScreen), findsOneWidget);
    });

    test(
      'navigator unavailable still completes cleanup without crashing',
      () async {
        await seedSession();

        await sessionManager.handleUnauthorized();

        expect(secure.deleteCount, 1);
        expect(await tokenStorage.readToken(), isNull);
        expect(CurrentUserCache.peek(), isNull);
      },
    );

    testWidgets('does not push another login when already on login', (
      tester,
    ) async {
      await seedSession();
      final counter = _LoginPushCounter();
      await pumpHostApp(tester, observers: [counter]);

      await sessionManager.handleUnauthorized();
      await tester.pumpAndSettle();
      expect(counter.loginPushes, 1);
      expect(find.byType(LoginEmailScreen), findsOneWidget);

      await sessionManager.handleUnauthorized();
      await tester.pumpAndSettle();
      expect(counter.loginPushes, 1);
      expect(find.byType(LoginEmailScreen), findsOneWidget);
    });

    testWidgets('resetAfterSuccessfulLogin clears lock and keeps saved token', (
      tester,
    ) async {
      await seedSession();
      final counter = _LoginPushCounter();
      await pumpHostApp(tester, observers: [counter]);

      await sessionManager.handleUnauthorized();
      await tester.pumpAndSettle();

      sessionManager.resetAfterSuccessfulLogin();
      expect(sessionManager.isHandlingUnauthorized, isFalse);

      await tokenStorage.saveToken('new-token');
      expect(await tokenStorage.readToken(), 'new-token');

      await sessionManager.handleUnauthorized();
      await tester.pumpAndSettle();
      expect(counter.loginPushes, 2);
      expect(await tokenStorage.readToken(), isNull);
    });

    testWidgets('manual logout reuses cleanup and navigates once', (
      tester,
    ) async {
      await seedSession();
      final counter = _LoginPushCounter();
      await pumpHostApp(tester, observers: [counter]);

      await sessionManager.logout();
      await tester.pumpAndSettle();

      expect(secure.deleteCount, 1);
      expect(await tokenStorage.readToken(), isNull);
      expect(CurrentUserCache.peek(), isNull);
      expect(counter.loginPushes, 1);
      expect(find.byType(LoginEmailScreen), findsOneWidget);
    });
  });
}
