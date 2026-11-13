import 'package:drift/native.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/features/shoes/domain/shoe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_engine/metrics_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Shoe domain model calculates wear ratio, alert, and remaining km correctly', () {
    final now = DateTime(2026, 1, 1);
    final freshShoe = Shoe(
      id: 1,
      name: 'Pegasus 40',
      brand: 'Nike',
      maxDistanceKm: 600.0,
      createdAt: now,
      updatedAt: now,
    );

    final freshUsage = ShoeWithUsage(
      shoe: freshShoe,
      totalDistanceMeters: 300000.0, // 300 km
      activitiesCount: 30,
    );

    expect(freshUsage.currentDistanceKm, equals(300.0));
    expect(freshUsage.wearRatio, closeTo(0.5, 0.001));
    expect(freshUsage.wearPercent, closeTo(50.0, 0.001));
    expect(freshUsage.isAlertWorn, isFalse);
    expect(freshUsage.isNearLimit, isFalse);
    expect(freshUsage.remainingKm, closeTo(300.0, 0.001));

    // Near limit (85%)
    final nearUsage = ShoeWithUsage(
      shoe: freshShoe,
      totalDistanceMeters: 520000.0, // 520 km
      activitiesCount: 52,
    );
    expect(nearUsage.isNearLimit, isTrue);
    expect(nearUsage.isAlertWorn, isFalse);

    // Over limit (620 km out of 600 km) -> Alert!
    final wornUsage = ShoeWithUsage(
      shoe: freshShoe,
      totalDistanceMeters: 620000.0,
      activitiesCount: 60,
    );
    expect(wornUsage.isAlertWorn, isTrue);
    expect(wornUsage.remainingKm, equals(0.0));
  });

  test('SQLite CRUD for shoes and activity mileage tracking', () async {
    // 1. Insert shoes
    final shoe1Id = await db.insertShoe(
      name: 'Vaporfly 3',
      brand: 'Nike',
      maxDistanceKm: 400.0,
      isDefault: true,
    );
    final shoe2Id = await db.insertShoe(
      name: 'Novablast 4',
      brand: 'Asics',
      maxDistanceKm: 800.0,
      isDefault: false,
    );

    expect(shoe1Id, isPositive);
    expect(shoe2Id, isPositive);

    var defaultShoe = await db.getDefaultShoe();
    expect(defaultShoe?.id, equals(shoe1Id));
    expect(defaultShoe?.name, equals('Vaporfly 3'));

    // 2. Set shoe2 as default
    await db.setDefaultShoe(shoe2Id);
    defaultShoe = await db.getDefaultShoe();
    expect(defaultShoe?.id, equals(shoe2Id));

    // 3. Insert activity and assign to shoe1
    final now = DateTime.now().toUtc();
    final actId = await db.insertParsedActivity(
      parsed: ParsedActivity(
        title: 'Morning 10K',
        sportType: SportType.run,
        startTimeUtc: now,
        utcOffsetSeconds: 0,
        durationTotalSec: 3000,
        durationMovingSec: 3000,
        distanceMeters: 10000.0,
        avgPaceSecPerKm: 300.0,
        totalElevationGainM: 50.0,
        totalElevationLossM: 50.0,
        caloriesKcal: 600,
        isIndoor: false,
        hasGpsTrack: false,
        gpsQuality: GpsQuality.none,
        trackPoints: const <ParsedTrackPoint>[],
        lapSplits: const <ParsedLapSplit>[],
        bestEfforts: const <BestEffortSegment>[],
        splitPacesSecPerKm: const <int>[],
        zoneDurationsSec: const <int>[0, 0, 0, 0, 0],
      ),
      source: ActivitySource.manualImport,
      syncStatus: SyncStatus.synced,
      fitFileHash: 'fit_hash_shoes_test_1',
    );

    await db.assignShoeToActivity(activityId: actId, shoeId: shoe1Id);

    // 4. Verify shoe with usage
    final shoeUsage = await db.getShoeForActivity(actId);
    expect(shoeUsage, isNotNull);
    expect(shoeUsage!.shoe.id, equals(shoe1Id));
    expect(shoeUsage.totalDistanceMeters, equals(10000.0));
    expect(shoeUsage.currentDistanceKm, equals(10.0));
    expect(shoeUsage.activitiesCount, equals(1));

    final allShoes = await db.getShoesWithUsage();
    expect(allShoes.length, equals(2));
    final s1 = allShoes.firstWhere((s) => s.shoe.id == shoe1Id);
    expect(s1.currentDistanceKm, equals(10.0));

    // 5. Update shoe
    await db.updateShoe(
      id: shoe1Id,
      name: 'Vaporfly 3 Ekiden',
      brand: 'Nike',
      maxDistanceKm: 450.0,
      isDefault: false,
      isRetired: false,
    );

    final updated = await db.getShoeForActivity(actId);
    expect(updated?.shoe.name, equals('Vaporfly 3 Ekiden'));

    // 6. Delete shoe (should unlink from activity, not crash)
    await db.deleteShoe(shoe1Id);
    final afterDelete = await db.getShoeForActivity(actId);
    expect(afterDelete, isNull);
  });
}
