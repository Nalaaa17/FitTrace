import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/activity_detail_providers.dart';
import 'cached_osm_tile_provider.dart';

/// Monochrome route map with Douglas-Peucker zoom-bucket switching, pace-intensity
/// polyline segments, start/finish markers, and synchronized chart marker
/// (`PRD M3-03`, `M3-04`, `NFR-01`).
class ActivityRouteMap extends StatefulWidget {
  const ActivityRouteMap({
    super.key,
    required this.bundle,
    required this.selectedPoint,
    this.tileProvider,
  });

  final ActivityDetailBundle bundle;
  final ChartSamplePoint? selectedPoint;
  final TileProvider? tileProvider;

  @override
  State<ActivityRouteMap> createState() => _ActivityRouteMapState();
}

class _ActivityRouteMapState extends State<ActivityRouteMap> {
  MapZoomBucket _zoomBucket = MapZoomBucket.city;

  // Desaturate + invert matrix so OSM streets render crisp monochrome in dark mode.
  static const ColorFilter _darkMonochromeMatrix = ColorFilter.matrix(<double>[
    -0.2126, -0.7152, -0.0722, 0, 255,
    -0.2126, -0.7152, -0.0722, 0, 255,
    -0.2126, -0.7152, -0.0722, 0, 255,
    0,       0,       0,       1, 0,
  ]);

  static const ColorFilter _lightMonochromeMatrix = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bundle = widget.bundle;
    final selectedPoint = widget.selectedPoint;

    if (bundle.activity.isIndoor ||
        !bundle.activity.hasGpsTrack ||
        bundle.boundsPoints.length < 2) {
      return Card(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.directions_run_rounded,
                  size: 32,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 10),
                Text(
                  'INDOOR — NO ROUTE',
                  style: AppTypography.metricLabel(colors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aktivitas direkam tanpa data koordinat GPS.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bounds = LatLngBounds.fromPoints(bundle.boundsPoints);
    final activeSegments = bundle.segmentsForBucket(_zoomBucket);
    final polylines = activeSegments.map((seg) {
      final color = _paceColor(seg.paceIntensity, isDark: isDark);
      return Polyline(
        points: seg.points,
        color: color,
        strokeWidth: 3.5 + seg.paceIntensity * 1.5,
      );
    }).toList(growable: false);

    final markers = <Marker>[
      if (bundle.startPoint != null)
        Marker(
          point: bundle.startPoint!,
          width: 16,
          height: 16,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accentSharp,
              border: Border.all(color: colors.bgBase, width: 2),
            ),
          ),
        ),
      if (bundle.endPoint != null)
        Marker(
          point: bundle.endPoint!,
          width: 18,
          height: 18,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.bgBase,
              border: Border.all(color: colors.accentSharp, width: 3),
            ),
          ),
        ),
      if (selectedPoint != null)
        Marker(
          point: LatLng(
            selectedPoint.latitudeDeg,
            selectedPoint.longitudeDeg,
          ),
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accentSharp.withValues(alpha: 0.25),
              border: Border.all(color: colors.accentSharp, width: 2),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.accentSharp,
                ),
              ),
            ),
          ),
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          border: Border.all(color: colors.hairlineBorder),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: Stack(
          children: <Widget>[
            FlutterMap(
              options: MapOptions(
                backgroundColor: colors.bgElevated,
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(28),
                ),
                onPositionChanged: (camera, _) {
                  final nextBucket = MapZoomBucket.forZoom(camera.zoom);
                  if (nextBucket != _zoomBucket && mounted) {
                    setState(() => _zoomBucket = nextBucket);
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: <Widget>[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.fittrace.app',
                  tileProvider: widget.tileProvider ?? CachedOsmTileProvider(),
                  tileBuilder: (context, tileWidget, tile) {
                    return ColorFiltered(
                      colorFilter: isDark
                          ? _darkMonochromeMatrix
                          : _lightMonochromeMatrix,
                      child: Opacity(
                        opacity: isDark ? 0.42 : 0.65,
                        child: tileWidget,
                      ),
                    );
                  },
                ),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgBase.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.hairlineBorder),
                ),
                child: Text(
                  'LAMBAT — CEPAT',
                  style: AppTypography.chartAxis(colors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _paceColor(double intensity, {required bool isDark}) {
    if (isDark) {
      return Color.lerp(
        const Color(0xFF5A5A5A),
        const Color(0xFFFFFFFF),
        intensity,
      )!;
    }
    return Color.lerp(
      const Color(0xFF9E9E9E),
      const Color(0xFF000000),
      intensity,
    )!;
  }
}

