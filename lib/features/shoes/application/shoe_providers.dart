import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../domain/shoe.dart';

/// Manages the list of shoes with their real-time usage and mileage.
class ShoesNotifier extends AsyncNotifier<List<ShoeWithUsage>> {
  @override
  Future<List<ShoeWithUsage>> build() async {
    final db = ref.watch(appDatabaseProvider);
    return db.getShoesWithUsage();
  }

  Future<void> addShoe({
    required String name,
    String brand = '',
    double maxDistanceKm = 600.0,
    bool isDefault = false,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await db.insertShoe(
      name: name,
      brand: brand,
      maxDistanceKm: maxDistanceKm,
      isDefault: isDefault,
    );
    ref.invalidateSelf();
  }

  Future<void> updateShoe({
    required int id,
    required String name,
    required String brand,
    required double maxDistanceKm,
    required bool isDefault,
    required bool isRetired,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await db.updateShoe(
      id: id,
      name: name,
      brand: brand,
      maxDistanceKm: maxDistanceKm,
      isDefault: isDefault,
      isRetired: isRetired,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteShoe(int id) async {
    final db = ref.read(appDatabaseProvider);
    await db.deleteShoe(id);
    ref.invalidateSelf();
  }

  Future<void> setDefaultShoe(int id) async {
    final db = ref.read(appDatabaseProvider);
    await db.setDefaultShoe(id);
    ref.invalidateSelf();
  }
}

final shoesNotifierProvider =
    AsyncNotifierProvider<ShoesNotifier, List<ShoeWithUsage>>(
  ShoesNotifier.new,
);

/// Provides the shoe linked to a specific activity.
final activityShoeProvider =
    FutureProvider.family<ShoeWithUsage?, int>((ref, activityId) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getShoeForActivity(activityId);
});

/// Controller to assign a shoe to an activity.
final assignShoeControllerProvider = Provider((ref) {
  return (int activityId, int? shoeId) async {
    final db = ref.read(appDatabaseProvider);
    await db.assignShoeToActivity(activityId: activityId, shoeId: shoeId);
    ref.invalidate(activityShoeProvider(activityId));
    ref.invalidate(shoesNotifierProvider);
  };
});

