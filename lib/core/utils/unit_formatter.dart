/// Shared Metric / Imperial formatter preserving tabular display conventions (`PRD §6.2`).
class UnitFormatter {
  const UnitFormatter._();

  static const double metersPerKm = 1000.0;
  static const double metersPerMile = 1609.344;
  static const double feetPerMeter = 3.28084;

  static bool isImperial(String? unitSystem) => unitSystem == 'imperial';

  static double convertDistanceMeters(double meters, String? unitSystem) {
    final divisor = isImperial(unitSystem) ? metersPerMile : metersPerKm;
    return meters / divisor;
  }

  static String formatDistanceValue(
    double meters,
    String? unitSystem, {
    int decimals = 2,
  }) {
    return convertDistanceMeters(meters, unitSystem).toStringAsFixed(decimals);
  }

  static String distanceUnitLabel(String? unitSystem, {bool upperCase = false}) {
    final unit = isImperial(unitSystem) ? 'mi' : 'km';
    return upperCase ? unit.toUpperCase() : unit;
  }

  static String formatPaceRaw(double paceSecPerUnit) {
    if (paceSecPerUnit <= 0 || paceSecPerUnit.isNaN || paceSecPerUnit.isInfinite) {
      return '--\'--"';
    }
    final totalSec = paceSecPerUnit.round();
    final minutes = totalSec ~/ 60;
    final seconds = totalSec % 60;
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  static String formatPace(double paceSecPerKm, String? unitSystem) {
    if (paceSecPerKm <= 0 || !paceSecPerKm.isFinite) {
      return '--\'--"';
    }
    final adjusted = isImperial(unitSystem)
        ? paceSecPerKm * (metersPerMile / metersPerKm)
        : paceSecPerKm;
    return formatPaceRaw(adjusted);
  }

  static String paceUnitSuffix(String? unitSystem) =>
      isImperial(unitSystem) ? '/mi' : '/km';

  static String formatPaceWithUnit(double paceSecPerKm, String? unitSystem) {
    return '${formatPace(paceSecPerKm, unitSystem)}${paceUnitSuffix(unitSystem)}';
  }

  static String formatElevation(
    double meters,
    String? unitSystem, {
    bool signed = false,
  }) {
    final value = isImperial(unitSystem) ? meters * feetPerMeter : meters;
    final rounded = value.round();
    final prefix = signed && rounded >= 0 ? '+' : '';
    final unit = isImperial(unitSystem) ? 'ft' : 'm';
    return '$prefix$rounded $unit';
  }

  static String formatShortDistance(double meters, String? unitSystem) {
    if (isImperial(unitSystem)) {
      final miles = meters / metersPerMile;
      if (miles >= 0.5) {
        return '${miles.toStringAsFixed(2)} mi';
      }
      final yards = (meters * 1.09361).round();
      return '$yards yd';
    }
    if (meters >= 1000) {
      return '${(meters / 1000.0).toStringAsFixed(2)} km';
    }
    return '${meters.round()} m';
  }
}
