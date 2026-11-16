import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:seniors_27/features/memoryboard/memory_model.dart';

void memoryboardTiming(String message) {
  if (kDebugMode || const bool.fromEnvironment('SENIORS_PREVIEW')) {
    debugPrint('[MemoryPerf] $message');
  }
}

class MemoryboardImageCache {
  MemoryboardImageCache({BaseCacheManager? cacheManager})
    : _injectedManager = cacheManager;

  static final CacheManager _sharedManager = CacheManager(
    Config(
      'memoryboard_originals_v1',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 36,
      fileService: _TimedFileService()..concurrentFetches = 4,
    ),
  );

  final BaseCacheManager? _injectedManager;
  int _prefetchGeneration = 0;
  Future<void>? _prefetchJob;

  BaseCacheManager get _manager => _injectedManager ?? _sharedManager;

  ImageProvider? imageFor(Memory memory) {
    final url = memory.imageUrl;
    if (url == null || url.isEmpty) return null;
    // Cache original bytes. Do not set maxWidth/maxHeight or resize the provider.
    return CachedNetworkImageProvider(url, cacheManager: _manager);
  }

  void cancelPrefetch() => _prefetchGeneration++;

  Future<void> prefetch(Iterable<Memory> memories) {
    final generation = ++_prefetchGeneration;
    final previous = _prefetchJob;
    final urls = memories
        .map((memory) => memory.imageUrl)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toSet()
        .take(12)
        .toList();
    Future<void> run() async {
      if (previous != null) await previous;
      if (generation != _prefetchGeneration) return;
      var next = 0;
      Future<void> worker() async {
        while (generation == _prefetchGeneration && next < urls.length) {
          final url = urls[next++];
          try {
            // Warm compressed source files only, not twelve full decoded bitmaps.
            await _manager.getSingleFile(url);
          } catch (_) {
            // The visible image retains its own error/placeholder handling.
          }
        }
      }

      await Future.wait(
        List.generate(math.min(2, urls.length), (_) => worker()),
      );
    }

    return _prefetchJob = run();
  }
}

class _TimedFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final watch = Stopwatch()..start();
    final response = await super.get(url, headers: headers);
    memoryboardTiming(
      'imageHeaders status=${response.statusCode} elapsedMs=${watch.elapsedMilliseconds}',
    );
    return _TimedFileResponse(response, watch);
  }
}

class _TimedFileResponse implements FileServiceResponse {
  const _TimedFileResponse(this.response, this.watch);

  final FileServiceResponse response;
  final Stopwatch watch;

  @override
  Stream<List<int>> get content async* {
    var bytes = 0;
    var completed = false;
    try {
      await for (final chunk in response.content) {
        bytes += chunk.length;
        yield chunk;
      }
      completed = true;
    } finally {
      watch.stop();
      memoryboardTiming(
        'imageTransfer bytes=$bytes elapsedMs=${watch.elapsedMilliseconds} completed=$completed',
      );
    }
  }

  @override
  int? get contentLength => response.contentLength;
  @override
  int get statusCode => response.statusCode;
  @override
  DateTime get validTill => response.validTill;
  @override
  String? get eTag => response.eTag;
  @override
  String get fileExtension => response.fileExtension;
}
