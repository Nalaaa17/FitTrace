import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../import/data/fit_import_pipeline.dart';
import '../../import/domain/activity_import_source.dart';
import '../domain/garmin_connect_client.dart';
import '../domain/garmin_session.dart';
import '../domain/garmin_session_refresher.dart';

typedef DelayScheduler = Future<void> Function(Duration duration);
typedef ClockNow = DateTime Function();

/// End-to-end Garmin Connect synchronization engine (`PRD §2.3`, `M1-03`..`M1-07`, `NFR-03`).
class GarminSyncEngine {
  GarminSyncEngine({
    required this.db,
    required this.client,
    required this.refresher,
    required this.importPipeline,
    DelayScheduler? delayScheduler,
    ClockNow? nowUtc,
  })  : _delay = delayScheduler ?? Future<void>.delayed,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const int pageSize = 50;
  static const int maxBurstSize = 10;
  static const Duration burstPauseDuration = Duration(seconds: 2);
  static const int maxRateLimitAttempts = 5;
  static const int maxDownloadRetries = 3;
  static const Duration incrementalOverlapBuffer = Duration(hours: 24);
  static const int _maxOffsetSafetyCap = 5000;

  final AppDatabase db;
  final GarminConnectClient client;
  final GarminSessionRefresher refresher;
  final FitImportPipeline importPipeline;
  final DelayScheduler _delay;
  final ClockNow _nowUtc;

  /// Validates stored session via lightweight probe + single silent refresh (`M1-03`, `M1-04`).
  Future<void> ensureValidSession() async {
    var probe = await _probeWithRateLimitBackoff();

    if (probe.status == ProbeStatus.valid) {
      return;
    }
    if (probe.status == ProbeStatus.rateLimited) {
      throw RateLimitFailure(
        probe.message ?? 'Garmin membatasi permintaan sementara (HTTP 429).',
      );
    }
    if (probe.status == ProbeStatus.challengeRequired) {
      throw GarminChallengeException(
        probe.message ??
            'Garmin meminta verifikasi keamanan (Cloudflare/CAPTCHA).',
      );
    }
    if (probe.status == ProbeStatus.networkError) {
      throw ImportFailure(
        probe.message ?? 'Gagal terhubung ke Garmin Connect.',
      );
    }

    // Attempt silent auto-refresh once on 401/403 before declaring expired.
    AppLogger.info('GarminSyncEngine', 'Session expired; attempting silent refresh');
    final refreshOutcome = await refresher.attemptSilentRefresh();
    if (refreshOutcome == RefreshOutcome.challengeRequired) {
      throw const GarminChallengeException();
    }
    if (refreshOutcome != RefreshOutcome.refreshed) {
      throw SyncAuthFailure(
        probe.message ?? 'Sesi Garmin Connect berakhir. Silakan login ulang.',
      );
    }

    probe = await _probeWithRateLimitBackoff();
    if (probe.status == ProbeStatus.valid) {
      return;
    }
    if (probe.status == ProbeStatus.rateLimited) {
      throw RateLimitFailure(
        probe.message ?? 'Garmin membatasi permintaan sementara (HTTP 429).',
      );
    }
    if (probe.status == ProbeStatus.challengeRequired) {
      throw GarminChallengeException(
        probe.message ??
            'Garmin meminta verifikasi keamanan (Cloudflare/CAPTCHA).',
      );
    }
    throw SyncAuthFailure(
      probe.message ?? 'Sesi Garmin masih kedaluwarsa setelah refresh.',
    );
  }

