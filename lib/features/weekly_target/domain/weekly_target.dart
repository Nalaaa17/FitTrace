class WeeklyTargetProgress {
  const WeeklyTargetProgress({
    required this.targetKm,
    required this.currentKm,
    required this.activityCount,
    required this.weekStartUtc,
    required this.weekEndUtc,
    required this.daysRemainingInWeek,
  });

  final double targetKm;
  final double currentKm;
  final int activityCount;
  final DateTime weekStartUtc;
  final DateTime weekEndUtc;
  final int daysRemainingInWeek;

  double get progressPercent =>
      targetKm > 0 ? (currentKm / targetKm).clamp(0.0, 1.0) : 0.0;

  double get progressRatioRaw => targetKm > 0 ? (currentKm / targetKm) : 0.0;

  bool get isAchieved => currentKm >= targetKm && targetKm > 0;

  double get remainingKm =>
      (targetKm - currentKm).clamp(0.0, double.infinity);
}

