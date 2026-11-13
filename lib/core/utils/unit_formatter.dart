import '../../features/feed/application/feed_providers.dart' as feed_fmt;

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

  static String formatPace(double paceSecPerKm, String? unitSystem) {
    if (paceSecPerKm <= 0 || !paceSecPerKm.isFinite) {
      return '--\'--"';
    }
    final adjusted = isImperial(unitSystem)
        ? paceSecPerKm * (metersPerMile / metersPerKm)
        : paceSecPerKm;
    return feed_fmt.formatPace(adjusted);
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
}
