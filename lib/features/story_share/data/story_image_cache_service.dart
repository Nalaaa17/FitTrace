import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/logging/app_logger.dart';

/// Persists rendered `1080×1920` Story PNGs inside app cache and prunes
/// files older than 24 hours (`PRD §2.5`).
class StoryImageCacheService {
  StoryImageCacheService({
    Future<Directory> Function()? cacheDirectoryResolver,
  }) : _cacheDirectoryResolver =
            cacheDirectoryResolver ?? getApplicationCacheDirectory;

  static const Duration defaultMaxAge = Duration(hours: 24);
  static const String _folderName = 'story_cache';

  final Future<Directory> Function() _cacheDirectoryResolver;

  Future<Directory> resolveDirectory() async {
    final base = await _cacheDirectoryResolver();
    final dir = Directory(p.join(base.path, _folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> savePng({
    required Uint8List pngBytes,
    required int activityId,
    required String tag,
  }) async {
    final dir = await resolveDirectory();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final safeTag = tag.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File(p.join(dir.path, 'story_${activityId}_${safeTag}_$ts.png'));
    await file.writeAsBytes(pngBytes, flush: true);
    return file;
  }

  /// Removes cached Story PNG files modified more than [maxAge] ago.
  Future<int> cleanupExpiredFiles({
    Duration maxAge = defaultMaxAge,
    DateTime? nowUtc,
  }) async {
    try {
      final dir = await resolveDirectory();
      if (!await dir.exists()) return 0;

      final cutoff = (nowUtc ?? DateTime.now()).toUtc().subtract(maxAge);
      var removed = 0;

      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        if (stat.modified.toUtc().isBefore(cutoff)) {
          await entity.delete();
          removed++;
        }
      }
      if (removed > 0) {
        AppLogger.info(
          'StoryImageCache',
          'Cleaned $removed expired story cache PNG(s) (> ${maxAge.inHours}h)',
        );
      }
      return removed;
    } on Object catch (error) {
      AppLogger.warn('StoryImageCache', 'Failed cleanup of story cache', error);
      return 0;
    }
  }
}

