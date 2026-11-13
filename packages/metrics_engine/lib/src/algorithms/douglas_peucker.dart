import 'dart:math' as math;

/// Iterative Douglas-Peucker polyline simplification operating in geographic meters
/// (`PRD NFR-01` zoom-bucket decimation).
class DouglasPeucker {
  const DouglasPeucker._();

  static const double _metersPerDegreeLat = 111132.0;

  /// Returns sorted original indices kept after simplifying `(latitudes, longitudes)`
  /// with perpendicular deviation [toleranceMeters].
  ///
  /// Uses an explicit stack so marathon tracks (>45,000 trackpoints) never risk
  /// recursive call-stack overflow.
  static List<int> simplifyLatLngIndices({
    required List<double> latitudes,
    required List<double> longitudes,
    required double toleranceMeters,
  }) {
    final count = latitudes.length;
    if (count == 0 || longitudes.length != count) {
      return const <int>[];
    }
    if (count <= 2 || toleranceMeters <= 0) {
      return List<int>.generate(count, (i) => i, growable: false);
    }

    final keep = List<bool>.filled(count, false);
    keep[0] = true;
    keep[count - 1] = true;

    final stack = <int>[0, count - 1];
    while (stack.isNotEmpty) {
      final end = stack.removeLast();
      final start = stack.removeLast();
      if (end - start <= 1) continue;

      final startLat = latitudes[start];
      final startLng = longitudes[start];
      final endLat = latitudes[end];
      final endLng = longitudes[end];

      final midLatRad = ((startLat + endLat) * 0.5) * math.pi / 180.0;
      final metersPerDegLng =
          _metersPerDegreeLat * math.cos(midLatRad).abs().clamp(0.15, 1.0);

      final dxEnd = (endLng - startLng) * metersPerDegLng;
      final dyEnd = (endLat - startLat) * _metersPerDegreeLat;
      final segLengthSq = dxEnd * dxEnd + dyEnd * dyEnd;

      var maxDistSq = -1.0;
      var maxIndex = -1;
      final toleranceSq = toleranceMeters * toleranceMeters;

      for (var i = start + 1; i < end; i++) {
        final px = (longitudes[i] - startLng) * metersPerDegLng;
        final py = (latitudes[i] - startLat) * _metersPerDegreeLat;

        final double distSq;
        if (segLengthSq <= 1e-9) {
          distSq = px * px + py * py;
        } else {
          final cross = dxEnd * py - dyEnd * px;
          distSq = (cross * cross) / segLengthSq;
        }

        if (distSq > maxDistSq) {
          maxDistSq = distSq;
          maxIndex = i;
        }
      }

      if (maxIndex != -1 && maxDistSq > toleranceSq) {
        keep[maxIndex] = true;
        if (maxIndex - start > 1) {
          stack
            ..add(start)
            ..add(maxIndex);
        }
        if (end - maxIndex > 1) {
          stack
            ..add(maxIndex)
            ..add(end);
        }
      }
    }

    final indices = <int>[];
    for (var i = 0; i < count; i++) {
      if (keep[i]) indices.add(i);
    }
    return indices;
  }
}

