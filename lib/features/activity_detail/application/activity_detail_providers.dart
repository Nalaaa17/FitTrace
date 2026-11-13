import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../presentation/widgets/cached_osm_tile_provider.dart';

/// Overrideable tile provider factory for offline testing vs live OSM caching.
final mapTileProviderFactoryProvider = Provider<TileProvider Function()>((ref) {
  return CachedOsmTileProvider.new;
});

/// Zoom-level buckets governing Douglas-Peucker simplification tolerances (`PRD NFR-01`: 1–5 m).
enum MapZoomBucket {
  overview(toleranceMeters: 5.0),
  city(toleranceMeters: 2.5),
  street(toleranceMeters: 1.0);

  const MapZoomBucket({required this.toleranceMeters});

  final double toleranceMeters;

  static MapZoomBucket forZoom(double zoom) {
    if (zoom < 12.5) return MapZoomBucket.overview;
    if (zoom < 14.5) return MapZoomBucket.city;
    return MapZoomBucket.street;
  }
}

/// Downsampled data point used by the synchronized multi-metric chart (`PRD NFR-01`).
class ChartSamplePoint {
  const ChartSamplePoint({
    required this.sourceIndex,
    required this.distanceMeters,
    required this.paceSecPerKm,
    required this.altitudeM,
    required this.heartRateBpm,
    required this.latitudeDeg,
    required this.longitudeDeg,
  });

  final int sourceIndex;
  final double distanceMeters;
  final double? paceSecPerKm;
  final double altitudeM;
  final int? heartRateBpm;
  final double latitudeDeg;
  final double longitudeDeg;
}

/// Polyline segment grouped by pace intensity `[0.0 = slowest .. 1.0 = fastest]`.
class MapRouteSegment {
  const MapRouteSegment({
    required this.points,
    required this.paceIntensity,
  });

  final List<LatLng> points;
  final double paceIntensity;
}

class ActivityDetailBundle {
  const ActivityDetailBundle({
    required this.activity,
    required this.lapSplits,
    required this.chartPoints,
    required this.mapSegments,
    this.segmentsByZoom = const <MapZoomBucket, List<MapRouteSegment>>{},
    required this.startPoint,
    required this.endPoint,
    required this.boundsPoints,
  });

  final ActivityRecord activity;
  final List<LapSplitRecord> lapSplits;
  final List<ChartSamplePoint> chartPoints;
  final List<MapRouteSegment> mapSegments;
  final Map<MapZoomBucket, List<MapRouteSegment>> segmentsByZoom;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final List<LatLng> boundsPoints;

  List<MapRouteSegment> segmentsForBucket(MapZoomBucket bucket) =>
      segmentsByZoom[bucket] ?? mapSegments;
}

/// Sendable trackpoint value class safe for passing across Isolate boundaries.
class RawDetailPointTransfer {
  const RawDetailPointTransfer({
    required this.lat,
    required this.lng,
    required this.alt,
    required this.speed,
    required this.hr,
    required this.dist,
  });

  final double lat;
  final double lng;
  final double alt;
  final double speed;
  final int? hr;
  final int dist;
}

class PreparedDetailGeometry {
  const PreparedDetailGeometry({
    required this.chartPoints,
    required this.mapSegments,
    required this.segmentsByZoom,
    required this.boundsPoints,
  });

  final List<ChartSamplePoint> chartPoints;
  final List<MapRouteSegment> mapSegments;
  final Map<MapZoomBucket, List<MapRouteSegment>> segmentsByZoom;
  final List<LatLng> boundsPoints;
}

Future<PreparedDetailGeometry> _runPrepareGeometryIsolate({
  required List<RawDetailPointTransfer> raw,
  required bool hasGps,
}) {
  return Isolate.run(
    () => prepareDetailGeometrySync(raw: raw, hasGps: hasGps),
  );
}

