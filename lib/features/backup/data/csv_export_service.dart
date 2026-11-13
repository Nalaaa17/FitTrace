import 'dart:convert';
import 'dart:typed_data';

import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/unit_formatter.dart';

class CsvExportPayload {
  const CsvExportPayload({
    required this.fileName,
    required this.rowCount,
    required this.bytes,
  });

  final String fileName;
  final int rowCount;
  final Uint8List bytes;
}

/// Exports running activity summaries from SQLite into a UTF-8 RFC-4180 CSV file
/// (`Phase 6 Ekspor CSV`). Credentials/cookies are never included.
class CsvExportService {
  const CsvExportService({required this.db});

  final AppDatabase db;

  Future<CsvExportPayload> buildActivitiesCsv({
    String unitSystem = 'metric',
    DateTime? exportedAtLocal,
  }) async {
    final rows = await db.getAllValidActivitiesForExport();
    final buffer = StringBuffer()
      ..writeln(
        'id,garmin_activity_id,title,sport_type,start_time_local,distance_meters,'
        'distance_formatted,duration_total_sec,duration_moving_sec,'
        'avg_pace_sec_per_km,avg_pace_formatted,avg_hr_bpm,max_hr_bpm,'
        'avg_cadence_spm,elevation_gain_m,elevation_loss_m,calories_kcal,'
        'is_indoor,source,sync_status',
      );

    for (final act in rows) {
      final localStart = act.startTimeUtc
          .toUtc()
          .add(Duration(seconds: act.utcOffsetSeconds))
          .toIso8601String();
      final sportLabel = SportType.fromCode(act.sportType).label;
      final distFormatted = UnitFormatter.formatDistanceValue(
        act.distanceMeters,
        unitSystem,
      );
      final paceFormatted = UnitFormatter.formatPaceWithUnit(
        act.avgPaceSecPerKm,
        unitSystem,
      );

      final fields = <String>[
        act.id.toString(),
        act.garminActivityId?.toString() ?? '',
        act.title,
        sportLabel,
        localStart,
        act.distanceMeters.toStringAsFixed(1),
        '$distFormatted ${UnitFormatter.distanceUnitLabel(unitSystem)}',
        act.durationTotalSec.toString(),
        act.durationMovingSec.toString(),
        act.avgPaceSecPerKm.toStringAsFixed(1),
        paceFormatted,
        act.avgHeartRate?.toStringAsFixed(1) ?? '',
        act.maxHeartRate?.toStringAsFixed(1) ?? '',
        act.avgCadence?.toStringAsFixed(1) ?? '',
        act.totalElevationGainM.toStringAsFixed(1),
        act.totalElevationLossM.toStringAsFixed(1),
        act.caloriesKcal.toString(),
        act.isIndoor.toString(),
        act.source,
        act.syncStatus,
      ];

      buffer.writeln(fields.map(_escapeCsv).join(','));
    }

    final now = exportedAtLocal ?? DateTime.now();
    final tag =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    return CsvExportPayload(
      fileName: 'fittrace_activities_$tag.csv',
      rowCount: rows.length,
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
    );
  }

  static String _escapeCsv(String value) {
    final needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

