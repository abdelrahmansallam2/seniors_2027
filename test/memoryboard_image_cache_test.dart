import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/file.dart' as fs;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniors_27/features/memoryboard/data/memoryboard_image_cache.dart';
import 'package:seniors_27/features/memoryboard/memory_model.dart';

Memory _memory(String id, {String? url}) => Memory(
  id: id,
  name: '',
  date: '',
  imageUrl: url ?? 'https://example.com/original-$id.jpg',
);

class _ControlledCache extends Fake implements BaseCacheManager {
  final List<String> requests = [];
  final Map<String, Completer<fs.File>> pending = {};
  int active = 0;
  int peak = 0;

  @override
  Future<fs.File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) {
    requests.add(url);
    active++;
    if (active > peak) peak = active;
    final future = Completer<fs.File>();
    pending[url] = future;
    return future.future.whenComplete(() => active--);
  }

  void finish(String url, {bool fail = false}) {
    final future = pending.remove(url)!;
    if (fail) {
      future.completeError(StateError('offline'));
    } else {
      future.complete(const LocalFileSystem().file('unused-test-file'));
    }
  }
}

class _DiskFiles implements FileSystem {
  _DiskFiles(io.Directory root)
    : root = const LocalFileSystem().directory(root.path);
  final fs.Directory root;

  @override
  Future<fs.File> createFile(String name) async => root.childFile(name);
}

class _SourceFiles extends FileService {
  _SourceFiles(this.bytes);
  final Uint8List bytes;
  int calls = 0;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    calls++;
    return _OriginalResponse(bytes);
  }
}

class _OriginalResponse implements FileServiceResponse {
  _OriginalResponse(this.bytes);
  final Uint8List bytes;
  @override
  Stream<List<int>> get content => Stream.value(bytes);
  @override
  int get contentLength => bytes.length;
  @override
  int get statusCode => 200;
  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 1));
  @override
  String get eTag => 'original-file';
  @override
  String get fileExtension => '.jpg';
}

void main() {
  test(
    'provider keeps the original URL and never requests a smaller image',
    () {
      final manager = _ControlledCache();
      final images = MemoryboardImageCache(cacheManager: manager);
      final provider =
          images.imageFor(_memory('1')) as CachedNetworkImageProvider;
      expect(provider.url, 'https://example.com/original-1.jpg');
      expect(provider.maxWidth, isNull);
      expect(provider.maxHeight, isNull);
      expect(provider.cacheManager, same(manager));
      expect(manager.requests, isEmpty);
    },
  );

  test('missing URLs do not initialize or request the cache', () {
    final manager = _ControlledCache();
    final images = MemoryboardImageCache(cacheManager: manager);
    expect(images.imageFor(const Memory(id: '1', name: '', date: '')), isNull);
    expect(manager.requests, isEmpty);
  });

  test(
    'prefetch uses at most two workers and cancels obsolete queued photos',
    () async {
      final manager = _ControlledCache();
      final images = MemoryboardImageCache(cacheManager: manager);
      final work = images.prefetch(List.generate(12, (i) => _memory('$i')));
      expect(manager.requests, hasLength(2));
      expect(manager.peak, 2);
      manager.finish(manager.requests.first);
      await Future<void>.delayed(Duration.zero);
      expect(manager.requests, hasLength(3));
      images.cancelPrefetch();
      for (final url in manager.pending.keys.toList()) {
        manager.finish(url);
      }
      await work;
      expect(manager.requests, hasLength(3));
      expect(manager.active, 0);
      expect(manager.peak, 2);
    },
  );

  test(
    'prefetch deduplicates URLs and a failed photo does not stop the rest',
    () async {
      final manager = _ControlledCache();
      final images = MemoryboardImageCache(cacheManager: manager);
      final work = images.prefetch([
        _memory('1'),
        _memory('1'),
        _memory('2'),
        _memory('3'),
      ]);
      expect(manager.requests, hasLength(2));
      manager.finish(manager.requests.first, fail: true);
      await Future<void>.delayed(Duration.zero);
      expect(manager.requests, hasLength(3));
      for (final url in manager.pending.keys.toList()) {
        manager.finish(url);
      }
      await work;
      expect(manager.requests.toSet(), hasLength(3));
      expect(manager.active, 0);
    },
  );

  test(
    'a replacement prefetch waits for the old two workers instead of adding more',
    () async {
      final manager = _ControlledCache();
      final images = MemoryboardImageCache(cacheManager: manager);
      final first = images.prefetch([_memory('1'), _memory('2'), _memory('3')]);
      final second = images.prefetch([_memory('4'), _memory('5')]);
      expect(manager.requests, hasLength(2));
      for (final url in manager.pending.keys.toList()) {
        manager.finish(url);
      }
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(manager.requests, hasLength(4));
      expect(
        manager.requests,
        isNot(contains('https://example.com/original-3.jpg')),
      );
      for (final url in manager.pending.keys.toList()) {
        manager.finish(url);
      }
      await second;
      expect(manager.peak, 2);
    },
  );

  test(
    'disk cache preserves exact bytes and avoids a second download after restart',
    () async {
      final root = await io.Directory.systemTemp.createTemp(
        'seniors_memory_cache_',
      );
      final source = _SourceFiles(
        Uint8List.fromList(List.generate(8192, (i) => i % 256)),
      );
      CacheManager createManager() => CacheManager(
        Config(
          'memoryboard_test',
          repo: JsonCacheInfoRepository(
            path: root.uri.resolve('index.json').toFilePath(),
          ),
          fileSystem: _DiskFiles(root),
          fileService: source,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 36,
        ),
      );
      var manager = createManager();
      try {
        const url = 'https://example.com/original.jpg';
        final concurrent = await Future.wait([
          manager.getSingleFile(url),
          manager.getSingleFile(url),
        ]);
        final first = concurrent.first;
        expect(await first.readAsBytes(), orderedEquals(source.bytes));
        expect(source.calls, 1);
        await manager.getSingleFile(url);
        expect(source.calls, 1);
        await Future<void>.delayed(Duration.zero);
        await manager.dispose();
        manager = createManager();
        final afterRestart = await manager.getSingleFile(url);
        expect(await afterRestart.readAsBytes(), orderedEquals(source.bytes));
        expect(source.calls, 1);
      } finally {
        await manager.dispose();
        final temp = io.Directory.systemTemp.absolute.uri;
        if (!root.absolute.uri.toString().startsWith(temp.toString()) ||
            !root.absolute.uri.pathSegments.any(
              (segment) => segment.startsWith('seniors_memory_cache_'),
            )) {
          throw StateError(
            'Refusing to clean a directory outside this test cache.',
          );
        }
        await root.delete(recursive: true);
      }
    },
  );
}
