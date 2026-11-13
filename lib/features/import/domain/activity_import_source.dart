import 'dart:io';
import 'dart:typed_data';

import 'package:metrics_engine/metrics_engine.dart';

/// Candidate `.FIT` payload supplied by either manual import or Garmin sync.
class ImportCandidate {
  const ImportCandidate({
    required this.source,
    this.file,
    this.bytes,
    this.streamFactory,
    this.garminActivityId,
    this.suggestedTitle,
    this.syncStatusOverride,
  }) : assert(
          file != null || bytes != null || streamFactory != null,
          'ImportCandidate must provide file, bytes, or streamFactory.',
        );

  final ActivitySource source;
  final File? file;
  final Uint8List? bytes;
  final Stream<List<int>> Function()? streamFactory;
  final int? garminActivityId;
  final String? suggestedTitle;
  final SyncStatus? syncStatusOverride;
}

enum ImportOutcomeType {
  imported,
  reparsed,
  skippedDuplicate,
  failed,
}

class ImportOutcome {
  const ImportOutcome({
    required this.type,
    required this.label,
    this.activityId,
    this.errorMessage,
  });

  final ImportOutcomeType type;
  final String label;
  final int? activityId;
  final String? errorMessage;
}

class BatchImportSummary {
  const BatchImportSummary({
    required this.outcomes,
    required this.importedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.failedCount,
  });

  final List<ImportOutcome> outcomes;
  final int importedCount;
  final int updatedCount;
  final int skippedCount;
  final int failedCount;

  int get totalCount => outcomes.length;
}

/// Unified activity source contract shared by Manual Import (Phase 2)
/// and Garmin Connect Sync (Phase 3).
abstract interface class ActivityImportSource {
  ActivitySource get sourceType;

  Future<List<ImportCandidate>> fetchCandidates();
}

