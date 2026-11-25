import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../activity_detail/application/activity_detail_providers.dart';

enum RouteExportFormat { gpx, tcx, geoJson }

/// Exports an activity's GPS trackpoints into `.gpx`, `.tcx`, or `.geojson`.
class RouteExportService {
  const RouteExportService();

  String toGpx(ActivityRecord act, List<TrackPointRecord> trackPoints) {
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="FitTrace" xmlns="http://www.topografix.com/GPX/1/1">')
      ..writeln('  <metadata>')
      ..writeln('    <name>${_escapeXml(act.title)}</name>')
      ..writeln('    <time>${act.startTimeUtc.toUtc().toIso8601String()}</time>')
      ..writeln('  </metadata>')
      ..writeln('  <trk>')
      ..writeln('    <name>${_escapeXml(act.title)}</name>')
      ..writeln('    <trkseg>');

    for (final pt in trackPoints) {
      buf
        ..writeln('      <trkpt lat="${pt.latitudeDeg}" lon="${pt.longitudeDeg}">')
        ..writeln('        <ele>${pt.altitudeM.toStringAsFixed(1)}</ele>')
        ..writeln('        <time>${pt.timestampUtc.toUtc().toIso8601String()}</time>')
        ..writeln('      </trkpt>');
    }

    buf
      ..writeln('    </trkseg>')
      ..writeln('  </trk>')
      ..writeln('</gpx>');
    return buf.toString();
  }

  String toTcx(ActivityRecord act, List<TrackPointRecord> trackPoints) {
    final startIso = act.startTimeUtc.toUtc().toIso8601String();
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">')
      ..writeln('  <Activities>')
      ..writeln('    <Activity Sport="Running">')
      ..writeln('      <Id>$startIso</Id>')
      ..writeln('      <Lap StartTime="$startIso">')
      ..writeln('        <TotalTimeSeconds>${act.durationTotalSec}</TotalTimeSeconds>')
      ..writeln('        <DistanceMeters>${act.distanceMeters.toStringAsFixed(1)}</DistanceMeters>')
      ..writeln('        <Calories>${act.caloriesKcal}</Calories>')
      ..writeln('        <Track>');

    for (final pt in trackPoints) {
      buf
        ..writeln('          <Trackpoint>')
        ..writeln('            <Time>${pt.timestampUtc.toUtc().toIso8601String()}</Time>')
        ..writeln('            <Position>')
        ..writeln('              <LatitudeDegrees>${pt.latitudeDeg}</LatitudeDegrees>')
        ..writeln('              <LongitudeDegrees>${pt.longitudeDeg}</LongitudeDegrees>')
        ..writeln('            </Position>')
        ..writeln('            <AltitudeMeters>${pt.altitudeM.toStringAsFixed(1)}</AltitudeMeters>')
        ..writeln('            <DistanceMeters>${pt.distanceMeters}</DistanceMeters>');
      if (pt.heartRateBpm != null) {
        buf
          ..writeln('            <HeartRateBpm>')
          ..writeln('              <Value>${pt.heartRateBpm}</Value>')
          ..writeln('            </HeartRateBpm>');
      }
      buf.writeln('          </Trackpoint>');
    }

    buf
      ..writeln('        </Track>')
      ..writeln('      </Lap>')
      ..writeln('    </Activity>')
      ..writeln('  </Activities>')
      ..writeln('</TrainingCenterDatabase>');
    return buf.toString();
  }

  String toGeoJson(ActivityRecord act, List<TrackPointRecord> trackPoints) {
    final coords = trackPoints
        .map((pt) => <double>[pt.longitudeDeg, pt.latitudeDeg, pt.altitudeM])
        .toList(growable: false);

    final geojson = <String, dynamic>{
      'type': 'FeatureCollection',
      'features': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'Feature',
          'properties': <String, dynamic>{
            'title': act.title,
            'startTimeUtc': act.startTimeUtc.toUtc().toIso8601String(),
            'distanceMeters': act.distanceMeters,
            'durationMovingSec': act.durationMovingSec,
          },
          'geometry': <String, dynamic>{
            'type': 'LineString',
            'coordinates': coords,
          },
        },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(geojson);
  }

  Future<Uri?> exportAndSave({
    required AppDatabase db,
    required ActivityDetailBundle bundle,
    required RouteExportFormat format,
  }) async {
    final trackPoints = await db.getTrackPointsForActivity(bundle.activity.id);
    final safeName = bundle.activity.title
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .toLowerCase();
    final (ext, content) = switch (format) {
      RouteExportFormat.gpx => ('gpx', toGpx(bundle.activity, trackPoints)),
      RouteExportFormat.tcx => ('tcx', toTcx(bundle.activity, trackPoints)),
      RouteExportFormat.geoJson =>
        ('geojson', toGeoJson(bundle.activity, trackPoints)),
    };
    final bytes = Uint8List.fromList(utf8.encode(content));
    return FilePicker.saveFile(
      dialogTitle: 'Ekspor Rute .$ext',
      fileName: '${safeName}_${bundle.activity.id}.$ext',
      bytes: bytes,
    );
  }

  static String _escapeXml(String raw) => raw
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

final routeExportServiceProvider = Provider<RouteExportService>((ref) {
  return const RouteExportService();
});
