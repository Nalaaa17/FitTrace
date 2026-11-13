import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/logging/app_logger.dart';
import '../../feed/application/feed_providers.dart';
import '../../garmin_sync/application/garmin_sync_providers.dart';
import '../../import/application/import_providers.dart';
import '../../story_share/application/story_share_providers.dart';
import '../data/backup_reminder_service.dart';
import '../data/backup_restore_service.dart';
import '../data/csv_export_service.dart';
import '../data/fit_export_service.dart';

typedef SaveBackupZipHandler = Future<Uri?> Function({
  required String fileName,
  required Uint8List bytes,
});

typedef PickBackupZipHandler = Future<Uint8List?> Function();

final fitExportServiceProvider = Provider<FitExportService>((ref) {
  return FitExportService(
    db: ref.watch(appDatabaseProvider),
    archiveStorage: ref.watch(fitArchiveStorageProvider),
  );
});

final backupRestoreServiceProvider = Provider<BackupRestoreService>((ref) {
  return BackupRestoreService(
    db: ref.watch(appDatabaseProvider),
    archiveStorage: ref.watch(fitArchiveStorageProvider),
    thumbnailCache: ref.watch(thumbnailCacheServiceProvider),
    storyCache: ref.watch(storyImageCacheServiceProvider),
    cookieStore: ref.watch(secureCookieStoreProvider),
    cookieExtractor: ref.watch(webViewCookieExtractorProvider),
  );
});

final saveBackupZipHandlerProvider = Provider<SaveBackupZipHandler>((ref) {
  return ({required String fileName, required Uint8List bytes}) {
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/zip',
      dialogTitle: 'Simpan Backup FitTrace (.ZIP)',
    );
  };
});

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportService(db: ref.watch(appDatabaseProvider));
});

final saveCsvHandlerProvider = Provider<SaveBackupZipHandler>((ref) {
  return ({required String fileName, required Uint8List bytes}) {
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'text/csv',
      dialogTitle: 'Ekspor Ringkasan Aktivitas (.CSV)',
    );
  };
});

final localNotificationDispatcherProvider =
    Provider<LocalNotificationDispatcher>((ref) {
  return const MethodChannelLocalNotificationDispatcher();
});

final backupReminderServiceProvider = Provider<BackupReminderService>((ref) {
  return BackupReminderService(
    db: ref.watch(appDatabaseProvider),
    notificationDispatcher: ref.watch(localNotificationDispatcherProvider),
    nowUtc: ref.watch(clockNowProvider),
  );
});

final backupReminderProvider = FutureProvider<BackupReminderDecision>((ref) {
  ref.watch(_storageMutationTickProvider);
  ref.watch(userPreferencesProvider);
  return ref.read(backupReminderServiceProvider).checkAndNotifyIfDue();
});

final pickBackupZipHandlerProvider = Provider<PickBackupZipHandler>((ref) {
  return () async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const <String>['zip'],
    );
    if (picked == null || picked.path == null) return null;
    return File(picked.path!).readAsBytes();
  };
});

final _storageMutationTickProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchActivitiesMutationTick();
});

final localStorageStatsProvider = FutureProvider<LocalStorageStats>((ref) {
  ref.watch(_storageMutationTickProvider);
  return ref.watch(backupRestoreServiceProvider).getStorageStats();
});

class BackupOperationState {
  const BackupOperationState({
    this.isRunning = false,
    this.stage = '',
    this.progress = 0.0,
    this.errorMessage,
  });

  final bool isRunning;
  final String stage;
  final double progress;
  final String? errorMessage;

