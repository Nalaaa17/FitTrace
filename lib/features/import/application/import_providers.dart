import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/logging/app_logger.dart';
import '../../feed/data/thumbnail_cache_service.dart';
import '../data/android_share_intent_bridge.dart';
import '../data/fit_archive_storage.dart';
import '../data/fit_import_pipeline.dart';
import '../data/manual_fit_import_source.dart';
import '../domain/activity_import_source.dart';

final fitArchiveStorageProvider = Provider<FitArchiveStorage>((ref) {
  return FitArchiveStorage();
});

final thumbnailCacheServiceProvider = Provider<ThumbnailCacheService>((ref) {
  return ThumbnailCacheService();
});

final androidShareIntentBridgeProvider =
    Provider<AndroidShareIntentBridge>((ref) {
  return AndroidShareIntentBridge();
});

final fitImportPipelineProvider = Provider<FitImportPipeline>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final archiveStorage = ref.watch(fitArchiveStorageProvider);
  final thumbnails = ref.watch(thumbnailCacheServiceProvider);

  return FitImportPipeline(
    db: db,
    archiveStorage: archiveStorage,
    onActivityPersisted: (activityId, parsed) async {
      if (parsed.hasGpsTrack && parsed.trackPoints.length >= 2) {
        try {
          await thumbnails.renderAndCache(activityId, parsed.trackPoints);
        } on Object catch (e) {
          AppLogger.warn('ThumbnailHook', 'Thumbnail render skipped', e);
        }
      }
    },
  );
});

class ImportState {
  const ImportState({
    this.isImporting = false,
    this.completed = 0,
    this.total = 0,
    this.lastSummary,
    this.errorMessage,
  });

  final bool isImporting;
  final int completed;
  final int total;
  final BatchImportSummary? lastSummary;
  final String? errorMessage;

  ImportState copyWith({
    bool? isImporting,
    int? completed,
    int? total,
    BatchImportSummary? Function()? lastSummary,
    String? Function()? errorMessage,
  }) {
    return ImportState(
      isImporting: isImporting ?? this.isImporting,
      completed: completed ?? this.completed,
      total: total ?? this.total,
      lastSummary: lastSummary != null ? lastSummary() : this.lastSummary,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ImportController extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportState();

  Future<BatchImportSummary?> importFromFilePicker() {
    return _runSourceImport(const ManualFilePickerSource());
  }

  Future<BatchImportSummary?> importSharedFilePaths(List<String> paths) {
    if (paths.isEmpty) return Future<BatchImportSummary?>.value(null);
    return _runSourceImport(SharedFilesImportSource(paths));
  }

  Future<ImportOutcome> retryFailedActivity(int activityId) async {
    final pipeline = ref.read(fitImportPipelineProvider);
    return pipeline.retryFailedActivity(activityId);
  }

  Future<void> deleteActivity(int activityId) async {
    final db = ref.read(appDatabaseProvider);
    final archiveStorage = ref.read(fitArchiveStorageProvider);
    final thumbnails = ref.read(thumbnailCacheServiceProvider);

    final record = await db.getActivityById(activityId);
    await db.deleteActivityById(activityId);
    await archiveStorage.deleteArchive(record?.originalFitPath);
    await thumbnails.deleteThumbnail(activityId);
  }

  Future<BatchImportSummary?> _runSourceImport(
    ActivityImportSource source,
  ) async {
    if (state.isImporting) return null;

    state = state.copyWith(
      isImporting: true,
      completed: 0,
      total: 0,
      lastSummary: () => null,
      errorMessage: () => null,
    );

    try {
      final candidates = await source.fetchCandidates();
      if (candidates.isEmpty) {
        state = state.copyWith(isImporting: false);
        return null;
      }

      state = state.copyWith(total: candidates.length);
      final pipeline = ref.read(fitImportPipelineProvider);
      final summary = await pipeline.importCandidates(
        candidates,
        onProgress: (done, total) {
          state = state.copyWith(completed: done, total: total);
        },
      );

      state = state.copyWith(
        isImporting: false,
        lastSummary: () => summary,
      );
      return summary;
    } on Object catch (error) {
      AppLogger.error('ImportController', 'Manual import failed', error);
      state = state.copyWith(
        isImporting: false,
        errorMessage: () => error.toString(),
      );
      return null;
    }
  }
}

final importControllerProvider =
    NotifierProvider<ImportController, ImportState>(ImportController.new);

