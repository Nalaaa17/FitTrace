import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:metrics_engine/metrics_engine.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/activity_import_source.dart';
import 'fit_archive_storage.dart';

class _FitIsolateInput {
  const _FitIsolateInput({
    required this.bytes,
    required this.hrZoneConfig,
    this.garminActivityId,
    this.fallbackTitle,
  });

  final Uint8List bytes;
  final HrZoneConfig hrZoneConfig;
  final int? garminActivityId;
  final String? fallbackTitle;
}

ParsedActivity _parseFitInIsolate(_FitIsolateInput input) {
  const parser = GarminFitParserEngine();
  return parser.parseFitBytes(
    input.bytes,
    hrZoneConfig: input.hrZoneConfig,
    garminActivityId: input.garminActivityId,
    fallbackTitle: input.fallbackTitle,
  );
}

/// Top-level isolate launcher that captures only sendable primitive/value args.
Future<ParsedActivity> _runParseIsolate({
  required Uint8List bytes,
  required HrZoneConfig hrZoneConfig,
  required int? garminActivityId,
  required String? fallbackTitle,
}) {
  final payload = _FitIsolateInput(
    bytes: bytes,
    hrZoneConfig: hrZoneConfig,
    garminActivityId: garminActivityId,
    fallbackTitle: fallbackTitle,
  );
  return Isolate.run(() => _parseFitInIsolate(payload));
}

class _SingleDigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}

typedef ThumbnailHook = Future<void> Function(
  int activityId,
  ParsedActivity parsed,
);

/// End-to-end local import pipeline:
/// stream/read -> SHA-256 dedup -> Isolate parse -> `.fit.gz` archive -> Drift transaction.
class FitImportPipeline {
  FitImportPipeline({
    required this.db,
    required this.archiveStorage,
    this.onActivityPersisted,
    this.tempDirectory,
  });

  final AppDatabase db;
  final FitArchiveStorage archiveStorage;
  final ThumbnailHook? onActivityPersisted;
  final Directory? tempDirectory;

  Future<BatchImportSummary> importFromSource(
    ActivityImportSource source, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final candidates = await source.fetchCandidates();
    return importCandidates(candidates, onProgress: onProgress);
  }

  Future<BatchImportSummary> importCandidates(
    List<ImportCandidate> candidates, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final outcomes = <ImportOutcome>[];
    var imported = 0;
    var updated = 0;
    var skipped = 0;
    var failed = 0;

    final prefs = await db.getPreferences();
    final hrZoneConfig = HrZoneConfig.resolve(
      hrMaxManual: prefs.hrMaxManual,
      birthDate: prefs.birthDate,
      thresholdsPercent: prefs.hrZoneThresholds.length == 4
          ? prefs.hrZoneThresholds
          : HrZoneConfig.defaultThresholdsPercent,
    );

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final outcome = await _processSingleCandidate(
        candidate: candidate,
        hrZoneConfig: hrZoneConfig,
      );
      outcomes.add(outcome);

      switch (outcome.type) {
        case ImportOutcomeType.imported:
          imported++;
        case ImportOutcomeType.reparsed:
          updated++;
        case ImportOutcomeType.skippedDuplicate:
          skipped++;
        case ImportOutcomeType.failed:
          failed++;
      }

      onProgress?.call(i + 1, candidates.length);
    }