/// Computes `<= 1.000`-point min/max chart samples AND all 3 Douglas-Peucker zoom
/// buckets (`5.0 m`, `2.5 m`, `1.0 m`) split per km (`<= 42` segments) in one pass.
@visibleForTesting
PreparedDetailGeometry prepareDetailGeometrySync({
  required List<RawDetailPointTransfer> raw,
  required bool hasGps,
}) {
  final chartPoints = _downsampleForChart(raw, maxPoints: 1000);
  if (!hasGps || raw.length < 2) {
    return PreparedDetailGeometry(
      chartPoints: chartPoints,
      mapSegments: const <MapRouteSegment>[],
      segmentsByZoom: const <MapZoomBucket, List<MapRouteSegment>>{},
      boundsPoints: const <LatLng>[],
    );
  }

  final latitudes = List<double>.generate(
    raw.length,
    (i) => raw[i].lat,
    growable: false,
  );
  final longitudes = List<double>.generate(
    raw.length,
    (i) => raw[i].lng,
    growable: false,
  );

  final validSpeeds = raw
      .map((p) => p.speed)
      .where((s) => s >= 0.5)
      .toList(growable: false)
    ..sort();
  final minSpeed = validSpeeds.isNotEmpty ? validSpeeds.first : 1.0;
  final maxSpeed = validSpeeds.isNotEmpty ? validSpeeds.last : 5.0;
  final speedSpan = math.max(0.5, maxSpeed - minSpeed);

  final segmentsByZoom = <MapZoomBucket, List<MapRouteSegment>>{};
  List<LatLng> boundsPoints = const <LatLng>[];

  for (final bucket in MapZoomBucket.values) {
    final keptIndices = DouglasPeucker.simplifyLatLngIndices(
      latitudes: latitudes,
      longitudes: longitudes,
      toleranceMeters: bucket.toleranceMeters,
    );
    final simplified = keptIndices
        .map((idx) => raw[idx])
        .toList(growable: false);

    if (bucket == MapZoomBucket.overview) {
      boundsPoints = simplified
          .map((pt) => LatLng(pt.lat, pt.lng))
          .toList(growable: false);
    }

    segmentsByZoom[bucket] = _buildDistanceSplitSegments(
      simplified,
      minSpeed: minSpeed,
      speedSpan: speedSpan,
      maxSegments: 42,
    );
  }

  final defaultSegments =
      segmentsByZoom[MapZoomBucket.city] ?? const <MapRouteSegment>[];

  return PreparedDetailGeometry(
    chartPoints: chartPoints,
    mapSegments: defaultSegments,
    segmentsByZoom: segmentsByZoom,
    boundsPoints: boundsPoints,
  );
}

/// Min/max speed bucket downsampling guaranteed to emit `<= maxPoints` (PRD NFR-01).
List<ChartSamplePoint> _downsampleForChart(
  List<RawDetailPointTransfer> raw, {
  int maxPoints = 1000,
}) {
  if (raw.isEmpty) return const <ChartSamplePoint>[];
  if (raw.length <= maxPoints) {
    return List<ChartSamplePoint>.generate(
      raw.length,
      (i) => _toChartPoint(i, raw[i]),
      growable: false,
    );
  }

  final bucketCount = maxPoints ~/ 2;
  final bucketSize = raw.length / bucketCount;
  final result = <ChartSamplePoint>[];

  for (var b = 0; b < bucketCount; b++) {
    final start = (b * bucketSize).floor();
    final end = math.min(raw.length, ((b + 1) * bucketSize).floor());
    if (start >= end) continue;

    var minIdx = start;
    var maxIdx = start;
    for (var i = start + 1; i < end; i++) {
      if (raw[i].speed < raw[minIdx].speed) minIdx = i;
      if (raw[i].speed > raw[maxIdx].speed) maxIdx = i;
    }

    if (minIdx == maxIdx) {
      result.add(_toChartPoint(minIdx, raw[minIdx]));
    } else if (minIdx < maxIdx) {
      result.add(_toChartPoint(minIdx, raw[minIdx]));
      result.add(_toChartPoint(maxIdx, raw[maxIdx]));
    } else {
      result.add(_toChartPoint(maxIdx, raw[maxIdx]));
      result.add(_toChartPoint(minIdx, raw[minIdx]));
    }
  }

  return result;
}

ChartSamplePoint _toChartPoint(int index, RawDetailPointTransfer pt) {
  final double? pace =
      pt.speed >= 0.4 ? (1000.0 / pt.speed).clamp(120.0, 1200.0) : null;
  return ChartSamplePoint(
    sourceIndex: index,
    distanceMeters: pt.dist.toDouble(),
    paceSecPerKm: pace,
    altitudeM: pt.alt,
    heartRateBpm: pt.hr,
    latitudeDeg: pt.lat,
    longitudeDeg: pt.lng,
  );
}