  BackupOperationState copyWith({
    bool? isRunning,
    String? stage,
    double? progress,
    String? Function()? errorMessage,
  }) {
    return BackupOperationState(
      isRunning: isRunning ?? this.isRunning,
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class BackupController extends Notifier<BackupOperationState> {
  @override
  BackupOperationState build() => const BackupOperationState();

  Future<({bool saved, Uri? uri})> exportFullBackupZip() async {
    if (state.isRunning) return const (saved: false, uri: null);
    state = const BackupOperationState(
      isRunning: true,
      stage: 'Memulai backup...',
      progress: 0.05,
    );

    try {
      final service = ref.read(backupRestoreServiceProvider);
      final zipBytes = await service.buildFullBackupZip(
        onProgress: (stage, progress) {
          state = state.copyWith(stage: stage, progress: progress);
        },
      );
      final now = DateTime.now();
      final dateTag =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final saveUri = await ref.read(saveBackupZipHandlerProvider)(
        fileName: 'fittrace_backup_$dateTag.zip',
        bytes: zipBytes,
      );
      ref.invalidate(localStorageStatsProvider);
      state = const BackupOperationState();
      return (saved: saveUri != null, uri: saveUri);
    } on Object catch (error) {
      AppLogger.warn('BackupController', 'Full backup failed', error);
      state = BackupOperationState(errorMessage: error.toString());
      return const (saved: false, uri: null);
    }
  }

  Future<BackupRestoreSummary?> restoreBackupFromPicker() async {
    if (state.isRunning) return null;
    state = const BackupOperationState(
      isRunning: true,
      stage: 'Memilih file backup (.zip)...',
      progress: 0.05,
    );

    try {
      final zipBytes = await ref.read(pickBackupZipHandlerProvider)();
      if (zipBytes == null) {
        state = const BackupOperationState();
        return null;
      }

      final summary = await ref.read(backupRestoreServiceProvider).restoreFromZipBytes(
        zipBytes,
        onProgress: (stage, progress) {
          state = state.copyWith(stage: stage, progress: progress);
        },
      );
      ref.invalidate(localStorageStatsProvider);
      await ref.read(feedPagingProvider.notifier).refresh();
      state = const BackupOperationState();
      return summary;
    } on Object catch (error) {
      AppLogger.warn('BackupController', 'Restore failed', error);
      state = BackupOperationState(errorMessage: error.toString());
      return null;
    }
  }

  Future<void> performFactoryReset() async {
    if (state.isRunning) return;
    state = const BackupOperationState(
      isRunning: true,
      stage: 'Menghapus seluruh data lokal...',
      progress: 0.5,
    );

    try {
      await ref.read(backupRestoreServiceProvider).factoryResetAllData();
      ref.invalidate(localStorageStatsProvider);
      await ref.read(feedPagingProvider.notifier).refresh();
      state = const BackupOperationState();
    } on Object catch (error) {
      AppLogger.warn('BackupController', 'Factory reset failed', error);
      state = BackupOperationState(errorMessage: error.toString());
      rethrow;
    }
  }

  Future<CompactDatabaseResult?> compactDatabase() async {
    if (state.isRunning) return null;
    state = const BackupOperationState(
      isRunning: true,
      stage: 'Memadatkan database SQLite (VACUUM)...',
      progress: 0.4,
    );

    try {
      final result =
          await ref.read(backupRestoreServiceProvider).compactDatabase();
      ref.invalidate(localStorageStatsProvider);
      state = const BackupOperationState();
      return result;
    } on Object catch (error) {
      AppLogger.warn('BackupController', 'Database compact failed', error);
      state = BackupOperationState(errorMessage: error.toString());
      return null;
    }
  }

  Future<({bool saved, int rowCount, Uri? uri})> exportCsvSummary() async {
    if (state.isRunning) {
      return const (saved: false, rowCount: 0, uri: null);
    }
    state = const BackupOperationState(
      isRunning: true,
      stage: 'Menyiapkan file .CSV...',
      progress: 0.35,
    );

    try {
      final prefs = await ref.read(appDatabaseProvider).getPreferences();
      final payload =
          await ref.read(csvExportServiceProvider).buildActivitiesCsv(
                unitSystem: prefs.unitSystem,
              );
      final uri = await ref.read(saveCsvHandlerProvider)(
        fileName: payload.fileName,
        bytes: payload.bytes,
      );
      state = const BackupOperationState();
      return (saved: uri != null, rowCount: payload.rowCount, uri: uri);
    } on Object catch (error) {
      AppLogger.warn('BackupController', 'CSV export failed', error);
      state = BackupOperationState(errorMessage: error.toString());
      return const (saved: false, rowCount: 0, uri: null);
    }
  }
}

final backupControllerProvider =
    NotifierProvider<BackupController, BackupOperationState>(
  BackupController.new,
);
