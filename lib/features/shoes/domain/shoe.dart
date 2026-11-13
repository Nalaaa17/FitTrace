class Shoe {
  const Shoe({
    required this.id,
    required this.name,
    this.brand = '',
    this.maxDistanceKm = 600.0,
    this.isDefault = false,
    this.isRetired = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String brand;
  final double maxDistanceKm;
  final bool isDefault;
  final bool isRetired;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shoe copyWith({
    int? id,
    String? name,
    String? brand,
    double? maxDistanceKm,
    bool? isDefault,
    bool? isRetired,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shoe(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      isDefault: isDefault ?? this.isDefault,
      isRetired: isRetired ?? this.isRetired,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ShoeWithUsage {
  const ShoeWithUsage({
    required this.shoe,
    required this.totalDistanceMeters,
    required this.activitiesCount,
  });

  final Shoe shoe;
  final double totalDistanceMeters;
  final int activitiesCount;

  double get currentDistanceKm => totalDistanceMeters / 1000.0;

  double get wearRatio =>
      shoe.maxDistanceKm > 0 ? currentDistanceKm / shoe.maxDistanceKm : 0.0;

  double get wearPercent => wearRatio * 100.0;

  /// Alert if shoe has reached or exceeded max distance (e.g. 500-800km).
  bool get isAlertWorn => currentDistanceKm >= shoe.maxDistanceKm;

  /// Warning if shoe has reached 85% of its lifespan.
  bool get isNearLimit => !isAlertWorn && wearRatio >= 0.85;

  double get remainingKm =>
      (shoe.maxDistanceKm - currentDistanceKm).clamp(0.0, double.infinity);
}

