import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Repository abstraction for weekly running distance targets.
abstract class WeeklyTargetRepository {
  Future<double> getWeeklyTargetKm();
  Future<void> setWeeklyTargetKm(double targetKm);
  Future<double> getDistanceMetersBetween({
    required DateTime startUtc,
    required DateTime endUtc,
  });
  Future<int> getActivityCountBetween({
    required DateTime startUtc,
    required DateTime endUtc,
  });
}

class DriftWeeklyTargetRepository implements WeeklyTargetRepository {
  const DriftWeeklyTargetRepository(this._db);

  final AppDatabase _db;

  @override
  Future<double> getWeeklyTargetKm() => _db.getWeeklyTargetKm();

  @override
  Future<void> setWeeklyTargetKm(double targetKm) =>
      _db.setWeeklyTargetKm(targetKm);

  @override
  Future<double> getDistanceMetersBetween({
    required DateTime startUtc,
    required DateTime endUtc,
  }) =>
      _db.getDistanceMetersBetween(startUtc: startUtc, endUtc: endUtc);

  @override
  Future<int> getActivityCountBetween({
    required DateTime startUtc,
    required DateTime endUtc,
  }) =>
      _db.getActivityCountBetween(startUtc: startUtc, endUtc: endUtc);
}

final weeklyTargetRepositoryProvider = Provider<WeeklyTargetRepository>((ref) {
  return DriftWeeklyTargetRepository(ref.watch(appDatabaseProvider));
});
