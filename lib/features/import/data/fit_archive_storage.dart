import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';

/// Manages gzip-compressed `.fit.gz` archives retained locally for 30 days
/// (PRD M5-01, ADR-004).
class FitArchiveStorage {
  FitArchiveStorage({
    Future<Directory> Function()? rootDirectoryResolver,
  }) : _rootDirectoryResolver =
            rootDirectoryResolver ?? _defaultArchiveDirectory;

  final Future<Directory> Function() _rootDirectoryResolver;

  static Future<Directory> _defaultArchiveDirectory() async {
    final appDocs = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDocs.path, 'fit_archives'));
  }

  Future<String> saveArchive({
    required String fitFileHash,
    required Uint8List rawFitBytes,
  }) async {
    final dir = await _rootDirectoryResolver();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final targetPath = p.join(dir.path, '$fitFileHash.fit.gz');
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      return targetPath;
    }

    final compressed = gzip.encode(rawFitBytes);
    final tempFile = File('$targetPath.tmp');
    await tempFile.writeAsBytes(compressed, flush: true);
    await tempFile.rename(targetPath);
    return targetPath;
  }

  Future<Uint8List?> readArchive(String? archivePath) async {
    if (archivePath == null || archivePath.isEmpty) return null;
    final file = File(archivePath);
    if (!await file.exists()) return null;
    final compressed = await file.readAsBytes();
    return Uint8List.fromList(gzip.decode(compressed));
  }

  Future<void> deleteArchive(String? archivePath) async {
    if (archivePath == null || archivePath.isEmpty) return;
    final file = File(archivePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Removes `.fit.gz` archives older than [retention] (default 30 days)
  /// and clears stale paths in SQLite.
  Future<int> pruneExpiredArchives({
    required AppDatabase db,
    Duration retention = const Duration(days: 30),
    DateTime? nowUtc,
  }) async {
    final dir = await _rootDirectoryResolver();
    if (!await dir.exists()) return 0;

    final cutoff = (nowUtc ?? DateTime.now().toUtc()).subtract(retention);
    var deletedCount = 0;

    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.fit.gz')) continue;
      try {
        final stat = await entity.stat();
        if (stat.modified.toUtc().isBefore(cutoff)) {
          await entity.delete();
          deletedCount++;
        }
      } on Object catch (e) {
        AppLogger.warn('FitArchiveStorage', 'Failed pruning ${entity.path}', e);
      }
    }

    if (deletedCount > 0) {
      final rows = await db.customSelect(
        'SELECT id, original_fit_path FROM activities '
        'WHERE original_fit_path IS NOT NULL;',
      ).get();
      for (final row in rows) {
        final path = row.read<String?>('original_fit_path');
        if (path != null && !await File(path).exists()) {
          await db.clearOriginalFitPath(row.read<int>('id'));
        }
      }
    }

    return deletedCount;
  }
}