  /// Synchronizes latest activities (`50/page`, dedup before download, max 10 burst).
  ///
  /// Unless [fullResync] is true, incremental sync (`M1-11`) fetches only
  /// activities with `startTime > lastActivityStartTime - 24h`.
  Future<SyncResult> syncNow({
    bool fullResync = false,
    void Function(String status, int completed, int total)? onProgress,
  }) async {
    onProgress?.call('Memeriksa sesi Garmin...', 0, 0);
    await ensureValidSession();

    final prefs = await db.getPreferences();
    final cutoffUtc = !fullResync && prefs.lastActivityStartTime != null
        ? prefs.lastActivityStartTime!.toUtc().subtract(incrementalOverlapBuffer)
        : null;

    onProgress?.call('Mengambil daftar aktivitas...', 0, 0);

    final toDownload = <GarminActivitySummary>[];
    var skippedPreDownload = 0;
    var offset = 0;

    while (offset < _maxOffsetSafetyCap) {
      final page = await _fetchPageWithBackoff(start: offset);
      if (page.isEmpty) break;

      var allSkippedOlderThanCutoff = cutoffUtc != null;
      var reachedOlderThanWindow = false;

      for (final summary in page) {
        if (cutoffUtc != null && !summary.startTimeUtc.isAfter(cutoffUtc)) {
          skippedPreDownload++;
          reachedOlderThanWindow = true;
          continue;
        }

        final existing = await db.findByGarminActivityId(summary.activityId);
        final isAlreadySynced = existing != null &&
            SyncStatus.fromStorageKey(existing.syncStatus) == SyncStatus.synced;
        final isServerNewer = existing != null &&
            summary.updatedAtUtc != null &&
            summary.updatedAtUtc!.isAfter(existing.updatedAt);

        if (isAlreadySynced && !isServerNewer) {
          skippedPreDownload++;
          if (cutoffUtc != null && summary.startTimeUtc.isAfter(cutoffUtc)) {
            allSkippedOlderThanCutoff = false;
          }
          continue;
        }

        allSkippedOlderThanCutoff = false;
        toDownload.add(summary);
      }

      if (page.length < pageSize ||
          allSkippedOlderThanCutoff ||
          reachedOlderThanWindow) {
        break;
      }
      offset += page.length;
    }

    var imported = 0;
    var updated = 0;
    var skippedPipeline = 0;
    var failed = 0;
    DateTime? maxSyncedStartUtc = prefs.lastActivityStartTime?.toUtc();

    final totalDownloads = toDownload.length;
    for (var i = 0; i < totalDownloads; i++) {
      // NFR-03: max 10 FIT downloads per burst with 2-second pause between bursts.
      if (i > 0 && i % maxBurstSize == 0) {
        onProgress?.call(
          'Jeda anti rate-limit antar burst ($i/$totalDownloads)...',
          i,
          totalDownloads,
        );
        await _delay(burstPauseDuration);
      }

      final summary = toDownload[i];
      onProgress?.call(
        'Mengunduh ${summary.activityName} (${i + 1}/$totalDownloads)...',
        i,
        totalDownloads,
      );

      final outcome = await _downloadAndImportWithRetry(summary);
      switch (outcome.type) {
        case ImportOutcomeType.imported:
          imported++;
          maxSyncedStartUtc = _latestDate(maxSyncedStartUtc, summary.startTimeUtc);
        case ImportOutcomeType.reparsed:
          updated++;
          maxSyncedStartUtc = _latestDate(maxSyncedStartUtc, summary.startTimeUtc);
        case ImportOutcomeType.skippedDuplicate:
          skippedPipeline++;
          maxSyncedStartUtc = _latestDate(maxSyncedStartUtc, summary.startTimeUtc);
        case ImportOutcomeType.failed:
          failed++;
      }

      onProgress?.call(
        'Menyinkronkan (${i + 1}/$totalDownloads)...',
        i + 1,
        totalDownloads,
      );
    }

    final syncedAt = _nowUtc();
    await db.updatePreferences(
      UserPreferencesTableCompanion(
        lastSyncAt: Value(syncedAt),
        lastActivityStartTime:
            failed == 0 && maxSyncedStartUtc != null
                ? Value(maxSyncedStartUtc)
                : const Value.absent(),
      ),
    );

    final result = SyncResult(
      importedCount: imported,
      updatedCount: updated,
      skippedCount: skippedPreDownload + skippedPipeline,
      failedCount: failed,
      syncedAtUtc: syncedAt,
    );
    AppLogger.info('GarminSyncEngine', 'Sync completed: ${result.summaryBannerText}');
    return result;
  }

  /// Retries either a failed Garmin download (`SyncStatus.failed`) or a
  /// failed local parse (`SyncStatus.parseFailed`).
  Future<ImportOutcome> retryFailedActivity(int activityId) async {
    final record = await db.getActivityById(activityId);
    if (record == null) {
      return const ImportOutcome(
        type: ImportOutcomeType.failed,
        label: 'Missing activity',
        errorMessage: 'Aktivitas tidak ditemukan.',
      );
    }

    final status = SyncStatus.fromStorageKey(record.syncStatus);
    if (status == SyncStatus.parseFailed || record.garminActivityId == null) {
      return importPipeline.retryFailedActivity(activityId);
    }

    await ensureValidSession();
    final summary = GarminActivitySummary(
      activityId: record.garminActivityId!,
      activityName: record.title,
      startTimeUtc: record.startTimeUtc.toUtc(),
      sportType: SportType.fromCode(record.sportType),
      distanceMeters: record.distanceMeters,
      durationTotalSec: record.durationTotalSec,
    );
    return _downloadAndImportWithRetry(summary);
  }

  Future<SessionProbeResult> _probeWithRateLimitBackoff() async {
    for (var attempt = 0; attempt < maxRateLimitAttempts; attempt++) {
      final result = await client.probeSession();
      if (result.status != ProbeStatus.rateLimited ||
          attempt == maxRateLimitAttempts - 1) {
        return result;
      }
      final delay = _boundedRateLimitDelay(
        attempt: attempt,
        retryAfter: result.retryAfter,
      );
      AppLogger.warn(
        'GarminSyncEngine',
        'Session probe HTTP 429; backoff ${delay.inSeconds}s (attempt ${attempt + 1}/$maxRateLimitAttempts)',
      );
      await _delay(delay);
    }
    return const SessionProbeResult(
      status: ProbeStatus.rateLimited,
      statusCode: 429,
      message: 'Rate limit Garmin terlampaui.',
    );
  }

