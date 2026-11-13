/// Heart-rate zone configuration following PRD M2-06 and ADR-004.
class HrZoneConfig {
  const HrZoneConfig({
    required this.hrMaxBpm,
    this.isEstimated = false,
    this.zoneThresholdsPercent = defaultThresholdsPercent,
  }) : assert(zoneThresholdsPercent.length == 4, 'Must define Z2..Z5 lower %');

  static const int defaultFallbackHrMax = 190;
  static const List<int> defaultThresholdsPercent = <int>[60, 70, 80, 90];

  final int hrMaxBpm;
  final bool isEstimated;
  final List<int> zoneThresholdsPercent;

  /// Resolves HRmax using manual override -> 220 - age -> 190 bpm fallback.
  factory HrZoneConfig.resolve({
    int? hrMaxManual,
    DateTime? birthDate,
    DateTime? referenceDate,
    List<int> thresholdsPercent = defaultThresholdsPercent,
  }) {
    if (hrMaxManual != null && hrMaxManual > 0) {
      return HrZoneConfig(
        hrMaxBpm: hrMaxManual,
        isEstimated: false,
        zoneThresholdsPercent: thresholdsPercent,
      );
    }
    if (birthDate != null) {
      final now = referenceDate ?? DateTime.now().toUtc();
      var age = now.year - birthDate.year;
      final hadBirthdayThisYear =
          now.month > birthDate.month ||
          (now.month == birthDate.month && now.day >= birthDate.day);
      if (!hadBirthdayThisYear) {
        age -= 1;
      }
      if (age > 0 && age < 120) {
        return HrZoneConfig(
          hrMaxBpm: (220 - age).clamp(100, 220),
          isEstimated: true,
          zoneThresholdsPercent: thresholdsPercent,
        );
      }
    }
    return HrZoneConfig(
      hrMaxBpm: defaultFallbackHrMax,
      isEstimated: true,
      zoneThresholdsPercent: thresholdsPercent,
    );
  }

  /// Classifies a heart rate value in BPM into Zone 1..5.
  int zoneForHeartRate(int heartRateBpm) {
    final pct = (heartRateBpm / hrMaxBpm) * 100.0;
    if (pct < zoneThresholdsPercent[0]) return 1;
    if (pct < zoneThresholdsPercent[1]) return 2;
    if (pct < zoneThresholdsPercent[2]) return 3;
    if (pct < zoneThresholdsPercent[3]) return 4;
    return 5;
  }
}

