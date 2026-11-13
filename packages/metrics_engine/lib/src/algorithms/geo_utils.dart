import 'dart:math' as math;

/// Geographic coordinate conversion and distance helpers (PRD M2-02).
class GeoUtils {
  GeoUtils._();

  static const double _earthRadiusMeters = 6371000.0;
  static const double _semicircleFactor = 180.0 / 2147483648.0;

  /// Converts FIT integer semicircles to decimal degrees.
  static double semicirclesToDegrees(int semicircles) =>
      semicircles * _semicircleFactor;

  /// Returns true when [latitudeDeg] and [longitudeDeg] are finite and within
  /// WGS-84 bounds `[-90, 90]` and `[-180, 180]`.
  static bool isValidCoordinate(double? latitudeDeg, double? longitudeDeg) {
    if (latitudeDeg == null || longitudeDeg == null) return false;
    if (!latitudeDeg.isFinite || !longitudeDeg.isFinite) return false;
    return latitudeDeg >= -90.0 &&
        latitudeDeg <= 90.0 &&
        longitudeDeg >= -180.0 &&
        longitudeDeg <= 180.0;
  }

  /// Computes great-circle distance in meters using the Haversine formula.
  static double haversineMeters(
    double lat1Deg,
    double lon1Deg,
    double lat2Deg,
    double lon2Deg,
  ) {
    final lat1 = _toRadians(lat1Deg);
    final lat2 = _toRadians(lat2Deg);
    final dLat = lat2 - lat1;
    final dLon = _toRadians(lon2Deg - lon1Deg);

    final sinHalfLat = math.sin(dLat / 2.0);
    final sinHalfLon = math.sin(dLon / 2.0);
    final a =
        sinHalfLat * sinHalfLat +
        math.cos(lat1) * math.cos(lat2) * sinHalfLon * sinHalfLon;
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(math.max(0.0, 1.0 - a)));
    return _earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}

