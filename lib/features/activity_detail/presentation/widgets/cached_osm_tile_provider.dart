import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/logging/app_logger.dart';

/// Disk-cached OpenStreetMap tile provider with 100 MB LRU cap (PRD M3-03, NFR-03).
class CachedOsmTileProvider extends TileProvider {
  CachedOsmTileProvider({
    Dio? dio,
    Future<Directory> Function()? cacheDirectoryResolver,
    this.maxCacheBytes = 100 * 1024 * 1024,
    this.offlineOnly = false,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 10),
                headers: const <String, String>{
                  'User-Agent': 'FitTrace/1.0 (com.fittrace.app)',
                },
              ),
            ),
        _cacheDirectoryResolver =
            cacheDirectoryResolver ?? getApplicationCacheDirectory;

  final Dio _dio;
  final Future<Directory> Function() _cacheDirectoryResolver;
  final int maxCacheBytes;
  final bool offlineOnly;
  int _writesSincePrune = 0;

  @override
  bool get supportsCancelLoading => true;

  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
    final url = getTileUrl(coordinates, options);
    return _CachedOsmTileImage(
      url: url,
      coordinates: coordinates,
      dio: _dio,
      cacheDirectoryResolver: _cacheDirectoryResolver,
      cancelLoading: cancelLoading,
      offlineOnly: offlineOnly,
      onTileWritten: _maybePruneCache,
    );
  }

  void _maybePruneCache() {
    _writesSincePrune++;
    if (_writesSincePrune < 25) return;
    _writesSincePrune = 0;
    unawaited(pruneLruCache());
  }

  Future<void> pruneLruCache() async {
    try {
      final root = await _cacheDirectoryResolver();
      final tileDir = Directory(p.join(root.path, 'osm_tiles'));
      if (!await tileDir.exists()) return;

      final entries = <({File file, int size, DateTime accessed})>[];
      var totalBytes = 0;

      await for (final entity in tileDir.list()) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        totalBytes += stat.size;
        entries.add((
          file: entity,
          size: stat.size,
          accessed: stat.modified,
        ));
      }

      if (totalBytes <= maxCacheBytes) return;
      entries.sort((a, b) => a.accessed.compareTo(b.accessed));

      for (final entry in entries) {
        if (totalBytes <= maxCacheBytes) break;
        await entry.file.delete();
        totalBytes -= entry.size;
      }
    } on Object catch (e) {
      AppLogger.warn('OsmTileCache', 'Failed pruning OSM tile cache', e);
    }
  }
}

class _CachedOsmTileImage extends ImageProvider<_CachedOsmTileImage> {
  const _CachedOsmTileImage({
    required this.url,
    required this.coordinates,
    required this.dio,
    required this.cacheDirectoryResolver,
    required this.cancelLoading,
    required this.offlineOnly,
    required this.onTileWritten,
  });

  final String url;
  final TileCoordinates coordinates;
  final Dio dio;
  final Future<Directory> Function() cacheDirectoryResolver;
  final Future<void> cancelLoading;
  final bool offlineOnly;
  final VoidCallback onTileWritten;

  @override
  Future<_CachedOsmTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_CachedOsmTileImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _CachedOsmTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      scale: 1.0,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<TileCoordinates>('Coordinates', coordinates),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(ImageDecoderCallback decode) async {
    final cacheRoot = await cacheDirectoryResolver();
    final tileDir = Directory(p.join(cacheRoot.path, 'osm_tiles'));
    if (!await tileDir.exists()) {
      await tileDir.create(recursive: true);
    }
    final file = File(
      p.join(
        tileDir.path,
        '${coordinates.z}_${coordinates.x}_${coordinates.y}.png',
      ),
    );

    if (await file.exists()) {
      final cached = await file.readAsBytes();
      if (cached.isNotEmpty) {
        unawaited(_touchTileIfStale(file));
        return decode(await ui.ImmutableBuffer.fromUint8List(cached));
      }
    }

    if (offlineOnly) {
      return decode(
        await ui.ImmutableBuffer.fromUint8List(TileProvider.transparentImage),
      );
    }

    final cancelToken = CancelToken();
    unawaited(
      cancelLoading.then((_) {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('tile disposed');
        }
      }),
    );

    try {
      final response = await dio.get<List<int>>(
        url,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data != null && data.isNotEmpty) {
        final bytes = Uint8List.fromList(data);
        final temp = File('${file.path}.tmp');
        await temp.writeAsBytes(bytes, flush: true);
        await temp.rename(file.path);
        onTileWritten();
        return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      }
    } on Object {
      // Offline or cancelled -> degrade cleanly to transparent tile.
    }

    return decode(
      await ui.ImmutableBuffer.fromUint8List(TileProvider.transparentImage),
    );
  }

  Future<void> _touchTileIfStale(File file) async {
    try {
      final stat = await file.stat();
      final age = DateTime.now().difference(stat.modified);
      if (age > const Duration(hours: 1)) {
        await file.setLastModified(DateTime.now());
      }
    } on Object catch (_) {}
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CachedOsmTileImage &&
          other.coordinates == coordinates &&
          other.url == url;

  @override
  int get hashCode => Object.hash(coordinates, url);
}