  Future<List<GarminActivitySummary>> _fetchPageWithBackoff({
    required int start,
  }) async {
    for (var attempt = 0; attempt < maxRateLimitAttempts; attempt++) {
      try {
        return await client.fetchActivitiesPage(start: start, limit: pageSize);
      } on RateLimitFailure catch (error) {
        if (attempt == maxRateLimitAttempts - 1) rethrow;
        final delay = Duration(seconds: 2 << attempt);
        AppLogger.warn(
          'GarminSyncEngine',
          'Activity list 429; backoff ${delay.inSeconds}s',
          error,
        );
        await _delay(delay);
      }
    }
    throw const RateLimitFailure('Rate limit saat mengambil daftar aktivitas.');
  }

  /// Downloads & imports a single Garmin activity with 3x retry (`2s -> 4s -> 8s`, `M1-07`).
  Future<ImportOutcome> _downloadAndImportWithRetry(
    GarminActivitySummary summary,
  ) async {
    Object? lastError;

    for (var attempt = 0; attempt <= maxDownloadRetries; attempt++) {
      try {
        final batch = await importPipeline.importCandidates(
          <ImportCandidate>[
            ImportCandidate(
              source: ActivitySource.garminSync,
              garminActivityId: summary.activityId,
              suggestedTitle: summary.activityName,
              streamFactory: () => client.downloadFitStream(summary.activityId),
            ),
          ],
        );
        if (batch.outcomes.isNotEmpty) {
          return batch.outcomes.first;
        }
        return ImportOutcome(
          type: ImportOutcomeType.failed,
          label: summary.activityName,
          errorMessage: 'Tidak ada hasil impor.',
        );
      } on StorageFullFailure {
        rethrow;
      } on SyncAuthFailure {
        rethrow;
      } on GarminChallengeException {
        rethrow;
      } on FileSystemException catch (error) {
        if (_isDiskFullException(error)) {
          throw StorageFullFailure(
            'Penyimpanan perangkat penuh. Kosongkan ruang untuk melanjutkan sinkronisasi.',
            error,
          );
        }
        lastError = error;
      } on Object catch (error) {
        if (!_isRetryableError(error)) {
          lastError = error;
          break;
        }
        lastError = error;
      }

      if (attempt < maxDownloadRetries) {
        final backoff = Duration(seconds: 2 << attempt); // 2s -> 4s -> 8s
        AppLogger.warn(
          'GarminSyncEngine',
          'Download retry ${attempt + 1}/$maxDownloadRetries for ${summary.activityId} in ${backoff.inSeconds}s',
          lastError,
        );
        await _delay(backoff);
      }
    }

    AppLogger.warn(
      'GarminSyncEngine',
      'Marked syncFailed for activity ${summary.activityId}',
      lastError,
    );
    final placeholderId = await db.upsertSyncFailedActivity(
      garminActivityId: summary.activityId,
      title: summary.activityName,
      sportType: summary.sportType,
      startTimeUtc: summary.startTimeUtc,
      distanceMeters: summary.distanceMeters,
      durationTotalSec: summary.durationTotalSec,
      durationMovingSec: summary.durationMovingSec,
      avgHeartRate: summary.averageHR,
      maxHeartRate: summary.maxHR,
      avgCadence: summary.averageCadence,
      totalElevationGainM: summary.elevationGainM ?? 0.0,
      totalElevationLossM: summary.elevationLossM ?? 0.0,
      caloriesKcal: summary.caloriesKcal ?? 0,
      zoneDurationsSec: summary.zoneDurationsSec,
    );
    return ImportOutcome(
      type: ImportOutcomeType.failed,
      label: summary.activityName,
      activityId: placeholderId,
      errorMessage:
          'Unduhan Garmin gagal setelah $maxDownloadRetries percobaan. Tap Coba lagi.',
    );
  }

  static Duration _boundedRateLimitDelay({
    required int attempt,
    Duration? retryAfter,
  }) {
    final exponential = Duration(seconds: 2 << attempt);
    if (retryAfter == null || retryAfter <= Duration.zero) {
      return exponential;
    }
    if (retryAfter > const Duration(seconds: 60)) {
      return const Duration(seconds: 60);
    }
    return retryAfter > exponential ? retryAfter : exponential;
  }

  static bool _isRetryableError(Object error) {
    return error is RateLimitFailure ||
        error is DioException ||
        error is SocketException ||
        error is HttpException ||
        error is TimeoutException ||
        error is ImportFailure;
  }

  static bool _isDiskFullException(FileSystemException error) {
    final code = error.osError?.errorCode;
    final msg = '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();
    return code == 28 ||
        code == 112 ||
        msg.contains('no space left') ||
        msg.contains('disk full') ||
        msg.contains('enospc');
  }

  static DateTime _latestDate(DateTime? a, DateTime b) {
    final bUtc = b.toUtc();
    if (a == null) return bUtc;
    return a.isAfter(bUtc) ? a : bUtc;
  }
}