/// Groups simplified trackpoints per ~1,000 m split (`<= maxSegments` total, PRD NFR-01).
List<MapRouteSegment> _buildDistanceSplitSegments(
  List<RawDetailPointTransfer> points, {
  required double minSpeed,
  required double speedSpan,
  int maxSegments = 42,
}) {
  if (points.length < 2) return const <MapRouteSegment>[];

  final startDist = points.first.dist;
  final totalSpanM = (points.last.dist - startDist).toDouble();
  if (totalSpanM <= 0) {
    final avgSpeed = _averageActiveSpeed(points, 0, points.length - 1, minSpeed);
    final intensity = ((avgSpeed - minSpeed) / speedSpan).clamp(0.0, 1.0);
    return <MapRouteSegment>[
      MapRouteSegment(
        points: points.map((p) => LatLng(p.lat, p.lng)).toList(growable: false),
        paceIntensity: intensity,
      ),
    ];
  }

  final segmentDistanceM = math.max(1000.0, totalSpanM / maxSegments);
  final segments = <MapRouteSegment>[];

  var segStart = 0;
  var currentBucket = 0;

  for (var i = 1; i < points.length; i++) {
    final bucketIdx = ((points[i].dist - startDist) / segmentDistanceM)
        .floor()
        .clamp(0, maxSegments - 1);
    final isLast = i == points.length - 1;

    if (bucketIdx > currentBucket || isLast) {
      final endIdx = i;
      if (endIdx > segStart) {
        final avgSpeed = _averageActiveSpeed(points, segStart, endIdx, minSpeed);
        final intensity = ((avgSpeed - minSpeed) / speedSpan).clamp(0.0, 1.0);
        segments.add(
          MapRouteSegment(
            points: points
                .sublist(segStart, endIdx + 1)
                .map((p) => LatLng(p.lat, p.lng))
                .toList(growable: false),
            paceIntensity: intensity,
          ),
        );
        segStart = endIdx;
      }
      currentBucket = bucketIdx;
    }
  }

  return segments;
}

double _averageActiveSpeed(
  List<RawDetailPointTransfer> points,
  int start,
  int end,
  double fallback,
) {
  var sum = 0.0;
  var count = 0;
  for (var i = start; i <= end; i++) {
    if (points[i].speed >= 0.5) {
      sum += points[i].speed;
      count++;
    }
  }
  return count > 0 ? sum / count : fallback;
}

final activityDetailProvider =
    FutureProvider.family<ActivityDetailBundle?, int>((ref, activityId) async {
  final db = ref.watch(appDatabaseProvider);
  final activity = await db.getActivityById(activityId);
  if (activity == null) return null;

  final splits = await db.getLapSplitsForActivity(activityId);
  final rawRecords = await db.getTrackPointsForActivity(activityId);

  final transfers = rawRecords
      .map(
        (r) => RawDetailPointTransfer(
          lat: r.latitudeDeg,
          lng: r.longitudeDeg,
          alt: r.altitudeM,
          speed: r.speedMps,
          hr: r.heartRateBpm,
          dist: r.distanceMeters,
        ),
      )
      .toList(growable: false);

  final hasGps = !activity.isIndoor && activity.hasGpsTrack;

  final prepared = transfers.length > 2000
      ? await _runPrepareGeometryIsolate(raw: transfers, hasGps: hasGps)
      : prepareDetailGeometrySync(raw: transfers, hasGps: hasGps);

  LatLng? startPt;
  LatLng? endPt;
  if (hasGps && transfers.isNotEmpty) {
    startPt = LatLng(transfers.first.lat, transfers.first.lng);
    endPt = LatLng(transfers.last.lat, transfers.last.lng);
  }

  return ActivityDetailBundle(
    activity: activity,
    lapSplits: splits,
    chartPoints: prepared.chartPoints,
    mapSegments: prepared.mapSegments,
    segmentsByZoom: prepared.segmentsByZoom,
    startPoint: startPt,
    endPoint: endPt,
    boundsPoints: prepared.boundsPoints,
  );
});
