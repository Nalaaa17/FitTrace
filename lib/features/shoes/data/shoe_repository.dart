import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/shoe.dart';

/// Repository abstraction for shoe tracking & mileage persistence.
abstract class ShoeRepository {
  Future<List<ShoeWithUsage>> getShoesWithUsage();
  Future<ShoeWithUsage?> getShoeForActivity(int activityId);
  Future<int> insertShoe({
    required String name,
    String brand = '',
    double maxDistanceKm = 600.0,
    bool isDefault = false,
  });
  Future<void> updateShoe({
    required int id,
    required String name,
    required String brand,
    required double maxDistanceKm,
    required bool isDefault,
    required bool isRetired,
  });
  Future<void> deleteShoe(int id);
  Future<void> setDefaultShoe(int id);
  Future<void> assignShoeToActivity({
    required int activityId,
    required int? shoeId,
  });
}

class DriftShoeRepository implements ShoeRepository {
  const DriftShoeRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<ShoeWithUsage>> getShoesWithUsage() => _db.getShoesWithUsage();

  @override
  Future<ShoeWithUsage?> getShoeForActivity(int activityId) =>
      _db.getShoeForActivity(activityId);

  @override
  Future<int> insertShoe({
    required String name,
    String brand = '',
    double maxDistanceKm = 600.0,
    bool isDefault = false,
  }) =>
      _db.insertShoe(
        name: name,
        brand: brand,
        maxDistanceKm: maxDistanceKm,
        isDefault: isDefault,
      );

  @override
  Future<void> updateShoe({
    required int id,
    required String name,
    required String brand,
    required double maxDistanceKm,
    required bool isDefault,
    required bool isRetired,
  }) =>
      _db.updateShoe(
        id: id,
        name: name,
        brand: brand,
        maxDistanceKm: maxDistanceKm,
        isDefault: isDefault,
        isRetired: isRetired,
      );

  @override
  Future<void> deleteShoe(int id) => _db.deleteShoe(id);

  @override
  Future<void> setDefaultShoe(int id) => _db.setDefaultShoe(id);

  @override
  Future<void> assignShoeToActivity({
    required int activityId,
    required int? shoeId,
  }) =>
      _db.assignShoeToActivity(activityId: activityId, shoeId: shoeId);
}

final shoeRepositoryProvider = Provider<ShoeRepository>((ref) {
  return DriftShoeRepository(ref.watch(appDatabaseProvider));
});