    return BatchImportSummary(
      outcomes: outcomes,
      importedCount: imported,
      updatedCount: updated,
      skippedCount: skipped,
      failedCount: failed,
    );
  }

  Future<ImportOutcome> retryFailedActivity(int activityId) async {
    final record = await db.getActivityById(activityId);
    if (record == null) {
      return const ImportOutcome(
        type: ImportOutcomeType.failed,
        label: 'Missing activity',
        errorMessage: 'Aktivitas tidak ditemukan.',
      );
    }

    final rawBytes = await archiveStorage.readArchive(record.originalFitPath);
    if (rawBytes == null) {
      return ImportOutcome(
        type: ImportOutcomeType.failed,
        label: record.title,
        activityId: activityId,
        errorMessage: 'Arsip .FIT tidak tersedia untuk diparse ulang.',
      );
    }

    final prefs = await db.getPreferences();
    final hrZoneConfig = HrZoneConfig.resolve(
      hrMaxManual: prefs.hrMaxManual,
      birthDate: prefs.birthDate,
      thresholdsPercent: prefs.hrZoneThresholds.length == 4
          ? prefs.hrZoneThresholds
          : HrZoneConfig.defaultThresholdsPercent,
    );

    try {
      final parsed = await _runParseIsolate(
        bytes: rawBytes,
        hrZoneConfig: hrZoneConfig,
        garminActivityId: record.garminActivityId,
        fallbackTitle: record.title,
      );

      final source = ActivitySource.fromStorageKey(record.source);
      final targetStatus = source == ActivitySource.garminSync
          ? SyncStatus.synced
          : SyncStatus.localOnly;

      await db.replaceParsedActivity(
        existingActivityId: activityId,
        parsed: parsed,
        source: source,
        syncStatus: targetStatus,
        fitFileHash: record.fitFileHash,
        originalFitPath: record.originalFitPath,
      );
      await onActivityPersisted?.call(activityId, parsed);

      return ImportOutcome(
        type: ImportOutcomeType.reparsed,
        label: parsed.title,
        activityId: activityId,
      );
    } on Object catch (error) {
      AppLogger.warn('FitImportPipeline', 'Retry parse failed', error);
      return ImportOutcome(
        type: ImportOutcomeType.failed,
        label: record.title,
        activityId: activityId,
        errorMessage: error.toString(),
      );
    }
  }

  Future<ImportOutcome> _processSingleCandidate({
    required ImportCandidate candidate,
    required HrZoneConfig hrZoneConfig,
  }) async {
    final label = _candidateLabel(candidate);
    File? tempFileToDelete;

    try {
      final resolved = await _materializeAndHash(candidate);
      tempFileToDelete = resolved.tempFile;
      final hash = resolved.sha256Hex;
      final bytes = resolved.bytes;

      ActivityRecord? existing;
      if (candidate.garminActivityId != null) {
        existing =
            await db.findByGarminActivityId(candidate.garminActivityId!);
        if (existing == null) {
          final manualMatch = await db.findByFitFileHash(hash);
          if (manualMatch != null &&
              manualMatch.garminActivityId == null &&
              SyncStatus.fromStorageKey(manualMatch.syncStatus) !=
                  SyncStatus.parseFailed) {
            await db.linkGarminActivityId(
              activityId: manualMatch.id,
              garminActivityId: candidate.garminActivityId!,
              source: candidate.source,
              syncStatus: candidate.syncStatusOverride ?? SyncStatus.synced,
            );
            return ImportOutcome(
              type: ImportOutcomeType.skippedDuplicate,
              label: manualMatch.title,
              activityId: manualMatch.id,
            );
          }
        }
      } else {
        existing = await db.findByFitFileHash(hash);
      }

      if (existing != null &&
          existing.fitFileHash == hash &&
          SyncStatus.fromStorageKey(existing.syncStatus) !=
              SyncStatus.parseFailed) {
        return ImportOutcome(
          type: ImportOutcomeType.skippedDuplicate,
          label: existing.title,
          activityId: existing.id,
        );
      }

      final parsed = await _runParseIsolate(
        bytes: bytes,
        hrZoneConfig: hrZoneConfig,
        garminActivityId: candidate.garminActivityId,
        fallbackTitle: candidate.suggestedTitle,
      );

      final archivePath = await archiveStorage.saveArchive(
        fitFileHash: hash,
        rawFitBytes: bytes,
      );

      final syncStatus = candidate.syncStatusOverride ??
          (candidate.source == ActivitySource.garminSync
              ? SyncStatus.synced
              : SyncStatus.localOnly);

      if (existing != null) {
        await db.replaceParsedActivity(
          existingActivityId: existing.id,
          parsed: parsed,
          source: candidate.source,
          syncStatus: syncStatus,
          fitFileHash: hash,
          originalFitPath: archivePath,
        );
        await onActivityPersisted?.call(existing.id, parsed);
        return ImportOutcome(
          type: ImportOutcomeType.reparsed,
          label: parsed.title,
          activityId: existing.id,
        );
      }

      final activityId = await db.insertParsedActivity(
        parsed: parsed,
        source: candidate.source,
        syncStatus: syncStatus,
        fitFileHash: hash,
        originalFitPath: archivePath,
      );
      await onActivityPersisted?.call(activityId, parsed);

      return ImportOutcome(
        type: ImportOutcomeType.imported,
        label: parsed.title,
        activityId: activityId,
      );
    } on FitParseException catch (error) {
      AppLogger.warn('FitImportPipeline', 'Corrupt/invalid FIT: $label', error);
      return _persistParseFailure(candidate, label, error.message);
    } on StorageFullFailure {
      rethrow;
    } on SyncAuthFailure {
      rethrow;
    } on RateLimitFailure {
      rethrow;
    } on FileSystemException catch (error) {
      if (_isDiskFull(error)) {
        throw StorageFullFailure(
          'Penyimpanan perangkat penuh. Kosongkan ruang lalu coba lagi.',
          error,
        );
      }
      if (candidate.source == ActivitySource.garminSync) rethrow;
      AppLogger.error('FitImportPipeline', 'Filesystem error: $label', error);
      return ImportOutcome(
        type: ImportOutcomeType.failed,
        label: label,
        errorMessage: error.message,
      );
    } on Object catch (error) {
      if (candidate.source == ActivitySource.garminSync) {
        rethrow;
      }
      AppLogger.error('FitImportPipeline', 'Import error: $label', error);
      return ImportOutcome(
        type: ImportOutcomeType.failed,
        label: label,
        errorMessage: error.toString(),
      );
    } finally {
      if (tempFileToDelete != null && await tempFileToDelete.exists()) {
        await tempFileToDelete.delete();
      }
    }
  }

  Future<ImportOutcome> _persistParseFailure(
    ImportCandidate candidate,
    String label,
    String message,
  ) async {
    try {
      final resolved = await _materializeAndHash(candidate);
      try {
        final existing = await db.findByFitFileHash(resolved.sha256Hex);
        if (existing != null) {
          return ImportOutcome(
            type: ImportOutcomeType.failed,
            label: existing.title,
            activityId: existing.id,
            errorMessage: message,
          );
        }
        final archivePath = await archiveStorage.saveArchive(
          fitFileHash: resolved.sha256Hex,
          rawFitBytes: resolved.bytes,
        );
        final id = await db.insertFailedParseActivity(
          title: label,
          source: candidate.source,
          fitFileHash: resolved.sha256Hex,
          garminActivityId: candidate.garminActivityId,
          originalFitPath: archivePath,
        );
        return ImportOutcome(
          type: ImportOutcomeType.failed,
          label: label,
          activityId: id,
          errorMessage: message,
        );
      } finally {
        if (resolved.tempFile != null && await resolved.tempFile!.exists()) {
          await resolved.tempFile!.delete();
        }
      }
    } on Object {
      return ImportOutcome(
        type: ImportOutcomeType.failed,
        label: label,
        errorMessage: message,
      );
    }
  }

  Future<({Uint8List bytes, String sha256Hex, File? tempFile})>
      _materializeAndHash(ImportCandidate candidate) async {
    if (candidate.bytes != null) {
      final unwrapped = _unwrapZipIfNeeded(
        candidate.bytes!,
        sha256.convert(candidate.bytes!).toString(),
      );
      return (bytes: unwrapped.bytes, sha256Hex: unwrapped.sha256Hex, tempFile: null);
    }

    if (candidate.file != null) {
      final file = candidate.file!;
      final digestSink = _SingleDigestSink();
      final hashSink = sha256.startChunkedConversion(digestSink);
      final builder = BytesBuilder(copy: false);

      await for (final chunk in file.openRead()) {
        hashSink.add(chunk);
        builder.add(chunk);
      }
      hashSink.close();
      final unwrapped = _unwrapZipIfNeeded(
        builder.takeBytes(),
        digestSink.digest.toString(),
      );
      return (
        bytes: unwrapped.bytes,
        sha256Hex: unwrapped.sha256Hex,
        tempFile: null,
      );
    }

    // Streaming download/input -> write temp file while computing SHA-256 (M1-06).
    final tempDir = tempDirectory ?? Directory.systemTemp;
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final tempFile = File(
      p.join(
        tempDir.path,
        'fit_dl_${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    final sink = tempFile.openWrite();
    final digestSink = _SingleDigestSink();
    final hashSink = sha256.startChunkedConversion(digestSink);

    try {
      await for (final chunk in candidate.streamFactory!()) {
        hashSink.add(chunk);
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
    } on Object {
      try {
        await sink.close();
      } on Object catch (_) {}
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
    hashSink.close();

    final rawBytes = await tempFile.readAsBytes();
    final unwrapped = _unwrapZipIfNeeded(
      rawBytes,
      digestSink.digest.toString(),
    );
    return (
      bytes: unwrapped.bytes,
      sha256Hex: unwrapped.sha256Hex,
      tempFile: tempFile,
    );
  }

  ({Uint8List bytes, String sha256Hex}) _unwrapZipIfNeeded(
    Uint8List rawBytes,
    String rawSha256Hex,
  ) {
    final isZip = rawBytes.length >= 4 &&
        rawBytes[0] == 0x50 &&
        rawBytes[1] == 0x4B &&
        rawBytes[2] == 0x03 &&
        rawBytes[3] == 0x04;
    if (!isZip) {
      return (bytes: rawBytes, sha256Hex: rawSha256Hex);
    }

    try {
      final archive = ZipDecoder().decodeBytes(rawBytes);
      ArchiveFile? fitEntry;
      for (final file in archive.files) {
        if (file.isFile && file.name.toLowerCase().endsWith('.fit')) {
          fitEntry = file;
          break;
        }
      }
      fitEntry ??= archive.files.cast<ArchiveFile?>().firstWhere(
            (f) => f != null && f.isFile,
            orElse: () => null,
          );
      if (fitEntry == null) {
        throw const FitParseException('Arsip ZIP tidak berisi file .FIT.');
      }
      final fitBytes = Uint8List.fromList(fitEntry.readBytes() ?? const <int>[]);
      return (
        bytes: fitBytes,
        sha256Hex: sha256.convert(fitBytes).toString(),
      );
    } on FitParseException {
      rethrow;
    } on Object catch (error) {
      throw FitParseException('Gagal mengekstrak ZIP .FIT: $error');
    }
  }

  static bool _isDiskFull(FileSystemException error) {
    final code = error.osError?.errorCode;
    final msg = '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();
    return code == 28 ||
        code == 112 ||
        msg.contains('no space left') ||
        msg.contains('disk full') ||
        msg.contains('enospc');
  }

  String _candidateLabel(ImportCandidate candidate) {
    if (candidate.suggestedTitle != null &&
        candidate.suggestedTitle!.trim().isNotEmpty) {
      return candidate.suggestedTitle!.trim();
    }
    if (candidate.file != null) {
      return p.basenameWithoutExtension(candidate.file!.path);
    }
    return 'Import FIT';
  }
}
