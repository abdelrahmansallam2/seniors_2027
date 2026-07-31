import 'package:flutter_test/flutter_test.dart';

import 'package:seniors_27/core/cache/current_user_cache.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';

ProfileUser _user(String id, {String name = 'A'}) =>
    ProfileUser(id: id, name: name);

void main() {
  setUp(() async {
    await CurrentUserCache.clear();
  });

  group('CurrentUserCache', () {
    test('fetches and caches when empty', () async {
      var calls = 0;
      final user = await CurrentUserCache.get(
        fetcher: () async {
          calls++;
          return _user('1');
        },
      );
      expect(user.id, '1');
      expect(calls, 1);
    });

    test(
      'serves cached value within freshness without calling fetcher',
      () async {
        var calls = 0;
        Future<ProfileUser> fetcher() async {
          calls++;
          return _user('1');
        }

        await CurrentUserCache.get(fetcher: fetcher);
        await CurrentUserCache.get(fetcher: fetcher);
        await CurrentUserCache.get(fetcher: fetcher);

        expect(calls, 1);
      },
    );

    test('dedupes simultaneous calls into a single fetch', () async {
      var calls = 0;
      Future<ProfileUser> fetcher() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _user('1');
      }

      final results = await Future.wait([
        CurrentUserCache.get(fetcher: fetcher),
        CurrentUserCache.get(fetcher: fetcher),
        CurrentUserCache.get(fetcher: fetcher),
      ]);

      expect(calls, 1);
      expect(results.map((u) => u.id).toSet(), {'1'});
    });

    test('refetches after freshness expires', () async {
      var calls = 0;
      Future<ProfileUser> fetcher() async {
        calls++;
        return _user('$calls');
      }

      await CurrentUserCache.get(fetcher: fetcher);
      CurrentUserCache.debugSetFetchedAt(
        DateTime.now().subtract(const Duration(seconds: 61)),
      );
      final user = await CurrentUserCache.get(fetcher: fetcher);

      expect(calls, 2);
      expect(user.id, '2');
    });

    test('forceRefresh bypasses fresh cache', () async {
      var calls = 0;
      Future<ProfileUser> fetcher() async {
        calls++;
        return _user('$calls');
      }

      await CurrentUserCache.get(fetcher: fetcher);
      final user = await CurrentUserCache.get(
        fetcher: fetcher,
        forceRefresh: true,
      );

      expect(calls, 2);
      expect(user.id, '2');
    });

    test('set updates cached value', () async {
      var calls = 0;
      Future<ProfileUser> fetcher() async {
        calls++;
        return _user('1', name: 'A');
      }

      await CurrentUserCache.get(fetcher: fetcher);
      CurrentUserCache.set(_user('1', name: 'B'));

      final user = await CurrentUserCache.get(fetcher: fetcher);
      expect(calls, 1);
      expect(user.name, 'B');
    });

    test('peek returns cached user without fetching', () async {
      expect(CurrentUserCache.peek(), isNull);

      var calls = 0;
      Future<ProfileUser> fetcher() async {
        calls++;
        return _user('1');
      }

      await CurrentUserCache.get(fetcher: fetcher);
      expect(CurrentUserCache.peek()?.id, '1');
      expect(calls, 1);
    });

    test('invalidate clears the cache', () async {
      var calls = 0;
      Future<ProfileUser> fetcher() async {
        calls++;
        return _user('1');
      }

      await CurrentUserCache.get(fetcher: fetcher);
      CurrentUserCache.invalidate();
      expect(CurrentUserCache.peek(), isNull);

      await CurrentUserCache.get(fetcher: fetcher);
      expect(calls, 2);
    });

    test('clear clears the cache', () async {
      var calls = 0;
      Future<ProfileUser> fetcher() async {
        calls++;
        return _user('1');
      }

      await CurrentUserCache.get(fetcher: fetcher);
      await CurrentUserCache.clear();
      expect(CurrentUserCache.peek(), isNull);

      await CurrentUserCache.get(fetcher: fetcher);
      expect(calls, 2);
    });

    test('does not cache failed fetches', () async {
      var calls = 0;
      Future<ProfileUser> fetcher() async {
        calls++;
        if (calls == 1) throw Exception('boom');
        return _user('2');
      }

      await expectLater(
        CurrentUserCache.get(fetcher: fetcher),
        throwsA(isA<Exception>()),
      );
      expect(CurrentUserCache.peek(), isNull);

      final user = await CurrentUserCache.get(fetcher: fetcher);
      expect(calls, 2);
      expect(user.id, '2');
    });
  });
}
