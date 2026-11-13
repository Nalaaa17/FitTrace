// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, ActivityRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _garminActivityIdMeta = const VerificationMeta(
    'garminActivityId',
  );
  @override
  late final GeneratedColumn<int> garminActivityId = GeneratedColumn<int>(
    'garmin_activity_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sportTypeMeta = const VerificationMeta(
    'sportType',
  );
  @override
  late final GeneratedColumn<int> sportType = GeneratedColumn<int>(
    'sport_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeUtcMeta = const VerificationMeta(
    'startTimeUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startTimeUtc = GeneratedColumn<DateTime>(
    'start_time_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _utcOffsetSecondsMeta = const VerificationMeta(
    'utcOffsetSeconds',
  );
  @override
  late final GeneratedColumn<int> utcOffsetSeconds = GeneratedColumn<int>(
    'utc_offset_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationTotalSecMeta = const VerificationMeta(
    'durationTotalSec',
  );
  @override
  late final GeneratedColumn<int> durationTotalSec = GeneratedColumn<int>(
    'duration_total_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMovingSecMeta = const VerificationMeta(
    'durationMovingSec',
  );
  @override
  late final GeneratedColumn<int> durationMovingSec = GeneratedColumn<int>(
    'duration_moving_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgPaceSecPerKmMeta = const VerificationMeta(
    'avgPaceSecPerKm',
  );
  @override
  late final GeneratedColumn<double> avgPaceSecPerKm = GeneratedColumn<double>(
    'avg_pace_sec_per_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgHeartRateMeta = const VerificationMeta(
    'avgHeartRate',
  );
  @override
  late final GeneratedColumn<double> avgHeartRate = GeneratedColumn<double>(
    'avg_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxHeartRateMeta = const VerificationMeta(
    'maxHeartRate',
  );
  @override
  late final GeneratedColumn<double> maxHeartRate = GeneratedColumn<double>(
    'max_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgCadenceMeta = const VerificationMeta(
    'avgCadence',
  );
  @override
  late final GeneratedColumn<double> avgCadence = GeneratedColumn<double>(
    'avg_cadence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalElevationGainMMeta =
      const VerificationMeta('totalElevationGainM');
  @override
  late final GeneratedColumn<double> totalElevationGainM =
      GeneratedColumn<double>(
        'total_elevation_gain_m',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _totalElevationLossMMeta =
      const VerificationMeta('totalElevationLossM');
  @override
  late final GeneratedColumn<double> totalElevationLossM =
      GeneratedColumn<double>(
        'total_elevation_loss_m',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _caloriesKcalMeta = const VerificationMeta(
    'caloriesKcal',
  );
  @override
  late final GeneratedColumn<int> caloriesKcal = GeneratedColumn<int>(
    'calories_kcal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isIndoorMeta = const VerificationMeta(
    'isIndoor',
  );
  @override
  late final GeneratedColumn<bool> isIndoor = GeneratedColumn<bool>(
    'is_indoor',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_indoor" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasGpsTrackMeta = const VerificationMeta(
    'hasGpsTrack',
  );
  @override
  late final GeneratedColumn<bool> hasGpsTrack = GeneratedColumn<bool>(
    'has_gps_track',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_gps_track" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _gpsQualityMeta = const VerificationMeta(
    'gpsQuality',
  );
  @override
  late final GeneratedColumn<String> gpsQuality = GeneratedColumn<String>(
    'gps_quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('good'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFitPathMeta = const VerificationMeta(
    'originalFitPath',
  );
  @override
  late final GeneratedColumn<String> originalFitPath = GeneratedColumn<String>(
    'original_fit_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fitFileHashMeta = const VerificationMeta(
    'fitFileHash',
  );
  @override
  late final GeneratedColumn<String> fitFileHash = GeneratedColumn<String>(
    'fit_file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String>
  splitPacesSecPerKm = GeneratedColumn<String>(
    'split_paces_sec_per_km',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<int>>($ActivitiesTable.$convertersplitPacesSecPerKm);
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String>
  zoneDurationsSec = GeneratedColumn<String>(
    'zone_durations_sec',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<int>>($ActivitiesTable.$converterzoneDurationsSec);
  static const VerificationMeta _hasCustomTitleMeta = const VerificationMeta(
    'hasCustomTitle',
  );
  @override
  late final GeneratedColumn<bool> hasCustomTitle = GeneratedColumn<bool>(
    'has_custom_title',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_custom_title" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    garminActivityId,
    title,
    sportType,
    startTimeUtc,
    utcOffsetSeconds,
    durationTotalSec,
    durationMovingSec,
    distanceMeters,
    avgPaceSecPerKm,
    avgHeartRate,
    maxHeartRate,
    avgCadence,
    totalElevationGainM,
    totalElevationLossM,
    caloriesKcal,
    isIndoor,
    hasGpsTrack,
    gpsQuality,
    source,
    syncStatus,
    originalFitPath,
    fitFileHash,
    splitPacesSecPerKm,
    zoneDurationsSec,
    hasCustomTitle,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('garmin_activity_id')) {
      context.handle(
        _garminActivityIdMeta,
        garminActivityId.isAcceptableOrUnknown(
          data['garmin_activity_id']!,
          _garminActivityIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('sport_type')) {
      context.handle(
        _sportTypeMeta,
        sportType.isAcceptableOrUnknown(data['sport_type']!, _sportTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sportTypeMeta);
    }
    if (data.containsKey('start_time_utc')) {
      context.handle(
        _startTimeUtcMeta,
        startTimeUtc.isAcceptableOrUnknown(
          data['start_time_utc']!,
          _startTimeUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startTimeUtcMeta);
    }
    if (data.containsKey('utc_offset_seconds')) {
      context.handle(
        _utcOffsetSecondsMeta,
        utcOffsetSeconds.isAcceptableOrUnknown(
          data['utc_offset_seconds']!,
          _utcOffsetSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_utcOffsetSecondsMeta);
    }
    if (data.containsKey('duration_total_sec')) {
      context.handle(
        _durationTotalSecMeta,
        durationTotalSec.isAcceptableOrUnknown(
          data['duration_total_sec']!,
          _durationTotalSecMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationTotalSecMeta);
    }
    if (data.containsKey('duration_moving_sec')) {
      context.handle(
        _durationMovingSecMeta,
        durationMovingSec.isAcceptableOrUnknown(
          data['duration_moving_sec']!,
          _durationMovingSecMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMovingSecMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('avg_pace_sec_per_km')) {
      context.handle(
        _avgPaceSecPerKmMeta,
        avgPaceSecPerKm.isAcceptableOrUnknown(
          data['avg_pace_sec_per_km']!,
          _avgPaceSecPerKmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgPaceSecPerKmMeta);
    }
    if (data.containsKey('avg_heart_rate')) {
      context.handle(
        _avgHeartRateMeta,
        avgHeartRate.isAcceptableOrUnknown(
          data['avg_heart_rate']!,
          _avgHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('max_heart_rate')) {
      context.handle(
        _maxHeartRateMeta,
        maxHeartRate.isAcceptableOrUnknown(
          data['max_heart_rate']!,
          _maxHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('avg_cadence')) {
      context.handle(
        _avgCadenceMeta,
        avgCadence.isAcceptableOrUnknown(data['avg_cadence']!, _avgCadenceMeta),
      );
    }
    if (data.containsKey('total_elevation_gain_m')) {
      context.handle(
        _totalElevationGainMMeta,
        totalElevationGainM.isAcceptableOrUnknown(
          data['total_elevation_gain_m']!,
          _totalElevationGainMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalElevationGainMMeta);
    }
    if (data.containsKey('total_elevation_loss_m')) {
      context.handle(
        _totalElevationLossMMeta,
        totalElevationLossM.isAcceptableOrUnknown(
          data['total_elevation_loss_m']!,
          _totalElevationLossMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalElevationLossMMeta);
    }
    if (data.containsKey('calories_kcal')) {
      context.handle(
        _caloriesKcalMeta,
        caloriesKcal.isAcceptableOrUnknown(
          data['calories_kcal']!,
          _caloriesKcalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesKcalMeta);
    }
    if (data.containsKey('is_indoor')) {
      context.handle(
        _isIndoorMeta,
        isIndoor.isAcceptableOrUnknown(data['is_indoor']!, _isIndoorMeta),
      );
    }
    if (data.containsKey('has_gps_track')) {
      context.handle(
        _hasGpsTrackMeta,
        hasGpsTrack.isAcceptableOrUnknown(
          data['has_gps_track']!,
          _hasGpsTrackMeta,
        ),
      );
    }
    if (data.containsKey('gps_quality')) {
      context.handle(
        _gpsQualityMeta,
        gpsQuality.isAcceptableOrUnknown(data['gps_quality']!, _gpsQualityMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('original_fit_path')) {
      context.handle(
        _originalFitPathMeta,
        originalFitPath.isAcceptableOrUnknown(
          data['original_fit_path']!,
          _originalFitPathMeta,
        ),
      );
    }
    if (data.containsKey('fit_file_hash')) {
      context.handle(
        _fitFileHashMeta,
        fitFileHash.isAcceptableOrUnknown(
          data['fit_file_hash']!,
          _fitFileHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fitFileHashMeta);
    }
    if (data.containsKey('has_custom_title')) {
      context.handle(
        _hasCustomTitleMeta,
        hasCustomTitle.isAcceptableOrUnknown(
          data['has_custom_title']!,
          _hasCustomTitleMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      garminActivityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}garmin_activity_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sportType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sport_type'],
      )!,
      startTimeUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time_utc'],
      )!,
      utcOffsetSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}utc_offset_seconds'],
      )!,
      durationTotalSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_total_sec'],
      )!,
      durationMovingSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_moving_sec'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      avgPaceSecPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_pace_sec_per_km'],
      )!,
      avgHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_heart_rate'],
      ),
      maxHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_heart_rate'],
      ),
      avgCadence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_cadence'],
      ),
      totalElevationGainM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_elevation_gain_m'],
      )!,
      totalElevationLossM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_elevation_loss_m'],
      )!,
      caloriesKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories_kcal'],
      )!,
      isIndoor: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_indoor'],
      )!,
      hasGpsTrack: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_gps_track'],
      )!,
      gpsQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gps_quality'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      originalFitPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_fit_path'],
      ),
      fitFileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fit_file_hash'],
      )!,
      splitPacesSecPerKm: $ActivitiesTable.$convertersplitPacesSecPerKm.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}split_paces_sec_per_km'],
        )!,
      ),
      zoneDurationsSec: $ActivitiesTable.$converterzoneDurationsSec.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}zone_durations_sec'],
        )!,
      ),
      hasCustomTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_custom_title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<int>, String> $convertersplitPacesSecPerKm =
      const IntListConverter();
  static TypeConverter<List<int>, String> $converterzoneDurationsSec =
      const IntListConverter();
}

class ActivityRecord extends DataClass implements Insertable<ActivityRecord> {
  final int id;

  /// Nullable for manual `.FIT` imports without a Garmin Connect activity ID.
  final int? garminActivityId;
  final String title;
  final int sportType;
  final DateTime startTimeUtc;
  final int utcOffsetSeconds;
  final int durationTotalSec;
  final int durationMovingSec;
  final double distanceMeters;
  final double avgPaceSecPerKm;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final double? avgCadence;
  final double totalElevationGainM;
  final double totalElevationLossM;
  final int caloriesKcal;
  final bool isIndoor;
  final bool hasGpsTrack;
  final String gpsQuality;
  final String source;
  final String syncStatus;
  final String? originalFitPath;
  final String fitFileHash;
  final List<int> splitPacesSecPerKm;
  final List<int> zoneDurationsSec;

  /// Marks titles renamed locally by the user so Garmin re-syncs keep them (M3-08).
  final bool hasCustomTitle;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ActivityRecord({
    required this.id,
    this.garminActivityId,
    required this.title,
    required this.sportType,
    required this.startTimeUtc,
    required this.utcOffsetSeconds,
    required this.durationTotalSec,
    required this.durationMovingSec,
    required this.distanceMeters,
    required this.avgPaceSecPerKm,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgCadence,
    required this.totalElevationGainM,
    required this.totalElevationLossM,
    required this.caloriesKcal,
    required this.isIndoor,
    required this.hasGpsTrack,
    required this.gpsQuality,
    required this.source,
    required this.syncStatus,
    this.originalFitPath,
    required this.fitFileHash,
    required this.splitPacesSecPerKm,
    required this.zoneDurationsSec,
    required this.hasCustomTitle,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || garminActivityId != null) {
      map['garmin_activity_id'] = Variable<int>(garminActivityId);
    }
    map['title'] = Variable<String>(title);
    map['sport_type'] = Variable<int>(sportType);
    map['start_time_utc'] = Variable<DateTime>(startTimeUtc);
    map['utc_offset_seconds'] = Variable<int>(utcOffsetSeconds);
    map['duration_total_sec'] = Variable<int>(durationTotalSec);
    map['duration_moving_sec'] = Variable<int>(durationMovingSec);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['avg_pace_sec_per_km'] = Variable<double>(avgPaceSecPerKm);
    if (!nullToAbsent || avgHeartRate != null) {
      map['avg_heart_rate'] = Variable<double>(avgHeartRate);
    }
    if (!nullToAbsent || maxHeartRate != null) {
      map['max_heart_rate'] = Variable<double>(maxHeartRate);
    }
    if (!nullToAbsent || avgCadence != null) {
      map['avg_cadence'] = Variable<double>(avgCadence);
    }
    map['total_elevation_gain_m'] = Variable<double>(totalElevationGainM);
    map['total_elevation_loss_m'] = Variable<double>(totalElevationLossM);
    map['calories_kcal'] = Variable<int>(caloriesKcal);
    map['is_indoor'] = Variable<bool>(isIndoor);
    map['has_gps_track'] = Variable<bool>(hasGpsTrack);
    map['gps_quality'] = Variable<String>(gpsQuality);
    map['source'] = Variable<String>(source);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || originalFitPath != null) {
      map['original_fit_path'] = Variable<String>(originalFitPath);
    }
    map['fit_file_hash'] = Variable<String>(fitFileHash);
    {
      map['split_paces_sec_per_km'] = Variable<String>(
        $ActivitiesTable.$convertersplitPacesSecPerKm.toSql(splitPacesSecPerKm),
      );
    }
    {
      map['zone_durations_sec'] = Variable<String>(
        $ActivitiesTable.$converterzoneDurationsSec.toSql(zoneDurationsSec),
      );
    }
    map['has_custom_title'] = Variable<bool>(hasCustomTitle);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      garminActivityId: garminActivityId == null && nullToAbsent
          ? const Value.absent()
          : Value(garminActivityId),
      title: Value(title),
      sportType: Value(sportType),
      startTimeUtc: Value(startTimeUtc),
      utcOffsetSeconds: Value(utcOffsetSeconds),
      durationTotalSec: Value(durationTotalSec),
      durationMovingSec: Value(durationMovingSec),
      distanceMeters: Value(distanceMeters),
      avgPaceSecPerKm: Value(avgPaceSecPerKm),
      avgHeartRate: avgHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHeartRate),
      maxHeartRate: maxHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHeartRate),
      avgCadence: avgCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(avgCadence),
      totalElevationGainM: Value(totalElevationGainM),
      totalElevationLossM: Value(totalElevationLossM),
      caloriesKcal: Value(caloriesKcal),
      isIndoor: Value(isIndoor),
      hasGpsTrack: Value(hasGpsTrack),
      gpsQuality: Value(gpsQuality),
      source: Value(source),
      syncStatus: Value(syncStatus),
      originalFitPath: originalFitPath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalFitPath),
      fitFileHash: Value(fitFileHash),
      splitPacesSecPerKm: Value(splitPacesSecPerKm),
      zoneDurationsSec: Value(zoneDurationsSec),
      hasCustomTitle: Value(hasCustomTitle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ActivityRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityRecord(
      id: serializer.fromJson<int>(json['id']),
      garminActivityId: serializer.fromJson<int?>(json['garminActivityId']),
      title: serializer.fromJson<String>(json['title']),
      sportType: serializer.fromJson<int>(json['sportType']),
      startTimeUtc: serializer.fromJson<DateTime>(json['startTimeUtc']),
      utcOffsetSeconds: serializer.fromJson<int>(json['utcOffsetSeconds']),
      durationTotalSec: serializer.fromJson<int>(json['durationTotalSec']),
      durationMovingSec: serializer.fromJson<int>(json['durationMovingSec']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      avgPaceSecPerKm: serializer.fromJson<double>(json['avgPaceSecPerKm']),
      avgHeartRate: serializer.fromJson<double?>(json['avgHeartRate']),
      maxHeartRate: serializer.fromJson<double?>(json['maxHeartRate']),
      avgCadence: serializer.fromJson<double?>(json['avgCadence']),
      totalElevationGainM: serializer.fromJson<double>(
        json['totalElevationGainM'],
      ),
      totalElevationLossM: serializer.fromJson<double>(
        json['totalElevationLossM'],
      ),
      caloriesKcal: serializer.fromJson<int>(json['caloriesKcal']),
      isIndoor: serializer.fromJson<bool>(json['isIndoor']),
      hasGpsTrack: serializer.fromJson<bool>(json['hasGpsTrack']),
      gpsQuality: serializer.fromJson<String>(json['gpsQuality']),
      source: serializer.fromJson<String>(json['source']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      originalFitPath: serializer.fromJson<String?>(json['originalFitPath']),
      fitFileHash: serializer.fromJson<String>(json['fitFileHash']),
      splitPacesSecPerKm: serializer.fromJson<List<int>>(
        json['splitPacesSecPerKm'],
      ),
      zoneDurationsSec: serializer.fromJson<List<int>>(
        json['zoneDurationsSec'],
      ),
      hasCustomTitle: serializer.fromJson<bool>(json['hasCustomTitle']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'garminActivityId': serializer.toJson<int?>(garminActivityId),
      'title': serializer.toJson<String>(title),
      'sportType': serializer.toJson<int>(sportType),
      'startTimeUtc': serializer.toJson<DateTime>(startTimeUtc),
      'utcOffsetSeconds': serializer.toJson<int>(utcOffsetSeconds),
      'durationTotalSec': serializer.toJson<int>(durationTotalSec),
      'durationMovingSec': serializer.toJson<int>(durationMovingSec),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'avgPaceSecPerKm': serializer.toJson<double>(avgPaceSecPerKm),
      'avgHeartRate': serializer.toJson<double?>(avgHeartRate),
      'maxHeartRate': serializer.toJson<double?>(maxHeartRate),
      'avgCadence': serializer.toJson<double?>(avgCadence),
      'totalElevationGainM': serializer.toJson<double>(totalElevationGainM),
      'totalElevationLossM': serializer.toJson<double>(totalElevationLossM),
      'caloriesKcal': serializer.toJson<int>(caloriesKcal),
      'isIndoor': serializer.toJson<bool>(isIndoor),
      'hasGpsTrack': serializer.toJson<bool>(hasGpsTrack),
      'gpsQuality': serializer.toJson<String>(gpsQuality),
      'source': serializer.toJson<String>(source),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'originalFitPath': serializer.toJson<String?>(originalFitPath),
      'fitFileHash': serializer.toJson<String>(fitFileHash),
      'splitPacesSecPerKm': serializer.toJson<List<int>>(splitPacesSecPerKm),
      'zoneDurationsSec': serializer.toJson<List<int>>(zoneDurationsSec),
      'hasCustomTitle': serializer.toJson<bool>(hasCustomTitle),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ActivityRecord copyWith({
    int? id,
    Value<int?> garminActivityId = const Value.absent(),
    String? title,
    int? sportType,
    DateTime? startTimeUtc,
    int? utcOffsetSeconds,
    int? durationTotalSec,
    int? durationMovingSec,
    double? distanceMeters,
    double? avgPaceSecPerKm,
    Value<double?> avgHeartRate = const Value.absent(),
    Value<double?> maxHeartRate = const Value.absent(),
    Value<double?> avgCadence = const Value.absent(),
    double? totalElevationGainM,
    double? totalElevationLossM,
    int? caloriesKcal,
    bool? isIndoor,
    bool? hasGpsTrack,
    String? gpsQuality,
    String? source,
    String? syncStatus,
    Value<String?> originalFitPath = const Value.absent(),
    String? fitFileHash,
    List<int>? splitPacesSecPerKm,
    List<int>? zoneDurationsSec,
    bool? hasCustomTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ActivityRecord(
    id: id ?? this.id,
    garminActivityId: garminActivityId.present
        ? garminActivityId.value
        : this.garminActivityId,
    title: title ?? this.title,
    sportType: sportType ?? this.sportType,
    startTimeUtc: startTimeUtc ?? this.startTimeUtc,
    utcOffsetSeconds: utcOffsetSeconds ?? this.utcOffsetSeconds,
    durationTotalSec: durationTotalSec ?? this.durationTotalSec,
    durationMovingSec: durationMovingSec ?? this.durationMovingSec,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    avgPaceSecPerKm: avgPaceSecPerKm ?? this.avgPaceSecPerKm,
    avgHeartRate: avgHeartRate.present ? avgHeartRate.value : this.avgHeartRate,
    maxHeartRate: maxHeartRate.present ? maxHeartRate.value : this.maxHeartRate,
    avgCadence: avgCadence.present ? avgCadence.value : this.avgCadence,
    totalElevationGainM: totalElevationGainM ?? this.totalElevationGainM,
    totalElevationLossM: totalElevationLossM ?? this.totalElevationLossM,
    caloriesKcal: caloriesKcal ?? this.caloriesKcal,
    isIndoor: isIndoor ?? this.isIndoor,
    hasGpsTrack: hasGpsTrack ?? this.hasGpsTrack,
    gpsQuality: gpsQuality ?? this.gpsQuality,
    source: source ?? this.source,
    syncStatus: syncStatus ?? this.syncStatus,
    originalFitPath: originalFitPath.present
        ? originalFitPath.value
        : this.originalFitPath,
    fitFileHash: fitFileHash ?? this.fitFileHash,
    splitPacesSecPerKm: splitPacesSecPerKm ?? this.splitPacesSecPerKm,
    zoneDurationsSec: zoneDurationsSec ?? this.zoneDurationsSec,
    hasCustomTitle: hasCustomTitle ?? this.hasCustomTitle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ActivityRecord copyWithCompanion(ActivitiesCompanion data) {
    return ActivityRecord(
      id: data.id.present ? data.id.value : this.id,
      garminActivityId: data.garminActivityId.present
          ? data.garminActivityId.value
          : this.garminActivityId,
      title: data.title.present ? data.title.value : this.title,
      sportType: data.sportType.present ? data.sportType.value : this.sportType,
      startTimeUtc: data.startTimeUtc.present
          ? data.startTimeUtc.value
          : this.startTimeUtc,
      utcOffsetSeconds: data.utcOffsetSeconds.present
          ? data.utcOffsetSeconds.value
          : this.utcOffsetSeconds,
      durationTotalSec: data.durationTotalSec.present
          ? data.durationTotalSec.value
          : this.durationTotalSec,
      durationMovingSec: data.durationMovingSec.present
          ? data.durationMovingSec.value
          : this.durationMovingSec,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      avgPaceSecPerKm: data.avgPaceSecPerKm.present
          ? data.avgPaceSecPerKm.value
          : this.avgPaceSecPerKm,
      avgHeartRate: data.avgHeartRate.present
          ? data.avgHeartRate.value
          : this.avgHeartRate,
      maxHeartRate: data.maxHeartRate.present
          ? data.maxHeartRate.value
          : this.maxHeartRate,
      avgCadence: data.avgCadence.present
          ? data.avgCadence.value
          : this.avgCadence,
      totalElevationGainM: data.totalElevationGainM.present
          ? data.totalElevationGainM.value
          : this.totalElevationGainM,
      totalElevationLossM: data.totalElevationLossM.present
          ? data.totalElevationLossM.value
          : this.totalElevationLossM,
      caloriesKcal: data.caloriesKcal.present
          ? data.caloriesKcal.value
          : this.caloriesKcal,
      isIndoor: data.isIndoor.present ? data.isIndoor.value : this.isIndoor,
      hasGpsTrack: data.hasGpsTrack.present
          ? data.hasGpsTrack.value
          : this.hasGpsTrack,
      gpsQuality: data.gpsQuality.present
          ? data.gpsQuality.value
          : this.gpsQuality,
      source: data.source.present ? data.source.value : this.source,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      originalFitPath: data.originalFitPath.present
          ? data.originalFitPath.value
          : this.originalFitPath,
      fitFileHash: data.fitFileHash.present
          ? data.fitFileHash.value
          : this.fitFileHash,
      splitPacesSecPerKm: data.splitPacesSecPerKm.present
          ? data.splitPacesSecPerKm.value
          : this.splitPacesSecPerKm,
      zoneDurationsSec: data.zoneDurationsSec.present
          ? data.zoneDurationsSec.value
          : this.zoneDurationsSec,
      hasCustomTitle: data.hasCustomTitle.present
          ? data.hasCustomTitle.value
          : this.hasCustomTitle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityRecord(')
          ..write('id: $id, ')
          ..write('garminActivityId: $garminActivityId, ')
          ..write('title: $title, ')
          ..write('sportType: $sportType, ')
          ..write('startTimeUtc: $startTimeUtc, ')
          ..write('utcOffsetSeconds: $utcOffsetSeconds, ')
          ..write('durationTotalSec: $durationTotalSec, ')
          ..write('durationMovingSec: $durationMovingSec, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('avgPaceSecPerKm: $avgPaceSecPerKm, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('totalElevationGainM: $totalElevationGainM, ')
          ..write('totalElevationLossM: $totalElevationLossM, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('isIndoor: $isIndoor, ')
          ..write('hasGpsTrack: $hasGpsTrack, ')
          ..write('gpsQuality: $gpsQuality, ')
          ..write('source: $source, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('originalFitPath: $originalFitPath, ')
          ..write('fitFileHash: $fitFileHash, ')
          ..write('splitPacesSecPerKm: $splitPacesSecPerKm, ')
          ..write('zoneDurationsSec: $zoneDurationsSec, ')
          ..write('hasCustomTitle: $hasCustomTitle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    garminActivityId,
    title,
    sportType,
    startTimeUtc,
    utcOffsetSeconds,
    durationTotalSec,
    durationMovingSec,
    distanceMeters,
    avgPaceSecPerKm,
    avgHeartRate,
    maxHeartRate,
    avgCadence,
    totalElevationGainM,
    totalElevationLossM,
    caloriesKcal,
    isIndoor,
    hasGpsTrack,
    gpsQuality,
    source,
    syncStatus,
    originalFitPath,
    fitFileHash,
    splitPacesSecPerKm,
    zoneDurationsSec,
    hasCustomTitle,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityRecord &&
          other.id == this.id &&
          other.garminActivityId == this.garminActivityId &&
          other.title == this.title &&
          other.sportType == this.sportType &&
          other.startTimeUtc == this.startTimeUtc &&
          other.utcOffsetSeconds == this.utcOffsetSeconds &&
          other.durationTotalSec == this.durationTotalSec &&
          other.durationMovingSec == this.durationMovingSec &&
          other.distanceMeters == this.distanceMeters &&
          other.avgPaceSecPerKm == this.avgPaceSecPerKm &&
          other.avgHeartRate == this.avgHeartRate &&
          other.maxHeartRate == this.maxHeartRate &&
          other.avgCadence == this.avgCadence &&
          other.totalElevationGainM == this.totalElevationGainM &&
          other.totalElevationLossM == this.totalElevationLossM &&
          other.caloriesKcal == this.caloriesKcal &&
          other.isIndoor == this.isIndoor &&
          other.hasGpsTrack == this.hasGpsTrack &&
          other.gpsQuality == this.gpsQuality &&
          other.source == this.source &&
          other.syncStatus == this.syncStatus &&
          other.originalFitPath == this.originalFitPath &&
          other.fitFileHash == this.fitFileHash &&
          other.splitPacesSecPerKm == this.splitPacesSecPerKm &&
          other.zoneDurationsSec == this.zoneDurationsSec &&
          other.hasCustomTitle == this.hasCustomTitle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ActivitiesCompanion extends UpdateCompanion<ActivityRecord> {
  final Value<int> id;
  final Value<int?> garminActivityId;
  final Value<String> title;
  final Value<int> sportType;
  final Value<DateTime> startTimeUtc;
  final Value<int> utcOffsetSeconds;
  final Value<int> durationTotalSec;
  final Value<int> durationMovingSec;
  final Value<double> distanceMeters;
  final Value<double> avgPaceSecPerKm;
  final Value<double?> avgHeartRate;
  final Value<double?> maxHeartRate;
  final Value<double?> avgCadence;
  final Value<double> totalElevationGainM;
  final Value<double> totalElevationLossM;
  final Value<int> caloriesKcal;
  final Value<bool> isIndoor;
  final Value<bool> hasGpsTrack;
  final Value<String> gpsQuality;
  final Value<String> source;
  final Value<String> syncStatus;
  final Value<String?> originalFitPath;
  final Value<String> fitFileHash;
  final Value<List<int>> splitPacesSecPerKm;
  final Value<List<int>> zoneDurationsSec;
  final Value<bool> hasCustomTitle;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.garminActivityId = const Value.absent(),
    this.title = const Value.absent(),
    this.sportType = const Value.absent(),
    this.startTimeUtc = const Value.absent(),
    this.utcOffsetSeconds = const Value.absent(),
    this.durationTotalSec = const Value.absent(),
    this.durationMovingSec = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.avgPaceSecPerKm = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.avgCadence = const Value.absent(),
    this.totalElevationGainM = const Value.absent(),
    this.totalElevationLossM = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.isIndoor = const Value.absent(),
    this.hasGpsTrack = const Value.absent(),
    this.gpsQuality = const Value.absent(),
    this.source = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.originalFitPath = const Value.absent(),
    this.fitFileHash = const Value.absent(),
    this.splitPacesSecPerKm = const Value.absent(),
    this.zoneDurationsSec = const Value.absent(),
    this.hasCustomTitle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    this.id = const Value.absent(),
    this.garminActivityId = const Value.absent(),
    required String title,
    required int sportType,
    required DateTime startTimeUtc,
    required int utcOffsetSeconds,
    required int durationTotalSec,
    required int durationMovingSec,
    required double distanceMeters,
    required double avgPaceSecPerKm,
    this.avgHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.avgCadence = const Value.absent(),
    required double totalElevationGainM,
    required double totalElevationLossM,
    required int caloriesKcal,
    this.isIndoor = const Value.absent(),
    this.hasGpsTrack = const Value.absent(),
    this.gpsQuality = const Value.absent(),
    required String source,
    required String syncStatus,
    this.originalFitPath = const Value.absent(),
    required String fitFileHash,
    required List<int> splitPacesSecPerKm,
    required List<int> zoneDurationsSec,
    this.hasCustomTitle = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : title = Value(title),
       sportType = Value(sportType),
       startTimeUtc = Value(startTimeUtc),
       utcOffsetSeconds = Value(utcOffsetSeconds),
       durationTotalSec = Value(durationTotalSec),
       durationMovingSec = Value(durationMovingSec),
       distanceMeters = Value(distanceMeters),
       avgPaceSecPerKm = Value(avgPaceSecPerKm),
       totalElevationGainM = Value(totalElevationGainM),
       totalElevationLossM = Value(totalElevationLossM),
       caloriesKcal = Value(caloriesKcal),
       source = Value(source),
       syncStatus = Value(syncStatus),
       fitFileHash = Value(fitFileHash),
       splitPacesSecPerKm = Value(splitPacesSecPerKm),
       zoneDurationsSec = Value(zoneDurationsSec),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ActivityRecord> custom({
    Expression<int>? id,
    Expression<int>? garminActivityId,
    Expression<String>? title,
    Expression<int>? sportType,
    Expression<DateTime>? startTimeUtc,
    Expression<int>? utcOffsetSeconds,
    Expression<int>? durationTotalSec,
    Expression<int>? durationMovingSec,
    Expression<double>? distanceMeters,
    Expression<double>? avgPaceSecPerKm,
    Expression<double>? avgHeartRate,
    Expression<double>? maxHeartRate,
    Expression<double>? avgCadence,
    Expression<double>? totalElevationGainM,
    Expression<double>? totalElevationLossM,
    Expression<int>? caloriesKcal,
    Expression<bool>? isIndoor,
    Expression<bool>? hasGpsTrack,
    Expression<String>? gpsQuality,
    Expression<String>? source,
    Expression<String>? syncStatus,
    Expression<String>? originalFitPath,
    Expression<String>? fitFileHash,
    Expression<String>? splitPacesSecPerKm,
    Expression<String>? zoneDurationsSec,
    Expression<bool>? hasCustomTitle,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (garminActivityId != null) 'garmin_activity_id': garminActivityId,
      if (title != null) 'title': title,
      if (sportType != null) 'sport_type': sportType,
      if (startTimeUtc != null) 'start_time_utc': startTimeUtc,
      if (utcOffsetSeconds != null) 'utc_offset_seconds': utcOffsetSeconds,
      if (durationTotalSec != null) 'duration_total_sec': durationTotalSec,
      if (durationMovingSec != null) 'duration_moving_sec': durationMovingSec,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (avgPaceSecPerKm != null) 'avg_pace_sec_per_km': avgPaceSecPerKm,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
      if (avgCadence != null) 'avg_cadence': avgCadence,
      if (totalElevationGainM != null)
        'total_elevation_gain_m': totalElevationGainM,
      if (totalElevationLossM != null)
        'total_elevation_loss_m': totalElevationLossM,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (isIndoor != null) 'is_indoor': isIndoor,
      if (hasGpsTrack != null) 'has_gps_track': hasGpsTrack,
      if (gpsQuality != null) 'gps_quality': gpsQuality,
      if (source != null) 'source': source,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (originalFitPath != null) 'original_fit_path': originalFitPath,
      if (fitFileHash != null) 'fit_file_hash': fitFileHash,
      if (splitPacesSecPerKm != null)
        'split_paces_sec_per_km': splitPacesSecPerKm,
      if (zoneDurationsSec != null) 'zone_durations_sec': zoneDurationsSec,
      if (hasCustomTitle != null) 'has_custom_title': hasCustomTitle,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ActivitiesCompanion copyWith({
    Value<int>? id,
    Value<int?>? garminActivityId,
    Value<String>? title,
    Value<int>? sportType,
    Value<DateTime>? startTimeUtc,
    Value<int>? utcOffsetSeconds,
    Value<int>? durationTotalSec,
    Value<int>? durationMovingSec,
    Value<double>? distanceMeters,
    Value<double>? avgPaceSecPerKm,
    Value<double?>? avgHeartRate,
    Value<double?>? maxHeartRate,
    Value<double?>? avgCadence,
    Value<double>? totalElevationGainM,
    Value<double>? totalElevationLossM,
    Value<int>? caloriesKcal,
    Value<bool>? isIndoor,
    Value<bool>? hasGpsTrack,
    Value<String>? gpsQuality,
    Value<String>? source,
    Value<String>? syncStatus,
    Value<String?>? originalFitPath,
    Value<String>? fitFileHash,
    Value<List<int>>? splitPacesSecPerKm,
    Value<List<int>>? zoneDurationsSec,
    Value<bool>? hasCustomTitle,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      garminActivityId: garminActivityId ?? this.garminActivityId,
      title: title ?? this.title,
      sportType: sportType ?? this.sportType,
      startTimeUtc: startTimeUtc ?? this.startTimeUtc,
      utcOffsetSeconds: utcOffsetSeconds ?? this.utcOffsetSeconds,
      durationTotalSec: durationTotalSec ?? this.durationTotalSec,
      durationMovingSec: durationMovingSec ?? this.durationMovingSec,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      avgPaceSecPerKm: avgPaceSecPerKm ?? this.avgPaceSecPerKm,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      avgCadence: avgCadence ?? this.avgCadence,
      totalElevationGainM: totalElevationGainM ?? this.totalElevationGainM,
      totalElevationLossM: totalElevationLossM ?? this.totalElevationLossM,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      isIndoor: isIndoor ?? this.isIndoor,
      hasGpsTrack: hasGpsTrack ?? this.hasGpsTrack,
      gpsQuality: gpsQuality ?? this.gpsQuality,
      source: source ?? this.source,
      syncStatus: syncStatus ?? this.syncStatus,
      originalFitPath: originalFitPath ?? this.originalFitPath,
      fitFileHash: fitFileHash ?? this.fitFileHash,
      splitPacesSecPerKm: splitPacesSecPerKm ?? this.splitPacesSecPerKm,
      zoneDurationsSec: zoneDurationsSec ?? this.zoneDurationsSec,
      hasCustomTitle: hasCustomTitle ?? this.hasCustomTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (garminActivityId.present) {
      map['garmin_activity_id'] = Variable<int>(garminActivityId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sportType.present) {
      map['sport_type'] = Variable<int>(sportType.value);
    }
    if (startTimeUtc.present) {
      map['start_time_utc'] = Variable<DateTime>(startTimeUtc.value);
    }
    if (utcOffsetSeconds.present) {
      map['utc_offset_seconds'] = Variable<int>(utcOffsetSeconds.value);
    }
    if (durationTotalSec.present) {
      map['duration_total_sec'] = Variable<int>(durationTotalSec.value);
    }
    if (durationMovingSec.present) {
      map['duration_moving_sec'] = Variable<int>(durationMovingSec.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (avgPaceSecPerKm.present) {
      map['avg_pace_sec_per_km'] = Variable<double>(avgPaceSecPerKm.value);
    }
    if (avgHeartRate.present) {
      map['avg_heart_rate'] = Variable<double>(avgHeartRate.value);
    }
    if (maxHeartRate.present) {
      map['max_heart_rate'] = Variable<double>(maxHeartRate.value);
    }
    if (avgCadence.present) {
      map['avg_cadence'] = Variable<double>(avgCadence.value);
    }
    if (totalElevationGainM.present) {
      map['total_elevation_gain_m'] = Variable<double>(
        totalElevationGainM.value,
      );
    }
    if (totalElevationLossM.present) {
      map['total_elevation_loss_m'] = Variable<double>(
        totalElevationLossM.value,
      );
    }
    if (caloriesKcal.present) {
      map['calories_kcal'] = Variable<int>(caloriesKcal.value);
    }
    if (isIndoor.present) {
      map['is_indoor'] = Variable<bool>(isIndoor.value);
    }
    if (hasGpsTrack.present) {
      map['has_gps_track'] = Variable<bool>(hasGpsTrack.value);
    }
    if (gpsQuality.present) {
      map['gps_quality'] = Variable<String>(gpsQuality.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (originalFitPath.present) {
      map['original_fit_path'] = Variable<String>(originalFitPath.value);
    }
    if (fitFileHash.present) {
      map['fit_file_hash'] = Variable<String>(fitFileHash.value);
    }
    if (splitPacesSecPerKm.present) {
      map['split_paces_sec_per_km'] = Variable<String>(
        $ActivitiesTable.$convertersplitPacesSecPerKm.toSql(
          splitPacesSecPerKm.value,
        ),
      );
    }
    if (zoneDurationsSec.present) {
      map['zone_durations_sec'] = Variable<String>(
        $ActivitiesTable.$converterzoneDurationsSec.toSql(
          zoneDurationsSec.value,
        ),
      );
    }
    if (hasCustomTitle.present) {
      map['has_custom_title'] = Variable<bool>(hasCustomTitle.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('garminActivityId: $garminActivityId, ')
          ..write('title: $title, ')
          ..write('sportType: $sportType, ')
          ..write('startTimeUtc: $startTimeUtc, ')
          ..write('utcOffsetSeconds: $utcOffsetSeconds, ')
          ..write('durationTotalSec: $durationTotalSec, ')
          ..write('durationMovingSec: $durationMovingSec, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('avgPaceSecPerKm: $avgPaceSecPerKm, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('totalElevationGainM: $totalElevationGainM, ')
          ..write('totalElevationLossM: $totalElevationLossM, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('isIndoor: $isIndoor, ')
          ..write('hasGpsTrack: $hasGpsTrack, ')
          ..write('gpsQuality: $gpsQuality, ')
          ..write('source: $source, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('originalFitPath: $originalFitPath, ')
          ..write('fitFileHash: $fitFileHash, ')
          ..write('splitPacesSecPerKm: $splitPacesSecPerKm, ')
          ..write('zoneDurationsSec: $zoneDurationsSec, ')
          ..write('hasCustomTitle: $hasCustomTitle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackPointsTable extends TrackPoints
    with TableInfo<$TrackPointsTable, TrackPointRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<int> activityId = GeneratedColumn<int>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES activities (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampUtcMeta = const VerificationMeta(
    'timestampUtc',
  );
  @override
  late final GeneratedColumn<DateTime> timestampUtc = GeneratedColumn<DateTime>(
    'timestamp_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeDegMeta = const VerificationMeta(
    'latitudeDeg',
  );
  @override
  late final GeneratedColumn<double> latitudeDeg = GeneratedColumn<double>(
    'latitude_deg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeDegMeta = const VerificationMeta(
    'longitudeDeg',
  );
  @override
  late final GeneratedColumn<double> longitudeDeg = GeneratedColumn<double>(
    'longitude_deg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMMeta = const VerificationMeta(
    'altitudeM',
  );
  @override
  late final GeneratedColumn<double> altitudeM = GeneratedColumn<double>(
    'altitude_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heartRateBpmMeta = const VerificationMeta(
    'heartRateBpm',
  );
  @override
  late final GeneratedColumn<int> heartRateBpm = GeneratedColumn<int>(
    'heart_rate_bpm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cadenceRpmMeta = const VerificationMeta(
    'cadenceRpm',
  );
  @override
  late final GeneratedColumn<int> cadenceRpm = GeneratedColumn<int>(
    'cadence_rpm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<int> distanceMeters = GeneratedColumn<int>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hrZoneMeta = const VerificationMeta('hrZone');
  @override
  late final GeneratedColumn<int> hrZone = GeneratedColumn<int>(
    'hr_zone',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityId,
    timestampUtc,
    latitudeDeg,
    longitudeDeg,
    altitudeM,
    speedMps,
    heartRateBpm,
    cadenceRpm,
    distanceMeters,
    hrZone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackPointRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('timestamp_utc')) {
      context.handle(
        _timestampUtcMeta,
        timestampUtc.isAcceptableOrUnknown(
          data['timestamp_utc']!,
          _timestampUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampUtcMeta);
    }
    if (data.containsKey('latitude_deg')) {
      context.handle(
        _latitudeDegMeta,
        latitudeDeg.isAcceptableOrUnknown(
          data['latitude_deg']!,
          _latitudeDegMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_latitudeDegMeta);
    }
    if (data.containsKey('longitude_deg')) {
      context.handle(
        _longitudeDegMeta,
        longitudeDeg.isAcceptableOrUnknown(
          data['longitude_deg']!,
          _longitudeDegMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_longitudeDegMeta);
    }
    if (data.containsKey('altitude_m')) {
      context.handle(
        _altitudeMMeta,
        altitudeM.isAcceptableOrUnknown(data['altitude_m']!, _altitudeMMeta),
      );
    } else if (isInserting) {
      context.missing(_altitudeMMeta);
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    } else if (isInserting) {
      context.missing(_speedMpsMeta);
    }
    if (data.containsKey('heart_rate_bpm')) {
      context.handle(
        _heartRateBpmMeta,
        heartRateBpm.isAcceptableOrUnknown(
          data['heart_rate_bpm']!,
          _heartRateBpmMeta,
        ),
      );
    }
    if (data.containsKey('cadence_rpm')) {
      context.handle(
        _cadenceRpmMeta,
        cadenceRpm.isAcceptableOrUnknown(data['cadence_rpm']!, _cadenceRpmMeta),
      );
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('hr_zone')) {
      context.handle(
        _hrZoneMeta,
        hrZone.isAcceptableOrUnknown(data['hr_zone']!, _hrZoneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackPointRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackPointRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_id'],
      )!,
      timestampUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp_utc'],
      )!,
      latitudeDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude_deg'],
      )!,
      longitudeDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude_deg'],
      )!,
      altitudeM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude_m'],
      )!,
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      )!,
      heartRateBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heart_rate_bpm'],
      ),
      cadenceRpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cadence_rpm'],
      ),
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_meters'],
      )!,
      hrZone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_zone'],
      ),
    );
  }

  @override
  $TrackPointsTable createAlias(String alias) {
    return $TrackPointsTable(attachedDatabase, alias);
  }
}

class TrackPointRecord extends DataClass
    implements Insertable<TrackPointRecord> {
  final int id;
  final int activityId;
  final DateTime timestampUtc;
  final double latitudeDeg;
  final double longitudeDeg;
  final double altitudeM;
  final double speedMps;
  final int? heartRateBpm;
  final int? cadenceRpm;
  final int distanceMeters;
  final int? hrZone;
  const TrackPointRecord({
    required this.id,
    required this.activityId,
    required this.timestampUtc,
    required this.latitudeDeg,
    required this.longitudeDeg,
    required this.altitudeM,
    required this.speedMps,
    this.heartRateBpm,
    this.cadenceRpm,
    required this.distanceMeters,
    this.hrZone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['activity_id'] = Variable<int>(activityId);
    map['timestamp_utc'] = Variable<DateTime>(timestampUtc);
    map['latitude_deg'] = Variable<double>(latitudeDeg);
    map['longitude_deg'] = Variable<double>(longitudeDeg);
    map['altitude_m'] = Variable<double>(altitudeM);
    map['speed_mps'] = Variable<double>(speedMps);
    if (!nullToAbsent || heartRateBpm != null) {
      map['heart_rate_bpm'] = Variable<int>(heartRateBpm);
    }
    if (!nullToAbsent || cadenceRpm != null) {
      map['cadence_rpm'] = Variable<int>(cadenceRpm);
    }
    map['distance_meters'] = Variable<int>(distanceMeters);
    if (!nullToAbsent || hrZone != null) {
      map['hr_zone'] = Variable<int>(hrZone);
    }
    return map;
  }

  TrackPointsCompanion toCompanion(bool nullToAbsent) {
    return TrackPointsCompanion(
      id: Value(id),
      activityId: Value(activityId),
      timestampUtc: Value(timestampUtc),
      latitudeDeg: Value(latitudeDeg),
      longitudeDeg: Value(longitudeDeg),
      altitudeM: Value(altitudeM),
      speedMps: Value(speedMps),
      heartRateBpm: heartRateBpm == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRateBpm),
      cadenceRpm: cadenceRpm == null && nullToAbsent
          ? const Value.absent()
          : Value(cadenceRpm),
      distanceMeters: Value(distanceMeters),
      hrZone: hrZone == null && nullToAbsent
          ? const Value.absent()
          : Value(hrZone),
    );
  }

  factory TrackPointRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackPointRecord(
      id: serializer.fromJson<int>(json['id']),
      activityId: serializer.fromJson<int>(json['activityId']),
      timestampUtc: serializer.fromJson<DateTime>(json['timestampUtc']),
      latitudeDeg: serializer.fromJson<double>(json['latitudeDeg']),
      longitudeDeg: serializer.fromJson<double>(json['longitudeDeg']),
      altitudeM: serializer.fromJson<double>(json['altitudeM']),
      speedMps: serializer.fromJson<double>(json['speedMps']),
      heartRateBpm: serializer.fromJson<int?>(json['heartRateBpm']),
      cadenceRpm: serializer.fromJson<int?>(json['cadenceRpm']),
      distanceMeters: serializer.fromJson<int>(json['distanceMeters']),
      hrZone: serializer.fromJson<int?>(json['hrZone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activityId': serializer.toJson<int>(activityId),
      'timestampUtc': serializer.toJson<DateTime>(timestampUtc),
      'latitudeDeg': serializer.toJson<double>(latitudeDeg),
      'longitudeDeg': serializer.toJson<double>(longitudeDeg),
      'altitudeM': serializer.toJson<double>(altitudeM),
      'speedMps': serializer.toJson<double>(speedMps),
      'heartRateBpm': serializer.toJson<int?>(heartRateBpm),
      'cadenceRpm': serializer.toJson<int?>(cadenceRpm),
      'distanceMeters': serializer.toJson<int>(distanceMeters),
      'hrZone': serializer.toJson<int?>(hrZone),
    };
  }

  TrackPointRecord copyWith({
    int? id,
    int? activityId,
    DateTime? timestampUtc,
    double? latitudeDeg,
    double? longitudeDeg,
    double? altitudeM,
    double? speedMps,
    Value<int?> heartRateBpm = const Value.absent(),
    Value<int?> cadenceRpm = const Value.absent(),
    int? distanceMeters,
    Value<int?> hrZone = const Value.absent(),
  }) => TrackPointRecord(
    id: id ?? this.id,
    activityId: activityId ?? this.activityId,
    timestampUtc: timestampUtc ?? this.timestampUtc,
    latitudeDeg: latitudeDeg ?? this.latitudeDeg,
    longitudeDeg: longitudeDeg ?? this.longitudeDeg,
    altitudeM: altitudeM ?? this.altitudeM,
    speedMps: speedMps ?? this.speedMps,
    heartRateBpm: heartRateBpm.present ? heartRateBpm.value : this.heartRateBpm,
    cadenceRpm: cadenceRpm.present ? cadenceRpm.value : this.cadenceRpm,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    hrZone: hrZone.present ? hrZone.value : this.hrZone,
  );
  TrackPointRecord copyWithCompanion(TrackPointsCompanion data) {
    return TrackPointRecord(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      timestampUtc: data.timestampUtc.present
          ? data.timestampUtc.value
          : this.timestampUtc,
      latitudeDeg: data.latitudeDeg.present
          ? data.latitudeDeg.value
          : this.latitudeDeg,
      longitudeDeg: data.longitudeDeg.present
          ? data.longitudeDeg.value
          : this.longitudeDeg,
      altitudeM: data.altitudeM.present ? data.altitudeM.value : this.altitudeM,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      heartRateBpm: data.heartRateBpm.present
          ? data.heartRateBpm.value
          : this.heartRateBpm,
      cadenceRpm: data.cadenceRpm.present
          ? data.cadenceRpm.value
          : this.cadenceRpm,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      hrZone: data.hrZone.present ? data.hrZone.value : this.hrZone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointRecord(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('timestampUtc: $timestampUtc, ')
          ..write('latitudeDeg: $latitudeDeg, ')
          ..write('longitudeDeg: $longitudeDeg, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('speedMps: $speedMps, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('cadenceRpm: $cadenceRpm, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('hrZone: $hrZone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityId,
    timestampUtc,
    latitudeDeg,
    longitudeDeg,
    altitudeM,
    speedMps,
    heartRateBpm,
    cadenceRpm,
    distanceMeters,
    hrZone,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackPointRecord &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.timestampUtc == this.timestampUtc &&
          other.latitudeDeg == this.latitudeDeg &&
          other.longitudeDeg == this.longitudeDeg &&
          other.altitudeM == this.altitudeM &&
          other.speedMps == this.speedMps &&
          other.heartRateBpm == this.heartRateBpm &&
          other.cadenceRpm == this.cadenceRpm &&
          other.distanceMeters == this.distanceMeters &&
          other.hrZone == this.hrZone);
}

class TrackPointsCompanion extends UpdateCompanion<TrackPointRecord> {
  final Value<int> id;
  final Value<int> activityId;
  final Value<DateTime> timestampUtc;
  final Value<double> latitudeDeg;
  final Value<double> longitudeDeg;
  final Value<double> altitudeM;
  final Value<double> speedMps;
  final Value<int?> heartRateBpm;
  final Value<int?> cadenceRpm;
  final Value<int> distanceMeters;
  final Value<int?> hrZone;
  const TrackPointsCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.timestampUtc = const Value.absent(),
    this.latitudeDeg = const Value.absent(),
    this.longitudeDeg = const Value.absent(),
    this.altitudeM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.heartRateBpm = const Value.absent(),
    this.cadenceRpm = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.hrZone = const Value.absent(),
  });
  TrackPointsCompanion.insert({
    this.id = const Value.absent(),
    required int activityId,
    required DateTime timestampUtc,
    required double latitudeDeg,
    required double longitudeDeg,
    required double altitudeM,
    required double speedMps,
    this.heartRateBpm = const Value.absent(),
    this.cadenceRpm = const Value.absent(),
    required int distanceMeters,
    this.hrZone = const Value.absent(),
  }) : activityId = Value(activityId),
       timestampUtc = Value(timestampUtc),
       latitudeDeg = Value(latitudeDeg),
       longitudeDeg = Value(longitudeDeg),
       altitudeM = Value(altitudeM),
       speedMps = Value(speedMps),
       distanceMeters = Value(distanceMeters);
  static Insertable<TrackPointRecord> custom({
    Expression<int>? id,
    Expression<int>? activityId,
    Expression<DateTime>? timestampUtc,
    Expression<double>? latitudeDeg,
    Expression<double>? longitudeDeg,
    Expression<double>? altitudeM,
    Expression<double>? speedMps,
    Expression<int>? heartRateBpm,
    Expression<int>? cadenceRpm,
    Expression<int>? distanceMeters,
    Expression<int>? hrZone,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (timestampUtc != null) 'timestamp_utc': timestampUtc,
      if (latitudeDeg != null) 'latitude_deg': latitudeDeg,
      if (longitudeDeg != null) 'longitude_deg': longitudeDeg,
      if (altitudeM != null) 'altitude_m': altitudeM,
      if (speedMps != null) 'speed_mps': speedMps,
      if (heartRateBpm != null) 'heart_rate_bpm': heartRateBpm,
      if (cadenceRpm != null) 'cadence_rpm': cadenceRpm,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (hrZone != null) 'hr_zone': hrZone,
    });
  }

  TrackPointsCompanion copyWith({
    Value<int>? id,
    Value<int>? activityId,
    Value<DateTime>? timestampUtc,
    Value<double>? latitudeDeg,
    Value<double>? longitudeDeg,
    Value<double>? altitudeM,
    Value<double>? speedMps,
    Value<int?>? heartRateBpm,
    Value<int?>? cadenceRpm,
    Value<int>? distanceMeters,
    Value<int?>? hrZone,
  }) {
    return TrackPointsCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      timestampUtc: timestampUtc ?? this.timestampUtc,
      latitudeDeg: latitudeDeg ?? this.latitudeDeg,
      longitudeDeg: longitudeDeg ?? this.longitudeDeg,
      altitudeM: altitudeM ?? this.altitudeM,
      speedMps: speedMps ?? this.speedMps,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      hrZone: hrZone ?? this.hrZone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<int>(activityId.value);
    }
    if (timestampUtc.present) {
      map['timestamp_utc'] = Variable<DateTime>(timestampUtc.value);
    }
    if (latitudeDeg.present) {
      map['latitude_deg'] = Variable<double>(latitudeDeg.value);
    }
    if (longitudeDeg.present) {
      map['longitude_deg'] = Variable<double>(longitudeDeg.value);
    }
    if (altitudeM.present) {
      map['altitude_m'] = Variable<double>(altitudeM.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (heartRateBpm.present) {
      map['heart_rate_bpm'] = Variable<int>(heartRateBpm.value);
    }
    if (cadenceRpm.present) {
      map['cadence_rpm'] = Variable<int>(cadenceRpm.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<int>(distanceMeters.value);
    }
    if (hrZone.present) {
      map['hr_zone'] = Variable<int>(hrZone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointsCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('timestampUtc: $timestampUtc, ')
          ..write('latitudeDeg: $latitudeDeg, ')
          ..write('longitudeDeg: $longitudeDeg, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('speedMps: $speedMps, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('cadenceRpm: $cadenceRpm, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('hrZone: $hrZone')
          ..write(')'))
        .toString();
  }
}

class $LapSplitsTable extends LapSplits
    with TableInfo<$LapSplitsTable, LapSplitRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LapSplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<int> activityId = GeneratedColumn<int>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES activities (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _splitIndexMeta = const VerificationMeta(
    'splitIndex',
  );
  @override
  late final GeneratedColumn<int> splitIndex = GeneratedColumn<int>(
    'split_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgPaceSecPerKmMeta = const VerificationMeta(
    'avgPaceSecPerKm',
  );
  @override
  late final GeneratedColumn<double> avgPaceSecPerKm = GeneratedColumn<double>(
    'avg_pace_sec_per_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgHeartRateMeta = const VerificationMeta(
    'avgHeartRate',
  );
  @override
  late final GeneratedColumn<double> avgHeartRate = GeneratedColumn<double>(
    'avg_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgCadenceMeta = const VerificationMeta(
    'avgCadence',
  );
  @override
  late final GeneratedColumn<double> avgCadence = GeneratedColumn<double>(
    'avg_cadence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elevationDeltaMMeta = const VerificationMeta(
    'elevationDeltaM',
  );
  @override
  late final GeneratedColumn<double> elevationDeltaM = GeneratedColumn<double>(
    'elevation_delta_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityId,
    splitIndex,
    distanceMeters,
    durationSec,
    avgPaceSecPerKm,
    avgHeartRate,
    avgCadence,
    elevationDeltaM,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lap_splits';
  @override
  VerificationContext validateIntegrity(
    Insertable<LapSplitRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('split_index')) {
      context.handle(
        _splitIndexMeta,
        splitIndex.isAcceptableOrUnknown(data['split_index']!, _splitIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_splitIndexMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecMeta);
    }
    if (data.containsKey('avg_pace_sec_per_km')) {
      context.handle(
        _avgPaceSecPerKmMeta,
        avgPaceSecPerKm.isAcceptableOrUnknown(
          data['avg_pace_sec_per_km']!,
          _avgPaceSecPerKmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgPaceSecPerKmMeta);
    }
    if (data.containsKey('avg_heart_rate')) {
      context.handle(
        _avgHeartRateMeta,
        avgHeartRate.isAcceptableOrUnknown(
          data['avg_heart_rate']!,
          _avgHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('avg_cadence')) {
      context.handle(
        _avgCadenceMeta,
        avgCadence.isAcceptableOrUnknown(data['avg_cadence']!, _avgCadenceMeta),
      );
    }
    if (data.containsKey('elevation_delta_m')) {
      context.handle(
        _elevationDeltaMMeta,
        elevationDeltaM.isAcceptableOrUnknown(
          data['elevation_delta_m']!,
          _elevationDeltaMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elevationDeltaMMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LapSplitRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LapSplitRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_id'],
      )!,
      splitIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}split_index'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      avgPaceSecPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_pace_sec_per_km'],
      )!,
      avgHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_heart_rate'],
      ),
      avgCadence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_cadence'],
      ),
      elevationDeltaM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_delta_m'],
      )!,
    );
  }

  @override
  $LapSplitsTable createAlias(String alias) {
    return $LapSplitsTable(attachedDatabase, alias);
  }
}

class LapSplitRecord extends DataClass implements Insertable<LapSplitRecord> {
  final int id;
  final int activityId;
  final int splitIndex;
  final double distanceMeters;
  final int durationSec;
  final double avgPaceSecPerKm;
  final double? avgHeartRate;
  final double? avgCadence;
  final double elevationDeltaM;
  const LapSplitRecord({
    required this.id,
    required this.activityId,
    required this.splitIndex,
    required this.distanceMeters,
    required this.durationSec,
    required this.avgPaceSecPerKm,
    this.avgHeartRate,
    this.avgCadence,
    required this.elevationDeltaM,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['activity_id'] = Variable<int>(activityId);
    map['split_index'] = Variable<int>(splitIndex);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['duration_sec'] = Variable<int>(durationSec);
    map['avg_pace_sec_per_km'] = Variable<double>(avgPaceSecPerKm);
    if (!nullToAbsent || avgHeartRate != null) {
      map['avg_heart_rate'] = Variable<double>(avgHeartRate);
    }
    if (!nullToAbsent || avgCadence != null) {
      map['avg_cadence'] = Variable<double>(avgCadence);
    }
    map['elevation_delta_m'] = Variable<double>(elevationDeltaM);
    return map;
  }

  LapSplitsCompanion toCompanion(bool nullToAbsent) {
    return LapSplitsCompanion(
      id: Value(id),
      activityId: Value(activityId),
      splitIndex: Value(splitIndex),
      distanceMeters: Value(distanceMeters),
      durationSec: Value(durationSec),
      avgPaceSecPerKm: Value(avgPaceSecPerKm),
      avgHeartRate: avgHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHeartRate),
      avgCadence: avgCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(avgCadence),
      elevationDeltaM: Value(elevationDeltaM),
    );
  }

  factory LapSplitRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LapSplitRecord(
      id: serializer.fromJson<int>(json['id']),
      activityId: serializer.fromJson<int>(json['activityId']),
      splitIndex: serializer.fromJson<int>(json['splitIndex']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      avgPaceSecPerKm: serializer.fromJson<double>(json['avgPaceSecPerKm']),
      avgHeartRate: serializer.fromJson<double?>(json['avgHeartRate']),
      avgCadence: serializer.fromJson<double?>(json['avgCadence']),
      elevationDeltaM: serializer.fromJson<double>(json['elevationDeltaM']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activityId': serializer.toJson<int>(activityId),
      'splitIndex': serializer.toJson<int>(splitIndex),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'durationSec': serializer.toJson<int>(durationSec),
      'avgPaceSecPerKm': serializer.toJson<double>(avgPaceSecPerKm),
      'avgHeartRate': serializer.toJson<double?>(avgHeartRate),
      'avgCadence': serializer.toJson<double?>(avgCadence),
      'elevationDeltaM': serializer.toJson<double>(elevationDeltaM),
    };
  }

  LapSplitRecord copyWith({
    int? id,
    int? activityId,
    int? splitIndex,
    double? distanceMeters,
    int? durationSec,
    double? avgPaceSecPerKm,
    Value<double?> avgHeartRate = const Value.absent(),
    Value<double?> avgCadence = const Value.absent(),
    double? elevationDeltaM,
  }) => LapSplitRecord(
    id: id ?? this.id,
    activityId: activityId ?? this.activityId,
    splitIndex: splitIndex ?? this.splitIndex,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    durationSec: durationSec ?? this.durationSec,
    avgPaceSecPerKm: avgPaceSecPerKm ?? this.avgPaceSecPerKm,
    avgHeartRate: avgHeartRate.present ? avgHeartRate.value : this.avgHeartRate,
    avgCadence: avgCadence.present ? avgCadence.value : this.avgCadence,
    elevationDeltaM: elevationDeltaM ?? this.elevationDeltaM,
  );
  LapSplitRecord copyWithCompanion(LapSplitsCompanion data) {
    return LapSplitRecord(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      splitIndex: data.splitIndex.present
          ? data.splitIndex.value
          : this.splitIndex,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      avgPaceSecPerKm: data.avgPaceSecPerKm.present
          ? data.avgPaceSecPerKm.value
          : this.avgPaceSecPerKm,
      avgHeartRate: data.avgHeartRate.present
          ? data.avgHeartRate.value
          : this.avgHeartRate,
      avgCadence: data.avgCadence.present
          ? data.avgCadence.value
          : this.avgCadence,
      elevationDeltaM: data.elevationDeltaM.present
          ? data.elevationDeltaM.value
          : this.elevationDeltaM,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LapSplitRecord(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('splitIndex: $splitIndex, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('durationSec: $durationSec, ')
          ..write('avgPaceSecPerKm: $avgPaceSecPerKm, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('elevationDeltaM: $elevationDeltaM')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityId,
    splitIndex,
    distanceMeters,
    durationSec,
    avgPaceSecPerKm,
    avgHeartRate,
    avgCadence,
    elevationDeltaM,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LapSplitRecord &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.splitIndex == this.splitIndex &&
          other.distanceMeters == this.distanceMeters &&
          other.durationSec == this.durationSec &&
          other.avgPaceSecPerKm == this.avgPaceSecPerKm &&
          other.avgHeartRate == this.avgHeartRate &&
          other.avgCadence == this.avgCadence &&
          other.elevationDeltaM == this.elevationDeltaM);
}

class LapSplitsCompanion extends UpdateCompanion<LapSplitRecord> {
  final Value<int> id;
  final Value<int> activityId;
  final Value<int> splitIndex;
  final Value<double> distanceMeters;
  final Value<int> durationSec;
  final Value<double> avgPaceSecPerKm;
  final Value<double?> avgHeartRate;
  final Value<double?> avgCadence;
  final Value<double> elevationDeltaM;
  const LapSplitsCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.splitIndex = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.avgPaceSecPerKm = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.avgCadence = const Value.absent(),
    this.elevationDeltaM = const Value.absent(),
  });
  LapSplitsCompanion.insert({
    this.id = const Value.absent(),
    required int activityId,
    required int splitIndex,
    required double distanceMeters,
    required int durationSec,
    required double avgPaceSecPerKm,
    this.avgHeartRate = const Value.absent(),
    this.avgCadence = const Value.absent(),
    required double elevationDeltaM,
  }) : activityId = Value(activityId),
       splitIndex = Value(splitIndex),
       distanceMeters = Value(distanceMeters),
       durationSec = Value(durationSec),
       avgPaceSecPerKm = Value(avgPaceSecPerKm),
       elevationDeltaM = Value(elevationDeltaM);
  static Insertable<LapSplitRecord> custom({
    Expression<int>? id,
    Expression<int>? activityId,
    Expression<int>? splitIndex,
    Expression<double>? distanceMeters,
    Expression<int>? durationSec,
    Expression<double>? avgPaceSecPerKm,
    Expression<double>? avgHeartRate,
    Expression<double>? avgCadence,
    Expression<double>? elevationDeltaM,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (splitIndex != null) 'split_index': splitIndex,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (durationSec != null) 'duration_sec': durationSec,
      if (avgPaceSecPerKm != null) 'avg_pace_sec_per_km': avgPaceSecPerKm,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (avgCadence != null) 'avg_cadence': avgCadence,
      if (elevationDeltaM != null) 'elevation_delta_m': elevationDeltaM,
    });
  }

  LapSplitsCompanion copyWith({
    Value<int>? id,
    Value<int>? activityId,
    Value<int>? splitIndex,
    Value<double>? distanceMeters,
    Value<int>? durationSec,
    Value<double>? avgPaceSecPerKm,
    Value<double?>? avgHeartRate,
    Value<double?>? avgCadence,
    Value<double>? elevationDeltaM,
  }) {
    return LapSplitsCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      splitIndex: splitIndex ?? this.splitIndex,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSec: durationSec ?? this.durationSec,
      avgPaceSecPerKm: avgPaceSecPerKm ?? this.avgPaceSecPerKm,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      avgCadence: avgCadence ?? this.avgCadence,
      elevationDeltaM: elevationDeltaM ?? this.elevationDeltaM,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<int>(activityId.value);
    }
    if (splitIndex.present) {
      map['split_index'] = Variable<int>(splitIndex.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (avgPaceSecPerKm.present) {
      map['avg_pace_sec_per_km'] = Variable<double>(avgPaceSecPerKm.value);
    }
    if (avgHeartRate.present) {
      map['avg_heart_rate'] = Variable<double>(avgHeartRate.value);
    }
    if (avgCadence.present) {
      map['avg_cadence'] = Variable<double>(avgCadence.value);
    }
    if (elevationDeltaM.present) {
      map['elevation_delta_m'] = Variable<double>(elevationDeltaM.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LapSplitsCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('splitIndex: $splitIndex, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('durationSec: $durationSec, ')
          ..write('avgPaceSecPerKm: $avgPaceSecPerKm, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('elevationDeltaM: $elevationDeltaM')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTableTable extends UserPreferencesTable
    with TableInfo<$UserPreferencesTableTable, UserPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _garminLoggedInMeta = const VerificationMeta(
    'garminLoggedIn',
  );
  @override
  late final GeneratedColumn<bool> garminLoggedIn = GeneratedColumn<bool>(
    'garmin_logged_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("garmin_logged_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastActivityStartTimeMeta =
      const VerificationMeta('lastActivityStartTime');
  @override
  late final GeneratedColumn<DateTime> lastActivityStartTime =
      GeneratedColumn<DateTime>(
        'last_activity_start_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrMaxManualMeta = const VerificationMeta(
    'hrMaxManual',
  );
  @override
  late final GeneratedColumn<int> hrMaxManual = GeneratedColumn<int>(
    'hr_max_manual',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String>
  hrZoneThresholds =
      GeneratedColumn<String>(
        'hr_zone_thresholds',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[60,70,80,90]'),
      ).withConverter<List<int>>(
        $UserPreferencesTableTable.$converterhrZoneThresholds,
      );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dark'),
  );
  static const VerificationMeta _unitSystemMeta = const VerificationMeta(
    'unitSystem',
  );
  @override
  late final GeneratedColumn<String> unitSystem = GeneratedColumn<String>(
    'unit_system',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('metric'),
  );
  static const VerificationMeta _weeklyMonthlyToggleMeta =
      const VerificationMeta('weeklyMonthlyToggle');
  @override
  late final GeneratedColumn<String> weeklyMonthlyToggle =
      GeneratedColumn<String>(
        'weekly_monthly_toggle',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('weekly'),
      );
  static const VerificationMeta _watermarkEnabledMeta = const VerificationMeta(
    'watermarkEnabled',
  );
  @override
  late final GeneratedColumn<bool> watermarkEnabled = GeneratedColumn<bool>(
    'watermark_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("watermark_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _defaultTemplateIdMeta = const VerificationMeta(
    'defaultTemplateId',
  );
  @override
  late final GeneratedColumn<String> defaultTemplateId =
      GeneratedColumn<String>(
        'default_template_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('routeGlow'),
      );
  static const VerificationMeta _backgroundSyncEnabledMeta =
      const VerificationMeta('backgroundSyncEnabled');
  @override
  late final GeneratedColumn<bool> backgroundSyncEnabled =
      GeneratedColumn<bool>(
        'background_sync_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("background_sync_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _backgroundSyncWifiOnlyMeta =
      const VerificationMeta('backgroundSyncWifiOnly');
  @override
  late final GeneratedColumn<bool> backgroundSyncWifiOnly =
      GeneratedColumn<bool>(
        'background_sync_wifi_only',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("background_sync_wifi_only" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _backgroundSyncRequireChargingMeta =
      const VerificationMeta('backgroundSyncRequireCharging');
  @override
  late final GeneratedColumn<bool> backgroundSyncRequireCharging =
      GeneratedColumn<bool>(
        'background_sync_require_charging',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("background_sync_require_charging" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _backgroundSyncIntervalMinutesMeta =
      const VerificationMeta('backgroundSyncIntervalMinutes');
  @override
  late final GeneratedColumn<int> backgroundSyncIntervalMinutes =
      GeneratedColumn<int>(
        'background_sync_interval_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(15),
      );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastBackupAtMeta = const VerificationMeta(
    'lastBackupAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastBackupAt = GeneratedColumn<DateTime>(
    'last_backup_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backupReminderEnabledMeta =
      const VerificationMeta('backupReminderEnabled');
  @override
  late final GeneratedColumn<bool> backupReminderEnabled =
      GeneratedColumn<bool>(
        'backup_reminder_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("backup_reminder_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _lastBackupReminderAtMeta =
      const VerificationMeta('lastBackupReminderAt');
  @override
  late final GeneratedColumn<DateTime> lastBackupReminderAt =
      GeneratedColumn<DateTime>(
        'last_backup_reminder_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    garminLoggedIn,
    lastSyncAt,
    lastActivityStartTime,
    birthDate,
    hrMaxManual,
    hrZoneThresholds,
    themeMode,
    unitSystem,
    weeklyMonthlyToggle,
    watermarkEnabled,
    defaultTemplateId,
    backgroundSyncEnabled,
    backgroundSyncWifiOnly,
    backgroundSyncRequireCharging,
    backgroundSyncIntervalMinutes,
    onboardingCompleted,
    lastBackupAt,
    backupReminderEnabled,
    lastBackupReminderAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('garmin_logged_in')) {
      context.handle(
        _garminLoggedInMeta,
        garminLoggedIn.isAcceptableOrUnknown(
          data['garmin_logged_in']!,
          _garminLoggedInMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_activity_start_time')) {
      context.handle(
        _lastActivityStartTimeMeta,
        lastActivityStartTime.isAcceptableOrUnknown(
          data['last_activity_start_time']!,
          _lastActivityStartTimeMeta,
        ),
      );
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('hr_max_manual')) {
      context.handle(
        _hrMaxManualMeta,
        hrMaxManual.isAcceptableOrUnknown(
          data['hr_max_manual']!,
          _hrMaxManualMeta,
        ),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('unit_system')) {
      context.handle(
        _unitSystemMeta,
        unitSystem.isAcceptableOrUnknown(data['unit_system']!, _unitSystemMeta),
      );
    }
    if (data.containsKey('weekly_monthly_toggle')) {
      context.handle(
        _weeklyMonthlyToggleMeta,
        weeklyMonthlyToggle.isAcceptableOrUnknown(
          data['weekly_monthly_toggle']!,
          _weeklyMonthlyToggleMeta,
        ),
      );
    }
    if (data.containsKey('watermark_enabled')) {
      context.handle(
        _watermarkEnabledMeta,
        watermarkEnabled.isAcceptableOrUnknown(
          data['watermark_enabled']!,
          _watermarkEnabledMeta,
        ),
      );
    }
    if (data.containsKey('default_template_id')) {
      context.handle(
        _defaultTemplateIdMeta,
        defaultTemplateId.isAcceptableOrUnknown(
          data['default_template_id']!,
          _defaultTemplateIdMeta,
        ),
      );
    }
    if (data.containsKey('background_sync_enabled')) {
      context.handle(
        _backgroundSyncEnabledMeta,
        backgroundSyncEnabled.isAcceptableOrUnknown(
          data['background_sync_enabled']!,
          _backgroundSyncEnabledMeta,
        ),
      );
    }
    if (data.containsKey('background_sync_wifi_only')) {
      context.handle(
        _backgroundSyncWifiOnlyMeta,
        backgroundSyncWifiOnly.isAcceptableOrUnknown(
          data['background_sync_wifi_only']!,
          _backgroundSyncWifiOnlyMeta,
        ),
      );
    }
    if (data.containsKey('background_sync_require_charging')) {
      context.handle(
        _backgroundSyncRequireChargingMeta,
        backgroundSyncRequireCharging.isAcceptableOrUnknown(
          data['background_sync_require_charging']!,
          _backgroundSyncRequireChargingMeta,
        ),
      );
    }
    if (data.containsKey('background_sync_interval_minutes')) {
      context.handle(
        _backgroundSyncIntervalMinutesMeta,
        backgroundSyncIntervalMinutes.isAcceptableOrUnknown(
          data['background_sync_interval_minutes']!,
          _backgroundSyncIntervalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    if (data.containsKey('last_backup_at')) {
      context.handle(
        _lastBackupAtMeta,
        lastBackupAt.isAcceptableOrUnknown(
          data['last_backup_at']!,
          _lastBackupAtMeta,
        ),
      );
    }
    if (data.containsKey('backup_reminder_enabled')) {
      context.handle(
        _backupReminderEnabledMeta,
        backupReminderEnabled.isAcceptableOrUnknown(
          data['backup_reminder_enabled']!,
          _backupReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('last_backup_reminder_at')) {
      context.handle(
        _lastBackupReminderAtMeta,
        lastBackupReminderAt.isAcceptableOrUnknown(
          data['last_backup_reminder_at']!,
          _lastBackupReminderAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      garminLoggedIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}garmin_logged_in'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      lastActivityStartTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_activity_start_time'],
      ),
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birth_date'],
      ),
      hrMaxManual: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_max_manual'],
      ),
      hrZoneThresholds: $UserPreferencesTableTable.$converterhrZoneThresholds
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}hr_zone_thresholds'],
            )!,
          ),
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      unitSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_system'],
      )!,
      weeklyMonthlyToggle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekly_monthly_toggle'],
      )!,
      watermarkEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}watermark_enabled'],
      )!,
      defaultTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_template_id'],
      )!,
      backgroundSyncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}background_sync_enabled'],
      )!,
      backgroundSyncWifiOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}background_sync_wifi_only'],
      )!,
      backgroundSyncRequireCharging: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}background_sync_require_charging'],
      )!,
      backgroundSyncIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}background_sync_interval_minutes'],
      )!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      lastBackupAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_backup_at'],
      ),
      backupReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}backup_reminder_enabled'],
      )!,
      lastBackupReminderAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_backup_reminder_at'],
      ),
    );
  }

  @override
  $UserPreferencesTableTable createAlias(String alias) {
    return $UserPreferencesTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<int>, String> $converterhrZoneThresholds =
      const IntListConverter();
}

class UserPreference extends DataClass implements Insertable<UserPreference> {
  final int id;
  final bool garminLoggedIn;
  final DateTime? lastSyncAt;
  final DateTime? lastActivityStartTime;
  final DateTime? birthDate;
  final int? hrMaxManual;
  final List<int> hrZoneThresholds;
  final String themeMode;
  final String unitSystem;
  final String weeklyMonthlyToggle;
  final bool watermarkEnabled;
  final String defaultTemplateId;
  final bool backgroundSyncEnabled;
  final bool backgroundSyncWifiOnly;
  final bool backgroundSyncRequireCharging;
  final int backgroundSyncIntervalMinutes;
  final bool onboardingCompleted;
  final DateTime? lastBackupAt;
  final bool backupReminderEnabled;
  final DateTime? lastBackupReminderAt;
  const UserPreference({
    required this.id,
    required this.garminLoggedIn,
    this.lastSyncAt,
    this.lastActivityStartTime,
    this.birthDate,
    this.hrMaxManual,
    required this.hrZoneThresholds,
    required this.themeMode,
    required this.unitSystem,
    required this.weeklyMonthlyToggle,
    required this.watermarkEnabled,
    required this.defaultTemplateId,
    required this.backgroundSyncEnabled,
    required this.backgroundSyncWifiOnly,
    required this.backgroundSyncRequireCharging,
    required this.backgroundSyncIntervalMinutes,
    required this.onboardingCompleted,
    this.lastBackupAt,
    required this.backupReminderEnabled,
    this.lastBackupReminderAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['garmin_logged_in'] = Variable<bool>(garminLoggedIn);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    if (!nullToAbsent || lastActivityStartTime != null) {
      map['last_activity_start_time'] = Variable<DateTime>(
        lastActivityStartTime,
      );
    }
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<DateTime>(birthDate);
    }
    if (!nullToAbsent || hrMaxManual != null) {
      map['hr_max_manual'] = Variable<int>(hrMaxManual);
    }
    {
      map['hr_zone_thresholds'] = Variable<String>(
        $UserPreferencesTableTable.$converterhrZoneThresholds.toSql(
          hrZoneThresholds,
        ),
      );
    }
    map['theme_mode'] = Variable<String>(themeMode);
    map['unit_system'] = Variable<String>(unitSystem);
    map['weekly_monthly_toggle'] = Variable<String>(weeklyMonthlyToggle);
    map['watermark_enabled'] = Variable<bool>(watermarkEnabled);
    map['default_template_id'] = Variable<String>(defaultTemplateId);
    map['background_sync_enabled'] = Variable<bool>(backgroundSyncEnabled);
    map['background_sync_wifi_only'] = Variable<bool>(backgroundSyncWifiOnly);
    map['background_sync_require_charging'] = Variable<bool>(
      backgroundSyncRequireCharging,
    );
    map['background_sync_interval_minutes'] = Variable<int>(
      backgroundSyncIntervalMinutes,
    );
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    if (!nullToAbsent || lastBackupAt != null) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt);
    }
    map['backup_reminder_enabled'] = Variable<bool>(backupReminderEnabled);
    if (!nullToAbsent || lastBackupReminderAt != null) {
      map['last_backup_reminder_at'] = Variable<DateTime>(lastBackupReminderAt);
    }
    return map;
  }

  UserPreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesTableCompanion(
      id: Value(id),
      garminLoggedIn: Value(garminLoggedIn),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastActivityStartTime: lastActivityStartTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActivityStartTime),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      hrMaxManual: hrMaxManual == null && nullToAbsent
          ? const Value.absent()
          : Value(hrMaxManual),
      hrZoneThresholds: Value(hrZoneThresholds),
      themeMode: Value(themeMode),
      unitSystem: Value(unitSystem),
      weeklyMonthlyToggle: Value(weeklyMonthlyToggle),
      watermarkEnabled: Value(watermarkEnabled),
      defaultTemplateId: Value(defaultTemplateId),
      backgroundSyncEnabled: Value(backgroundSyncEnabled),
      backgroundSyncWifiOnly: Value(backgroundSyncWifiOnly),
      backgroundSyncRequireCharging: Value(backgroundSyncRequireCharging),
      backgroundSyncIntervalMinutes: Value(backgroundSyncIntervalMinutes),
      onboardingCompleted: Value(onboardingCompleted),
      lastBackupAt: lastBackupAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupAt),
      backupReminderEnabled: Value(backupReminderEnabled),
      lastBackupReminderAt: lastBackupReminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupReminderAt),
    );
  }

  factory UserPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreference(
      id: serializer.fromJson<int>(json['id']),
      garminLoggedIn: serializer.fromJson<bool>(json['garminLoggedIn']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      lastActivityStartTime: serializer.fromJson<DateTime?>(
        json['lastActivityStartTime'],
      ),
      birthDate: serializer.fromJson<DateTime?>(json['birthDate']),
      hrMaxManual: serializer.fromJson<int?>(json['hrMaxManual']),
      hrZoneThresholds: serializer.fromJson<List<int>>(
        json['hrZoneThresholds'],
      ),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      unitSystem: serializer.fromJson<String>(json['unitSystem']),
      weeklyMonthlyToggle: serializer.fromJson<String>(
        json['weeklyMonthlyToggle'],
      ),
      watermarkEnabled: serializer.fromJson<bool>(json['watermarkEnabled']),
      defaultTemplateId: serializer.fromJson<String>(json['defaultTemplateId']),
      backgroundSyncEnabled: serializer.fromJson<bool>(
        json['backgroundSyncEnabled'],
      ),
      backgroundSyncWifiOnly: serializer.fromJson<bool>(
        json['backgroundSyncWifiOnly'],
      ),
      backgroundSyncRequireCharging: serializer.fromJson<bool>(
        json['backgroundSyncRequireCharging'],
      ),
      backgroundSyncIntervalMinutes: serializer.fromJson<int>(
        json['backgroundSyncIntervalMinutes'],
      ),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      lastBackupAt: serializer.fromJson<DateTime?>(json['lastBackupAt']),
      backupReminderEnabled: serializer.fromJson<bool>(
        json['backupReminderEnabled'],
      ),
      lastBackupReminderAt: serializer.fromJson<DateTime?>(
        json['lastBackupReminderAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'garminLoggedIn': serializer.toJson<bool>(garminLoggedIn),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'lastActivityStartTime': serializer.toJson<DateTime?>(
        lastActivityStartTime,
      ),
      'birthDate': serializer.toJson<DateTime?>(birthDate),
      'hrMaxManual': serializer.toJson<int?>(hrMaxManual),
      'hrZoneThresholds': serializer.toJson<List<int>>(hrZoneThresholds),
      'themeMode': serializer.toJson<String>(themeMode),
      'unitSystem': serializer.toJson<String>(unitSystem),
      'weeklyMonthlyToggle': serializer.toJson<String>(weeklyMonthlyToggle),
      'watermarkEnabled': serializer.toJson<bool>(watermarkEnabled),
      'defaultTemplateId': serializer.toJson<String>(defaultTemplateId),
      'backgroundSyncEnabled': serializer.toJson<bool>(backgroundSyncEnabled),
      'backgroundSyncWifiOnly': serializer.toJson<bool>(backgroundSyncWifiOnly),
      'backgroundSyncRequireCharging': serializer.toJson<bool>(
        backgroundSyncRequireCharging,
      ),
      'backgroundSyncIntervalMinutes': serializer.toJson<int>(
        backgroundSyncIntervalMinutes,
      ),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'lastBackupAt': serializer.toJson<DateTime?>(lastBackupAt),
      'backupReminderEnabled': serializer.toJson<bool>(backupReminderEnabled),
      'lastBackupReminderAt': serializer.toJson<DateTime?>(
        lastBackupReminderAt,
      ),
    };
  }

  UserPreference copyWith({
    int? id,
    bool? garminLoggedIn,
    Value<DateTime?> lastSyncAt = const Value.absent(),
    Value<DateTime?> lastActivityStartTime = const Value.absent(),
    Value<DateTime?> birthDate = const Value.absent(),
    Value<int?> hrMaxManual = const Value.absent(),
    List<int>? hrZoneThresholds,
    String? themeMode,
    String? unitSystem,
    String? weeklyMonthlyToggle,
    bool? watermarkEnabled,
    String? defaultTemplateId,
    bool? backgroundSyncEnabled,
    bool? backgroundSyncWifiOnly,
    bool? backgroundSyncRequireCharging,
    int? backgroundSyncIntervalMinutes,
    bool? onboardingCompleted,
    Value<DateTime?> lastBackupAt = const Value.absent(),
    bool? backupReminderEnabled,
    Value<DateTime?> lastBackupReminderAt = const Value.absent(),
  }) => UserPreference(
    id: id ?? this.id,
    garminLoggedIn: garminLoggedIn ?? this.garminLoggedIn,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastActivityStartTime: lastActivityStartTime.present
        ? lastActivityStartTime.value
        : this.lastActivityStartTime,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    hrMaxManual: hrMaxManual.present ? hrMaxManual.value : this.hrMaxManual,
    hrZoneThresholds: hrZoneThresholds ?? this.hrZoneThresholds,
    themeMode: themeMode ?? this.themeMode,
    unitSystem: unitSystem ?? this.unitSystem,
    weeklyMonthlyToggle: weeklyMonthlyToggle ?? this.weeklyMonthlyToggle,
    watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
    defaultTemplateId: defaultTemplateId ?? this.defaultTemplateId,
    backgroundSyncEnabled: backgroundSyncEnabled ?? this.backgroundSyncEnabled,
    backgroundSyncWifiOnly:
        backgroundSyncWifiOnly ?? this.backgroundSyncWifiOnly,
    backgroundSyncRequireCharging:
        backgroundSyncRequireCharging ?? this.backgroundSyncRequireCharging,
    backgroundSyncIntervalMinutes:
        backgroundSyncIntervalMinutes ?? this.backgroundSyncIntervalMinutes,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    lastBackupAt: lastBackupAt.present ? lastBackupAt.value : this.lastBackupAt,
    backupReminderEnabled: backupReminderEnabled ?? this.backupReminderEnabled,
    lastBackupReminderAt: lastBackupReminderAt.present
        ? lastBackupReminderAt.value
        : this.lastBackupReminderAt,
  );
  UserPreference copyWithCompanion(UserPreferencesTableCompanion data) {
    return UserPreference(
      id: data.id.present ? data.id.value : this.id,
      garminLoggedIn: data.garminLoggedIn.present
          ? data.garminLoggedIn.value
          : this.garminLoggedIn,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      lastActivityStartTime: data.lastActivityStartTime.present
          ? data.lastActivityStartTime.value
          : this.lastActivityStartTime,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      hrMaxManual: data.hrMaxManual.present
          ? data.hrMaxManual.value
          : this.hrMaxManual,
      hrZoneThresholds: data.hrZoneThresholds.present
          ? data.hrZoneThresholds.value
          : this.hrZoneThresholds,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      unitSystem: data.unitSystem.present
          ? data.unitSystem.value
          : this.unitSystem,
      weeklyMonthlyToggle: data.weeklyMonthlyToggle.present
          ? data.weeklyMonthlyToggle.value
          : this.weeklyMonthlyToggle,
      watermarkEnabled: data.watermarkEnabled.present
          ? data.watermarkEnabled.value
          : this.watermarkEnabled,
      defaultTemplateId: data.defaultTemplateId.present
          ? data.defaultTemplateId.value
          : this.defaultTemplateId,
      backgroundSyncEnabled: data.backgroundSyncEnabled.present
          ? data.backgroundSyncEnabled.value
          : this.backgroundSyncEnabled,
      backgroundSyncWifiOnly: data.backgroundSyncWifiOnly.present
          ? data.backgroundSyncWifiOnly.value
          : this.backgroundSyncWifiOnly,
      backgroundSyncRequireCharging: data.backgroundSyncRequireCharging.present
          ? data.backgroundSyncRequireCharging.value
          : this.backgroundSyncRequireCharging,
      backgroundSyncIntervalMinutes: data.backgroundSyncIntervalMinutes.present
          ? data.backgroundSyncIntervalMinutes.value
          : this.backgroundSyncIntervalMinutes,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      lastBackupAt: data.lastBackupAt.present
          ? data.lastBackupAt.value
          : this.lastBackupAt,
      backupReminderEnabled: data.backupReminderEnabled.present
          ? data.backupReminderEnabled.value
          : this.backupReminderEnabled,
      lastBackupReminderAt: data.lastBackupReminderAt.present
          ? data.lastBackupReminderAt.value
          : this.lastBackupReminderAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreference(')
          ..write('id: $id, ')
          ..write('garminLoggedIn: $garminLoggedIn, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastActivityStartTime: $lastActivityStartTime, ')
          ..write('birthDate: $birthDate, ')
          ..write('hrMaxManual: $hrMaxManual, ')
          ..write('hrZoneThresholds: $hrZoneThresholds, ')
          ..write('themeMode: $themeMode, ')
          ..write('unitSystem: $unitSystem, ')
          ..write('weeklyMonthlyToggle: $weeklyMonthlyToggle, ')
          ..write('watermarkEnabled: $watermarkEnabled, ')
          ..write('defaultTemplateId: $defaultTemplateId, ')
          ..write('backgroundSyncEnabled: $backgroundSyncEnabled, ')
          ..write('backgroundSyncWifiOnly: $backgroundSyncWifiOnly, ')
          ..write(
            'backgroundSyncRequireCharging: $backgroundSyncRequireCharging, ',
          )
          ..write(
            'backgroundSyncIntervalMinutes: $backgroundSyncIntervalMinutes, ',
          )
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('backupReminderEnabled: $backupReminderEnabled, ')
          ..write('lastBackupReminderAt: $lastBackupReminderAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    garminLoggedIn,
    lastSyncAt,
    lastActivityStartTime,
    birthDate,
    hrMaxManual,
    hrZoneThresholds,
    themeMode,
    unitSystem,
    weeklyMonthlyToggle,
    watermarkEnabled,
    defaultTemplateId,
    backgroundSyncEnabled,
    backgroundSyncWifiOnly,
    backgroundSyncRequireCharging,
    backgroundSyncIntervalMinutes,
    onboardingCompleted,
    lastBackupAt,
    backupReminderEnabled,
    lastBackupReminderAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreference &&
          other.id == this.id &&
          other.garminLoggedIn == this.garminLoggedIn &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastActivityStartTime == this.lastActivityStartTime &&
          other.birthDate == this.birthDate &&
          other.hrMaxManual == this.hrMaxManual &&
          other.hrZoneThresholds == this.hrZoneThresholds &&
          other.themeMode == this.themeMode &&
          other.unitSystem == this.unitSystem &&
          other.weeklyMonthlyToggle == this.weeklyMonthlyToggle &&
          other.watermarkEnabled == this.watermarkEnabled &&
          other.defaultTemplateId == this.defaultTemplateId &&
          other.backgroundSyncEnabled == this.backgroundSyncEnabled &&
          other.backgroundSyncWifiOnly == this.backgroundSyncWifiOnly &&
          other.backgroundSyncRequireCharging ==
              this.backgroundSyncRequireCharging &&
          other.backgroundSyncIntervalMinutes ==
              this.backgroundSyncIntervalMinutes &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.lastBackupAt == this.lastBackupAt &&
          other.backupReminderEnabled == this.backupReminderEnabled &&
          other.lastBackupReminderAt == this.lastBackupReminderAt);
}

class UserPreferencesTableCompanion extends UpdateCompanion<UserPreference> {
  final Value<int> id;
  final Value<bool> garminLoggedIn;
  final Value<DateTime?> lastSyncAt;
  final Value<DateTime?> lastActivityStartTime;
  final Value<DateTime?> birthDate;
  final Value<int?> hrMaxManual;
  final Value<List<int>> hrZoneThresholds;
  final Value<String> themeMode;
  final Value<String> unitSystem;
  final Value<String> weeklyMonthlyToggle;
  final Value<bool> watermarkEnabled;
  final Value<String> defaultTemplateId;
  final Value<bool> backgroundSyncEnabled;
  final Value<bool> backgroundSyncWifiOnly;
  final Value<bool> backgroundSyncRequireCharging;
  final Value<int> backgroundSyncIntervalMinutes;
  final Value<bool> onboardingCompleted;
  final Value<DateTime?> lastBackupAt;
  final Value<bool> backupReminderEnabled;
  final Value<DateTime?> lastBackupReminderAt;
  const UserPreferencesTableCompanion({
    this.id = const Value.absent(),
    this.garminLoggedIn = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastActivityStartTime = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.hrMaxManual = const Value.absent(),
    this.hrZoneThresholds = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.unitSystem = const Value.absent(),
    this.weeklyMonthlyToggle = const Value.absent(),
    this.watermarkEnabled = const Value.absent(),
    this.defaultTemplateId = const Value.absent(),
    this.backgroundSyncEnabled = const Value.absent(),
    this.backgroundSyncWifiOnly = const Value.absent(),
    this.backgroundSyncRequireCharging = const Value.absent(),
    this.backgroundSyncIntervalMinutes = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.backupReminderEnabled = const Value.absent(),
    this.lastBackupReminderAt = const Value.absent(),
  });
  UserPreferencesTableCompanion.insert({
    this.id = const Value.absent(),
    this.garminLoggedIn = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastActivityStartTime = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.hrMaxManual = const Value.absent(),
    this.hrZoneThresholds = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.unitSystem = const Value.absent(),
    this.weeklyMonthlyToggle = const Value.absent(),
    this.watermarkEnabled = const Value.absent(),
    this.defaultTemplateId = const Value.absent(),
    this.backgroundSyncEnabled = const Value.absent(),
    this.backgroundSyncWifiOnly = const Value.absent(),
    this.backgroundSyncRequireCharging = const Value.absent(),
    this.backgroundSyncIntervalMinutes = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.backupReminderEnabled = const Value.absent(),
    this.lastBackupReminderAt = const Value.absent(),
  });
  static Insertable<UserPreference> custom({
    Expression<int>? id,
    Expression<bool>? garminLoggedIn,
    Expression<DateTime>? lastSyncAt,
    Expression<DateTime>? lastActivityStartTime,
    Expression<DateTime>? birthDate,
    Expression<int>? hrMaxManual,
    Expression<String>? hrZoneThresholds,
    Expression<String>? themeMode,
    Expression<String>? unitSystem,
    Expression<String>? weeklyMonthlyToggle,
    Expression<bool>? watermarkEnabled,
    Expression<String>? defaultTemplateId,
    Expression<bool>? backgroundSyncEnabled,
    Expression<bool>? backgroundSyncWifiOnly,
    Expression<bool>? backgroundSyncRequireCharging,
    Expression<int>? backgroundSyncIntervalMinutes,
    Expression<bool>? onboardingCompleted,
    Expression<DateTime>? lastBackupAt,
    Expression<bool>? backupReminderEnabled,
    Expression<DateTime>? lastBackupReminderAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (garminLoggedIn != null) 'garmin_logged_in': garminLoggedIn,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastActivityStartTime != null)
        'last_activity_start_time': lastActivityStartTime,
      if (birthDate != null) 'birth_date': birthDate,
      if (hrMaxManual != null) 'hr_max_manual': hrMaxManual,
      if (hrZoneThresholds != null) 'hr_zone_thresholds': hrZoneThresholds,
      if (themeMode != null) 'theme_mode': themeMode,
      if (unitSystem != null) 'unit_system': unitSystem,
      if (weeklyMonthlyToggle != null)
        'weekly_monthly_toggle': weeklyMonthlyToggle,
      if (watermarkEnabled != null) 'watermark_enabled': watermarkEnabled,
      if (defaultTemplateId != null) 'default_template_id': defaultTemplateId,
      if (backgroundSyncEnabled != null)
        'background_sync_enabled': backgroundSyncEnabled,
      if (backgroundSyncWifiOnly != null)
        'background_sync_wifi_only': backgroundSyncWifiOnly,
      if (backgroundSyncRequireCharging != null)
        'background_sync_require_charging': backgroundSyncRequireCharging,
      if (backgroundSyncIntervalMinutes != null)
        'background_sync_interval_minutes': backgroundSyncIntervalMinutes,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (lastBackupAt != null) 'last_backup_at': lastBackupAt,
      if (backupReminderEnabled != null)
        'backup_reminder_enabled': backupReminderEnabled,
      if (lastBackupReminderAt != null)
        'last_backup_reminder_at': lastBackupReminderAt,
    });
  }

  UserPreferencesTableCompanion copyWith({
    Value<int>? id,
    Value<bool>? garminLoggedIn,
    Value<DateTime?>? lastSyncAt,
    Value<DateTime?>? lastActivityStartTime,
    Value<DateTime?>? birthDate,
    Value<int?>? hrMaxManual,
    Value<List<int>>? hrZoneThresholds,
    Value<String>? themeMode,
    Value<String>? unitSystem,
    Value<String>? weeklyMonthlyToggle,
    Value<bool>? watermarkEnabled,
    Value<String>? defaultTemplateId,
    Value<bool>? backgroundSyncEnabled,
    Value<bool>? backgroundSyncWifiOnly,
    Value<bool>? backgroundSyncRequireCharging,
    Value<int>? backgroundSyncIntervalMinutes,
    Value<bool>? onboardingCompleted,
    Value<DateTime?>? lastBackupAt,
    Value<bool>? backupReminderEnabled,
    Value<DateTime?>? lastBackupReminderAt,
  }) {
    return UserPreferencesTableCompanion(
      id: id ?? this.id,
      garminLoggedIn: garminLoggedIn ?? this.garminLoggedIn,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastActivityStartTime:
          lastActivityStartTime ?? this.lastActivityStartTime,
      birthDate: birthDate ?? this.birthDate,
      hrMaxManual: hrMaxManual ?? this.hrMaxManual,
      hrZoneThresholds: hrZoneThresholds ?? this.hrZoneThresholds,
      themeMode: themeMode ?? this.themeMode,
      unitSystem: unitSystem ?? this.unitSystem,
      weeklyMonthlyToggle: weeklyMonthlyToggle ?? this.weeklyMonthlyToggle,
      watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
      defaultTemplateId: defaultTemplateId ?? this.defaultTemplateId,
      backgroundSyncEnabled:
          backgroundSyncEnabled ?? this.backgroundSyncEnabled,
      backgroundSyncWifiOnly:
          backgroundSyncWifiOnly ?? this.backgroundSyncWifiOnly,
      backgroundSyncRequireCharging:
          backgroundSyncRequireCharging ?? this.backgroundSyncRequireCharging,
      backgroundSyncIntervalMinutes:
          backgroundSyncIntervalMinutes ?? this.backgroundSyncIntervalMinutes,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      backupReminderEnabled:
          backupReminderEnabled ?? this.backupReminderEnabled,
      lastBackupReminderAt: lastBackupReminderAt ?? this.lastBackupReminderAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (garminLoggedIn.present) {
      map['garmin_logged_in'] = Variable<bool>(garminLoggedIn.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (lastActivityStartTime.present) {
      map['last_activity_start_time'] = Variable<DateTime>(
        lastActivityStartTime.value,
      );
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (hrMaxManual.present) {
      map['hr_max_manual'] = Variable<int>(hrMaxManual.value);
    }
    if (hrZoneThresholds.present) {
      map['hr_zone_thresholds'] = Variable<String>(
        $UserPreferencesTableTable.$converterhrZoneThresholds.toSql(
          hrZoneThresholds.value,
        ),
      );
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (unitSystem.present) {
      map['unit_system'] = Variable<String>(unitSystem.value);
    }
    if (weeklyMonthlyToggle.present) {
      map['weekly_monthly_toggle'] = Variable<String>(
        weeklyMonthlyToggle.value,
      );
    }
    if (watermarkEnabled.present) {
      map['watermark_enabled'] = Variable<bool>(watermarkEnabled.value);
    }
    if (defaultTemplateId.present) {
      map['default_template_id'] = Variable<String>(defaultTemplateId.value);
    }
    if (backgroundSyncEnabled.present) {
      map['background_sync_enabled'] = Variable<bool>(
        backgroundSyncEnabled.value,
      );
    }
    if (backgroundSyncWifiOnly.present) {
      map['background_sync_wifi_only'] = Variable<bool>(
        backgroundSyncWifiOnly.value,
      );
    }
    if (backgroundSyncRequireCharging.present) {
      map['background_sync_require_charging'] = Variable<bool>(
        backgroundSyncRequireCharging.value,
      );
    }
    if (backgroundSyncIntervalMinutes.present) {
      map['background_sync_interval_minutes'] = Variable<int>(
        backgroundSyncIntervalMinutes.value,
      );
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (lastBackupAt.present) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt.value);
    }
    if (backupReminderEnabled.present) {
      map['backup_reminder_enabled'] = Variable<bool>(
        backupReminderEnabled.value,
      );
    }
    if (lastBackupReminderAt.present) {
      map['last_backup_reminder_at'] = Variable<DateTime>(
        lastBackupReminderAt.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableCompanion(')
          ..write('id: $id, ')
          ..write('garminLoggedIn: $garminLoggedIn, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastActivityStartTime: $lastActivityStartTime, ')
          ..write('birthDate: $birthDate, ')
          ..write('hrMaxManual: $hrMaxManual, ')
          ..write('hrZoneThresholds: $hrZoneThresholds, ')
          ..write('themeMode: $themeMode, ')
          ..write('unitSystem: $unitSystem, ')
          ..write('weeklyMonthlyToggle: $weeklyMonthlyToggle, ')
          ..write('watermarkEnabled: $watermarkEnabled, ')
          ..write('defaultTemplateId: $defaultTemplateId, ')
          ..write('backgroundSyncEnabled: $backgroundSyncEnabled, ')
          ..write('backgroundSyncWifiOnly: $backgroundSyncWifiOnly, ')
          ..write(
            'backgroundSyncRequireCharging: $backgroundSyncRequireCharging, ',
          )
          ..write(
            'backgroundSyncIntervalMinutes: $backgroundSyncIntervalMinutes, ',
          )
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('backupReminderEnabled: $backupReminderEnabled, ')
          ..write('lastBackupReminderAt: $lastBackupReminderAt')
          ..write(')'))
        .toString();
  }
}

class $ActivityBestEffortsTable extends ActivityBestEfforts
    with TableInfo<$ActivityBestEffortsTable, BestEffortRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityBestEffortsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<int> activityId = GeneratedColumn<int>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES activities (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _distanceKeyMeta = const VerificationMeta(
    'distanceKey',
  );
  @override
  late final GeneratedColumn<String> distanceKey = GeneratedColumn<String>(
    'distance_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDistanceMetersMeta =
      const VerificationMeta('targetDistanceMeters');
  @override
  late final GeneratedColumn<double> targetDistanceMeters =
      GeneratedColumn<double>(
        'target_distance_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paceSecPerKmMeta = const VerificationMeta(
    'paceSecPerKm',
  );
  @override
  late final GeneratedColumn<double> paceSecPerKm = GeneratedColumn<double>(
    'pace_sec_per_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityId,
    distanceKey,
    targetDistanceMeters,
    durationSec,
    paceSecPerKm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_best_efforts';
  @override
  VerificationContext validateIntegrity(
    Insertable<BestEffortRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('distance_key')) {
      context.handle(
        _distanceKeyMeta,
        distanceKey.isAcceptableOrUnknown(
          data['distance_key']!,
          _distanceKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceKeyMeta);
    }
    if (data.containsKey('target_distance_meters')) {
      context.handle(
        _targetDistanceMetersMeta,
        targetDistanceMeters.isAcceptableOrUnknown(
          data['target_distance_meters']!,
          _targetDistanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetDistanceMetersMeta);
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecMeta);
    }
    if (data.containsKey('pace_sec_per_km')) {
      context.handle(
        _paceSecPerKmMeta,
        paceSecPerKm.isAcceptableOrUnknown(
          data['pace_sec_per_km']!,
          _paceSecPerKmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paceSecPerKmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BestEffortRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BestEffortRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_id'],
      )!,
      distanceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distance_key'],
      )!,
      targetDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_distance_meters'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      paceSecPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pace_sec_per_km'],
      )!,
    );
  }

  @override
  $ActivityBestEffortsTable createAlias(String alias) {
    return $ActivityBestEffortsTable(attachedDatabase, alias);
  }
}

class BestEffortRecord extends DataClass
    implements Insertable<BestEffortRecord> {
  final int id;
  final int activityId;
  final String distanceKey;
  final double targetDistanceMeters;
  final int durationSec;
  final double paceSecPerKm;
  const BestEffortRecord({
    required this.id,
    required this.activityId,
    required this.distanceKey,
    required this.targetDistanceMeters,
    required this.durationSec,
    required this.paceSecPerKm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['activity_id'] = Variable<int>(activityId);
    map['distance_key'] = Variable<String>(distanceKey);
    map['target_distance_meters'] = Variable<double>(targetDistanceMeters);
    map['duration_sec'] = Variable<int>(durationSec);
    map['pace_sec_per_km'] = Variable<double>(paceSecPerKm);
    return map;
  }

  ActivityBestEffortsCompanion toCompanion(bool nullToAbsent) {
    return ActivityBestEffortsCompanion(
      id: Value(id),
      activityId: Value(activityId),
      distanceKey: Value(distanceKey),
      targetDistanceMeters: Value(targetDistanceMeters),
      durationSec: Value(durationSec),
      paceSecPerKm: Value(paceSecPerKm),
    );
  }

  factory BestEffortRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BestEffortRecord(
      id: serializer.fromJson<int>(json['id']),
      activityId: serializer.fromJson<int>(json['activityId']),
      distanceKey: serializer.fromJson<String>(json['distanceKey']),
      targetDistanceMeters: serializer.fromJson<double>(
        json['targetDistanceMeters'],
      ),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      paceSecPerKm: serializer.fromJson<double>(json['paceSecPerKm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activityId': serializer.toJson<int>(activityId),
      'distanceKey': serializer.toJson<String>(distanceKey),
      'targetDistanceMeters': serializer.toJson<double>(targetDistanceMeters),
      'durationSec': serializer.toJson<int>(durationSec),
      'paceSecPerKm': serializer.toJson<double>(paceSecPerKm),
    };
  }

  BestEffortRecord copyWith({
    int? id,
    int? activityId,
    String? distanceKey,
    double? targetDistanceMeters,
    int? durationSec,
    double? paceSecPerKm,
  }) => BestEffortRecord(
    id: id ?? this.id,
    activityId: activityId ?? this.activityId,
    distanceKey: distanceKey ?? this.distanceKey,
    targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
    durationSec: durationSec ?? this.durationSec,
    paceSecPerKm: paceSecPerKm ?? this.paceSecPerKm,
  );
  BestEffortRecord copyWithCompanion(ActivityBestEffortsCompanion data) {
    return BestEffortRecord(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      distanceKey: data.distanceKey.present
          ? data.distanceKey.value
          : this.distanceKey,
      targetDistanceMeters: data.targetDistanceMeters.present
          ? data.targetDistanceMeters.value
          : this.targetDistanceMeters,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      paceSecPerKm: data.paceSecPerKm.present
          ? data.paceSecPerKm.value
          : this.paceSecPerKm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BestEffortRecord(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('distanceKey: $distanceKey, ')
          ..write('targetDistanceMeters: $targetDistanceMeters, ')
          ..write('durationSec: $durationSec, ')
          ..write('paceSecPerKm: $paceSecPerKm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityId,
    distanceKey,
    targetDistanceMeters,
    durationSec,
    paceSecPerKm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BestEffortRecord &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.distanceKey == this.distanceKey &&
          other.targetDistanceMeters == this.targetDistanceMeters &&
          other.durationSec == this.durationSec &&
          other.paceSecPerKm == this.paceSecPerKm);
}

class ActivityBestEffortsCompanion extends UpdateCompanion<BestEffortRecord> {
  final Value<int> id;
  final Value<int> activityId;
  final Value<String> distanceKey;
  final Value<double> targetDistanceMeters;
  final Value<int> durationSec;
  final Value<double> paceSecPerKm;
  const ActivityBestEffortsCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.distanceKey = const Value.absent(),
    this.targetDistanceMeters = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.paceSecPerKm = const Value.absent(),
  });
  ActivityBestEffortsCompanion.insert({
    this.id = const Value.absent(),
    required int activityId,
    required String distanceKey,
    required double targetDistanceMeters,
    required int durationSec,
    required double paceSecPerKm,
  }) : activityId = Value(activityId),
       distanceKey = Value(distanceKey),
       targetDistanceMeters = Value(targetDistanceMeters),
       durationSec = Value(durationSec),
       paceSecPerKm = Value(paceSecPerKm);
  static Insertable<BestEffortRecord> custom({
    Expression<int>? id,
    Expression<int>? activityId,
    Expression<String>? distanceKey,
    Expression<double>? targetDistanceMeters,
    Expression<int>? durationSec,
    Expression<double>? paceSecPerKm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (distanceKey != null) 'distance_key': distanceKey,
      if (targetDistanceMeters != null)
        'target_distance_meters': targetDistanceMeters,
      if (durationSec != null) 'duration_sec': durationSec,
      if (paceSecPerKm != null) 'pace_sec_per_km': paceSecPerKm,
    });
  }

  ActivityBestEffortsCompanion copyWith({
    Value<int>? id,
    Value<int>? activityId,
    Value<String>? distanceKey,
    Value<double>? targetDistanceMeters,
    Value<int>? durationSec,
    Value<double>? paceSecPerKm,
  }) {
    return ActivityBestEffortsCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      distanceKey: distanceKey ?? this.distanceKey,
      targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
      durationSec: durationSec ?? this.durationSec,
      paceSecPerKm: paceSecPerKm ?? this.paceSecPerKm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<int>(activityId.value);
    }
    if (distanceKey.present) {
      map['distance_key'] = Variable<String>(distanceKey.value);
    }
    if (targetDistanceMeters.present) {
      map['target_distance_meters'] = Variable<double>(
        targetDistanceMeters.value,
      );
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (paceSecPerKm.present) {
      map['pace_sec_per_km'] = Variable<double>(paceSecPerKm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityBestEffortsCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('distanceKey: $distanceKey, ')
          ..write('targetDistanceMeters: $targetDistanceMeters, ')
          ..write('durationSec: $durationSec, ')
          ..write('paceSecPerKm: $paceSecPerKm')
          ..write(')'))
        .toString();
  }
}

class $StoryPresetsTable extends StoryPresets
    with TableInfo<$StoryPresetsTable, StoryPresetRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    configJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryPresetRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryPresetRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryPresetRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StoryPresetsTable createAlias(String alias) {
    return $StoryPresetsTable(attachedDatabase, alias);
  }
}

class StoryPresetRecord extends DataClass
    implements Insertable<StoryPresetRecord> {
  final int id;
  final String name;
  final String configJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StoryPresetRecord({
    required this.id,
    required this.name,
    required this.configJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['config_json'] = Variable<String>(configJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoryPresetsCompanion toCompanion(bool nullToAbsent) {
    return StoryPresetsCompanion(
      id: Value(id),
      name: Value(name),
      configJson: Value(configJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoryPresetRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryPresetRecord(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      configJson: serializer.fromJson<String>(json['configJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'configJson': serializer.toJson<String>(configJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoryPresetRecord copyWith({
    int? id,
    String? name,
    String? configJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StoryPresetRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    configJson: configJson ?? this.configJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StoryPresetRecord copyWithCompanion(StoryPresetsCompanion data) {
    return StoryPresetRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryPresetRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, configJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryPresetRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.configJson == this.configJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StoryPresetsCompanion extends UpdateCompanion<StoryPresetRecord> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> configJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const StoryPresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.configJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StoryPresetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String configJson,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       configJson = Value(configJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StoryPresetRecord> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? configJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (configJson != null) 'config_json': configJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StoryPresetsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? configJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return StoryPresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      configJson: configJson ?? this.configJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryPresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $TrackPointsTable trackPoints = $TrackPointsTable(this);
  late final $LapSplitsTable lapSplits = $LapSplitsTable(this);
  late final $UserPreferencesTableTable userPreferencesTable =
      $UserPreferencesTableTable(this);
  late final $ActivityBestEffortsTable activityBestEfforts =
      $ActivityBestEffortsTable(this);
  late final $StoryPresetsTable storyPresets = $StoryPresetsTable(this);
  late final Index idxActivitiesStartTime = Index(
    'idx_activities_start_time',
    'CREATE INDEX idx_activities_start_time ON activities (start_time_utc)',
  );
  late final Index idxActivitiesFitHash = Index(
    'idx_activities_fit_hash',
    'CREATE INDEX idx_activities_fit_hash ON activities (fit_file_hash)',
  );
  late final Index idxTrackPointsActivityTs = Index(
    'idx_track_points_activity_ts',
    'CREATE INDEX idx_track_points_activity_ts ON track_points (activity_id, timestamp_utc)',
  );
  late final Index idxLapSplitsActivityIdx = Index(
    'idx_lap_splits_activity_idx',
    'CREATE INDEX idx_lap_splits_activity_idx ON lap_splits (activity_id, split_index)',
  );
  late final Index idxBestEffortsDistDur = Index(
    'idx_best_efforts_dist_dur',
    'CREATE INDEX idx_best_efforts_dist_dur ON activity_best_efforts (distance_key, duration_sec)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    activities,
    trackPoints,
    lapSplits,
    userPreferencesTable,
    activityBestEfforts,
    storyPresets,
    idxActivitiesStartTime,
    idxActivitiesFitHash,
    idxTrackPointsActivityTs,
    idxLapSplitsActivityIdx,
    idxBestEffortsDistDur,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'activities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('track_points', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'activities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lap_splits', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'activities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('activity_best_efforts', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ActivitiesTableCreateCompanionBuilder = ActivitiesCompanion Function({
  Value<int> id,
  Value<int?> garminActivityId,
  required String title,
  required int sportType,
  required DateTime startTimeUtc,
  required int utcOffsetSeconds,
  required int durationTotalSec,
  required int durationMovingSec,
  required double distanceMeters,
  required double avgPaceSecPerKm,
  Value<double?> avgHeartRate,
  Value<double?> maxHeartRate,
  Value<double?> avgCadence,
  required double totalElevationGainM,
  required double totalElevationLossM,
  required int caloriesKcal,
  Value<bool> isIndoor,
  Value<bool> hasGpsTrack,
  Value<String> gpsQuality,
  required String source,
  required String syncStatus,
  Value<String?> originalFitPath,
  required String fitFileHash,
  required List<int> splitPacesSecPerKm,
  required List<int> zoneDurationsSec,
  Value<bool> hasCustomTitle,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$ActivitiesTableUpdateCompanionBuilder = ActivitiesCompanion Function({
  Value<int> id,
  Value<int?> garminActivityId,
  Value<String> title,
  Value<int> sportType,
  Value<DateTime> startTimeUtc,
  Value<int> utcOffsetSeconds,
  Value<int> durationTotalSec,
  Value<int> durationMovingSec,
  Value<double> distanceMeters,
  Value<double> avgPaceSecPerKm,
  Value<double?> avgHeartRate,
  Value<double?> maxHeartRate,
  Value<double?> avgCadence,
  Value<double> totalElevationGainM,
  Value<double> totalElevationLossM,
  Value<int> caloriesKcal,
  Value<bool> isIndoor,
  Value<bool> hasGpsTrack,
  Value<String> gpsQuality,
  Value<String> source,
  Value<String> syncStatus,
  Value<String?> originalFitPath,
  Value<String> fitFileHash,
  Value<List<int>> splitPacesSecPerKm,
  Value<List<int>> zoneDurationsSec,
  Value<bool> hasCustomTitle,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ActivitiesTableReferences
    extends BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityRecord> {
  $$ActivitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackPointsTable, List<TrackPointRecord>>
  _trackPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackPoints,
    aliasName: 'activities__id__track_points__activity_id',
  );

  $$TrackPointsTableProcessedTableManager get trackPointsRefs {
    final manager = $$TrackPointsTableTableManager(
      $_db,
      $_db.trackPoints,
    ).filter((f) => f.activityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LapSplitsTable, List<LapSplitRecord>>
  _lapSplitsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lapSplits,
    aliasName: 'activities__id__lap_splits__activity_id',
  );

  $$LapSplitsTableProcessedTableManager get lapSplitsRefs {
    final manager = $$LapSplitsTableTableManager(
      $_db,
      $_db.lapSplits,
    ).filter((f) => f.activityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lapSplitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ActivityBestEffortsTable, List<BestEffortRecord>>
  _activityBestEffortsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.activityBestEfforts,
        aliasName: 'activities__id__activity_best_efforts__activity_id',
      );

  $$ActivityBestEffortsTableProcessedTableManager get activityBestEffortsRefs {
    final manager = $$ActivityBestEffortsTableTableManager(
      $_db,
      $_db.activityBestEfforts,
    ).filter((f) => f.activityId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _activityBestEffortsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get garminActivityId => $composableBuilder(
    column: $table.garminActivityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sportType => $composableBuilder(
    column: $table.sportType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTimeUtc => $composableBuilder(
    column: $table.startTimeUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get utcOffsetSeconds => $composableBuilder(
    column: $table.utcOffsetSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationTotalSec => $composableBuilder(
    column: $table.durationTotalSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMovingSec => $composableBuilder(
    column: $table.durationMovingSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgPaceSecPerKm => $composableBuilder(
    column: $table.avgPaceSecPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgCadence => $composableBuilder(
    column: $table.avgCadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalElevationGainM => $composableBuilder(
    column: $table.totalElevationGainM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalElevationLossM => $composableBuilder(
    column: $table.totalElevationLossM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isIndoor => $composableBuilder(
    column: $table.isIndoor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasGpsTrack => $composableBuilder(
    column: $table.hasGpsTrack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gpsQuality => $composableBuilder(
    column: $table.gpsQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFitPath => $composableBuilder(
    column: $table.originalFitPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fitFileHash => $composableBuilder(
    column: $table.fitFileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int>, List<int>, String>
  get splitPacesSecPerKm => $composableBuilder(
    column: $table.splitPacesSecPerKm,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int>, List<int>, String>
  get zoneDurationsSec => $composableBuilder(
    column: $table.zoneDurationsSec,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get hasCustomTitle => $composableBuilder(
    column: $table.hasCustomTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> trackPointsRefs(
    Expression<bool> Function($$TrackPointsTableFilterComposer f) f,
  ) {
    final $$TrackPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableFilterComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lapSplitsRefs(
    Expression<bool> Function($$LapSplitsTableFilterComposer f) f,
  ) {
    final $$LapSplitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lapSplits,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapSplitsTableFilterComposer(
            $db: $db,
            $table: $db.lapSplits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> activityBestEffortsRefs(
    Expression<bool> Function($$ActivityBestEffortsTableFilterComposer f) f,
  ) {
    final $$ActivityBestEffortsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activityBestEfforts,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivityBestEffortsTableFilterComposer(
            $db: $db,
            $table: $db.activityBestEfforts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get garminActivityId => $composableBuilder(
    column: $table.garminActivityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sportType => $composableBuilder(
    column: $table.sportType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTimeUtc => $composableBuilder(
    column: $table.startTimeUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get utcOffsetSeconds => $composableBuilder(
    column: $table.utcOffsetSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationTotalSec => $composableBuilder(
    column: $table.durationTotalSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMovingSec => $composableBuilder(
    column: $table.durationMovingSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgPaceSecPerKm => $composableBuilder(
    column: $table.avgPaceSecPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgCadence => $composableBuilder(
    column: $table.avgCadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalElevationGainM => $composableBuilder(
    column: $table.totalElevationGainM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalElevationLossM => $composableBuilder(
    column: $table.totalElevationLossM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIndoor => $composableBuilder(
    column: $table.isIndoor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasGpsTrack => $composableBuilder(
    column: $table.hasGpsTrack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gpsQuality => $composableBuilder(
    column: $table.gpsQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFitPath => $composableBuilder(
    column: $table.originalFitPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fitFileHash => $composableBuilder(
    column: $table.fitFileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitPacesSecPerKm => $composableBuilder(
    column: $table.splitPacesSecPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneDurationsSec => $composableBuilder(
    column: $table.zoneDurationsSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasCustomTitle => $composableBuilder(
    column: $table.hasCustomTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get garminActivityId => $composableBuilder(
    column: $table.garminActivityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get sportType =>
      $composableBuilder(column: $table.sportType, builder: (column) => column);

  GeneratedColumn<DateTime> get startTimeUtc => $composableBuilder(
    column: $table.startTimeUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get utcOffsetSeconds => $composableBuilder(
    column: $table.utcOffsetSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationTotalSec => $composableBuilder(
    column: $table.durationTotalSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMovingSec => $composableBuilder(
    column: $table.durationMovingSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgPaceSecPerKm => $composableBuilder(
    column: $table.avgPaceSecPerKm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgCadence => $composableBuilder(
    column: $table.avgCadence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalElevationGainM => $composableBuilder(
    column: $table.totalElevationGainM,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalElevationLossM => $composableBuilder(
    column: $table.totalElevationLossM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isIndoor =>
      $composableBuilder(column: $table.isIndoor, builder: (column) => column);

  GeneratedColumn<bool> get hasGpsTrack => $composableBuilder(
    column: $table.hasGpsTrack,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gpsQuality => $composableBuilder(
    column: $table.gpsQuality,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalFitPath => $composableBuilder(
    column: $table.originalFitPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fitFileHash => $composableBuilder(
    column: $table.fitFileHash,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<int>, String> get splitPacesSecPerKm =>
      $composableBuilder(
        column: $table.splitPacesSecPerKm,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<int>, String> get zoneDurationsSec =>
      $composableBuilder(
        column: $table.zoneDurationsSec,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get hasCustomTitle => $composableBuilder(
    column: $table.hasCustomTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> trackPointsRefs<T extends Object>(
    Expression<T> Function($$TrackPointsTableAnnotationComposer a) f,
  ) {
    final $$TrackPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lapSplitsRefs<T extends Object>(
    Expression<T> Function($$LapSplitsTableAnnotationComposer a) f,
  ) {
    final $$LapSplitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lapSplits,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapSplitsTableAnnotationComposer(
            $db: $db,
            $table: $db.lapSplits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> activityBestEffortsRefs<T extends Object>(
    Expression<T> Function($$ActivityBestEffortsTableAnnotationComposer a) f,
  ) {
    final $$ActivityBestEffortsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.activityBestEfforts,
          getReferencedColumn: (t) => t.activityId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ActivityBestEffortsTableAnnotationComposer(
                $db: $db,
                $table: $db.activityBestEfforts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivitiesTable,
          ActivityRecord,
          $$ActivitiesTableFilterComposer,
          $$ActivitiesTableOrderingComposer,
          $$ActivitiesTableAnnotationComposer,
          $$ActivitiesTableCreateCompanionBuilder,
          $$ActivitiesTableUpdateCompanionBuilder,
          (ActivityRecord, $$ActivitiesTableReferences),
          ActivityRecord,
          PrefetchHooks Function({
            bool trackPointsRefs,
            bool lapSplitsRefs,
            bool activityBestEffortsRefs,
          })
        > {
  $$ActivitiesTableTableManager(_$AppDatabase db, $ActivitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> garminActivityId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> sportType = const Value.absent(),
                Value<DateTime> startTimeUtc = const Value.absent(),
                Value<int> utcOffsetSeconds = const Value.absent(),
                Value<int> durationTotalSec = const Value.absent(),
                Value<int> durationMovingSec = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<double> avgPaceSecPerKm = const Value.absent(),
                Value<double?> avgHeartRate = const Value.absent(),
                Value<double?> maxHeartRate = const Value.absent(),
                Value<double?> avgCadence = const Value.absent(),
                Value<double> totalElevationGainM = const Value.absent(),
                Value<double> totalElevationLossM = const Value.absent(),
                Value<int> caloriesKcal = const Value.absent(),
                Value<bool> isIndoor = const Value.absent(),
                Value<bool> hasGpsTrack = const Value.absent(),
                Value<String> gpsQuality = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> originalFitPath = const Value.absent(),
                Value<String> fitFileHash = const Value.absent(),
                Value<List<int>> splitPacesSecPerKm = const Value.absent(),
                Value<List<int>> zoneDurationsSec = const Value.absent(),
                Value<bool> hasCustomTitle = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ActivitiesCompanion(
                id: id,
                garminActivityId: garminActivityId,
                title: title,
                sportType: sportType,
                startTimeUtc: startTimeUtc,
                utcOffsetSeconds: utcOffsetSeconds,
                durationTotalSec: durationTotalSec,
                durationMovingSec: durationMovingSec,
                distanceMeters: distanceMeters,
                avgPaceSecPerKm: avgPaceSecPerKm,
                avgHeartRate: avgHeartRate,
                maxHeartRate: maxHeartRate,
                avgCadence: avgCadence,
                totalElevationGainM: totalElevationGainM,
                totalElevationLossM: totalElevationLossM,
                caloriesKcal: caloriesKcal,
                isIndoor: isIndoor,
                hasGpsTrack: hasGpsTrack,
                gpsQuality: gpsQuality,
                source: source,
                syncStatus: syncStatus,
                originalFitPath: originalFitPath,
                fitFileHash: fitFileHash,
                splitPacesSecPerKm: splitPacesSecPerKm,
                zoneDurationsSec: zoneDurationsSec,
                hasCustomTitle: hasCustomTitle,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> garminActivityId = const Value.absent(),
                required String title,
                required int sportType,
                required DateTime startTimeUtc,
                required int utcOffsetSeconds,
                required int durationTotalSec,
                required int durationMovingSec,
                required double distanceMeters,
                required double avgPaceSecPerKm,
                Value<double?> avgHeartRate = const Value.absent(),
                Value<double?> maxHeartRate = const Value.absent(),
                Value<double?> avgCadence = const Value.absent(),
                required double totalElevationGainM,
                required double totalElevationLossM,
                required int caloriesKcal,
                Value<bool> isIndoor = const Value.absent(),
                Value<bool> hasGpsTrack = const Value.absent(),
                Value<String> gpsQuality = const Value.absent(),
                required String source,
                required String syncStatus,
                Value<String?> originalFitPath = const Value.absent(),
                required String fitFileHash,
                required List<int> splitPacesSecPerKm,
                required List<int> zoneDurationsSec,
                Value<bool> hasCustomTitle = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ActivitiesCompanion.insert(
                id: id,
                garminActivityId: garminActivityId,
                title: title,
                sportType: sportType,
                startTimeUtc: startTimeUtc,
                utcOffsetSeconds: utcOffsetSeconds,
                durationTotalSec: durationTotalSec,
                durationMovingSec: durationMovingSec,
                distanceMeters: distanceMeters,
                avgPaceSecPerKm: avgPaceSecPerKm,
                avgHeartRate: avgHeartRate,
                maxHeartRate: maxHeartRate,
                avgCadence: avgCadence,
                totalElevationGainM: totalElevationGainM,
                totalElevationLossM: totalElevationLossM,
                caloriesKcal: caloriesKcal,
                isIndoor: isIndoor,
                hasGpsTrack: hasGpsTrack,
                gpsQuality: gpsQuality,
                source: source,
                syncStatus: syncStatus,
                originalFitPath: originalFitPath,
                fitFileHash: fitFileHash,
                splitPacesSecPerKm: splitPacesSecPerKm,
                zoneDurationsSec: zoneDurationsSec,
                hasCustomTitle: hasCustomTitle,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivitiesTable, ActivityRecord>(table),
                  $$ActivitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                trackPointsRefs = false,
                lapSplitsRefs = false,
                activityBestEffortsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (trackPointsRefs) db.trackPoints,
                    if (lapSplitsRefs) db.lapSplits,
                    if (activityBestEffortsRefs) db.activityBestEfforts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (trackPointsRefs)
                        await $_getPrefetchedDataByColumns<
                          ActivityRecord,
                          $ActivitiesTable,
                          TrackPointRecord,
                          $TrackPointsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ActivitiesTableReferences
                              ._trackPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ActivitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).trackPointsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'activity_id',
                          typedResults: items,
                        ),
                      if (lapSplitsRefs)
                        await $_getPrefetchedDataByColumns<
                          ActivityRecord,
                          $ActivitiesTable,
                          LapSplitRecord,
                          $LapSplitsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ActivitiesTableReferences
                              ._lapSplitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ActivitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).lapSplitsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'activity_id',
                          typedResults: items,
                        ),
                      if (activityBestEffortsRefs)
                        await $_getPrefetchedDataByColumns<
                          ActivityRecord,
                          $ActivitiesTable,
                          BestEffortRecord,
                          $ActivityBestEffortsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ActivitiesTableReferences
                              ._activityBestEffortsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ActivitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).activityBestEffortsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'activity_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivitiesTable,
      ActivityRecord,
      $$ActivitiesTableFilterComposer,
      $$ActivitiesTableOrderingComposer,
      $$ActivitiesTableAnnotationComposer,
      $$ActivitiesTableCreateCompanionBuilder,
      $$ActivitiesTableUpdateCompanionBuilder,
      (ActivityRecord, $$ActivitiesTableReferences),
      ActivityRecord,
      PrefetchHooks Function({
        bool trackPointsRefs,
        bool lapSplitsRefs,
        bool activityBestEffortsRefs,
      })
    >;
typedef $$TrackPointsTableCreateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> id,
      required int activityId,
      required DateTime timestampUtc,
      required double latitudeDeg,
      required double longitudeDeg,
      required double altitudeM,
      required double speedMps,
      Value<int?> heartRateBpm,
      Value<int?> cadenceRpm,
      required int distanceMeters,
      Value<int?> hrZone,
    });
typedef $$TrackPointsTableUpdateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> id,
      Value<int> activityId,
      Value<DateTime> timestampUtc,
      Value<double> latitudeDeg,
      Value<double> longitudeDeg,
      Value<double> altitudeM,
      Value<double> speedMps,
      Value<int?> heartRateBpm,
      Value<int?> cadenceRpm,
      Value<int> distanceMeters,
      Value<int?> hrZone,
    });

final class $$TrackPointsTableReferences
    extends BaseReferences<_$AppDatabase, $TrackPointsTable, TrackPointRecord> {
  $$TrackPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ActivitiesTable _activityIdTable(_$AppDatabase db) =>
      db.activities.createAlias('track_points__activity_id__activities__id');

  $$ActivitiesTableProcessedTableManager get activityId {
    final $_column = $_itemColumn<int>('activity_id')!;

    final manager = $$ActivitiesTableTableManager(
      $_db,
      $_db.activities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackPointsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestampUtc => $composableBuilder(
    column: $table.timestampUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitudeDeg => $composableBuilder(
    column: $table.latitudeDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitudeDeg => $composableBuilder(
    column: $table.longitudeDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cadenceRpm => $composableBuilder(
    column: $table.cadenceRpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrZone => $composableBuilder(
    column: $table.hrZone,
    builder: (column) => ColumnFilters(column),
  );

  $$ActivitiesTableFilterComposer get activityId {
    final $$ActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestampUtc => $composableBuilder(
    column: $table.timestampUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitudeDeg => $composableBuilder(
    column: $table.latitudeDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitudeDeg => $composableBuilder(
    column: $table.longitudeDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cadenceRpm => $composableBuilder(
    column: $table.cadenceRpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrZone => $composableBuilder(
    column: $table.hrZone,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActivitiesTableOrderingComposer get activityId {
    final $$ActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestampUtc => $composableBuilder(
    column: $table.timestampUtc,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitudeDeg => $composableBuilder(
    column: $table.latitudeDeg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get longitudeDeg => $composableBuilder(
    column: $table.longitudeDeg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get altitudeM =>
      $composableBuilder(column: $table.altitudeM, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<int> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cadenceRpm => $composableBuilder(
    column: $table.cadenceRpm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hrZone =>
      $composableBuilder(column: $table.hrZone, builder: (column) => column);

  $$ActivitiesTableAnnotationComposer get activityId {
    final $$ActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackPointsTable,
          TrackPointRecord,
          $$TrackPointsTableFilterComposer,
          $$TrackPointsTableOrderingComposer,
          $$TrackPointsTableAnnotationComposer,
          $$TrackPointsTableCreateCompanionBuilder,
          $$TrackPointsTableUpdateCompanionBuilder,
          (TrackPointRecord, $$TrackPointsTableReferences),
          TrackPointRecord,
          PrefetchHooks Function({bool activityId})
        > {
  $$TrackPointsTableTableManager(_$AppDatabase db, $TrackPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> activityId = const Value.absent(),
                Value<DateTime> timestampUtc = const Value.absent(),
                Value<double> latitudeDeg = const Value.absent(),
                Value<double> longitudeDeg = const Value.absent(),
                Value<double> altitudeM = const Value.absent(),
                Value<double> speedMps = const Value.absent(),
                Value<int?> heartRateBpm = const Value.absent(),
                Value<int?> cadenceRpm = const Value.absent(),
                Value<int> distanceMeters = const Value.absent(),
                Value<int?> hrZone = const Value.absent(),
              }) => TrackPointsCompanion(
                id: id,
                activityId: activityId,
                timestampUtc: timestampUtc,
                latitudeDeg: latitudeDeg,
                longitudeDeg: longitudeDeg,
                altitudeM: altitudeM,
                speedMps: speedMps,
                heartRateBpm: heartRateBpm,
                cadenceRpm: cadenceRpm,
                distanceMeters: distanceMeters,
                hrZone: hrZone,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int activityId,
                required DateTime timestampUtc,
                required double latitudeDeg,
                required double longitudeDeg,
                required double altitudeM,
                required double speedMps,
                Value<int?> heartRateBpm = const Value.absent(),
                Value<int?> cadenceRpm = const Value.absent(),
                required int distanceMeters,
                Value<int?> hrZone = const Value.absent(),
              }) => TrackPointsCompanion.insert(
                id: id,
                activityId: activityId,
                timestampUtc: timestampUtc,
                latitudeDeg: latitudeDeg,
                longitudeDeg: longitudeDeg,
                altitudeM: altitudeM,
                speedMps: speedMps,
                heartRateBpm: heartRateBpm,
                cadenceRpm: cadenceRpm,
                distanceMeters: distanceMeters,
                hrZone: hrZone,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackPointsTable, TrackPointRecord>(table),
                  $$TrackPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (activityId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.activityId,
                        referencedTable: $$TrackPointsTableReferences
                            ._activityIdTable(db),
                        referencedColumn: $$TrackPointsTableReferences
                            ._activityIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackPointsTable,
      TrackPointRecord,
      $$TrackPointsTableFilterComposer,
      $$TrackPointsTableOrderingComposer,
      $$TrackPointsTableAnnotationComposer,
      $$TrackPointsTableCreateCompanionBuilder,
      $$TrackPointsTableUpdateCompanionBuilder,
      (TrackPointRecord, $$TrackPointsTableReferences),
      TrackPointRecord,
      PrefetchHooks Function({bool activityId})
    >;
typedef $$LapSplitsTableCreateCompanionBuilder = LapSplitsCompanion Function({
  Value<int> id,
  required int activityId,
  required int splitIndex,
  required double distanceMeters,
  required int durationSec,
  required double avgPaceSecPerKm,
  Value<double?> avgHeartRate,
  Value<double?> avgCadence,
  required double elevationDeltaM,
});
typedef $$LapSplitsTableUpdateCompanionBuilder = LapSplitsCompanion Function({
  Value<int> id,
  Value<int> activityId,
  Value<int> splitIndex,
  Value<double> distanceMeters,
  Value<int> durationSec,
  Value<double> avgPaceSecPerKm,
  Value<double?> avgHeartRate,
  Value<double?> avgCadence,
  Value<double> elevationDeltaM,
});

final class $$LapSplitsTableReferences
    extends BaseReferences<_$AppDatabase, $LapSplitsTable, LapSplitRecord> {
  $$LapSplitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ActivitiesTable _activityIdTable(_$AppDatabase db) =>
      db.activities.createAlias('lap_splits__activity_id__activities__id');

  $$ActivitiesTableProcessedTableManager get activityId {
    final $_column = $_itemColumn<int>('activity_id')!;

    final manager = $$ActivitiesTableTableManager(
      $_db,
      $_db.activities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LapSplitsTableFilterComposer
    extends Composer<_$AppDatabase, $LapSplitsTable> {
  $$LapSplitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get splitIndex => $composableBuilder(
    column: $table.splitIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgPaceSecPerKm => $composableBuilder(
    column: $table.avgPaceSecPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgCadence => $composableBuilder(
    column: $table.avgCadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationDeltaM => $composableBuilder(
    column: $table.elevationDeltaM,
    builder: (column) => ColumnFilters(column),
  );

  $$ActivitiesTableFilterComposer get activityId {
    final $$ActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapSplitsTableOrderingComposer
    extends Composer<_$AppDatabase, $LapSplitsTable> {
  $$LapSplitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get splitIndex => $composableBuilder(
    column: $table.splitIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgPaceSecPerKm => $composableBuilder(
    column: $table.avgPaceSecPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgCadence => $composableBuilder(
    column: $table.avgCadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationDeltaM => $composableBuilder(
    column: $table.elevationDeltaM,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActivitiesTableOrderingComposer get activityId {
    final $$ActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapSplitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LapSplitsTable> {
  $$LapSplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get splitIndex => $composableBuilder(
    column: $table.splitIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgPaceSecPerKm => $composableBuilder(
    column: $table.avgPaceSecPerKm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgHeartRate => $composableBuilder(
    column: $table.avgHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgCadence => $composableBuilder(
    column: $table.avgCadence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get elevationDeltaM => $composableBuilder(
    column: $table.elevationDeltaM,
    builder: (column) => column,
  );

  $$ActivitiesTableAnnotationComposer get activityId {
    final $$ActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LapSplitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LapSplitsTable,
          LapSplitRecord,
          $$LapSplitsTableFilterComposer,
          $$LapSplitsTableOrderingComposer,
          $$LapSplitsTableAnnotationComposer,
          $$LapSplitsTableCreateCompanionBuilder,
          $$LapSplitsTableUpdateCompanionBuilder,
          (LapSplitRecord, $$LapSplitsTableReferences),
          LapSplitRecord,
          PrefetchHooks Function({bool activityId})
        > {
  $$LapSplitsTableTableManager(_$AppDatabase db, $LapSplitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LapSplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LapSplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LapSplitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> activityId = const Value.absent(),
                Value<int> splitIndex = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<double> avgPaceSecPerKm = const Value.absent(),
                Value<double?> avgHeartRate = const Value.absent(),
                Value<double?> avgCadence = const Value.absent(),
                Value<double> elevationDeltaM = const Value.absent(),
              }) => LapSplitsCompanion(
                id: id,
                activityId: activityId,
                splitIndex: splitIndex,
                distanceMeters: distanceMeters,
                durationSec: durationSec,
                avgPaceSecPerKm: avgPaceSecPerKm,
                avgHeartRate: avgHeartRate,
                avgCadence: avgCadence,
                elevationDeltaM: elevationDeltaM,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int activityId,
                required int splitIndex,
                required double distanceMeters,
                required int durationSec,
                required double avgPaceSecPerKm,
                Value<double?> avgHeartRate = const Value.absent(),
                Value<double?> avgCadence = const Value.absent(),
                required double elevationDeltaM,
              }) => LapSplitsCompanion.insert(
                id: id,
                activityId: activityId,
                splitIndex: splitIndex,
                distanceMeters: distanceMeters,
                durationSec: durationSec,
                avgPaceSecPerKm: avgPaceSecPerKm,
                avgHeartRate: avgHeartRate,
                avgCadence: avgCadence,
                elevationDeltaM: elevationDeltaM,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LapSplitsTable, LapSplitRecord>(table),
                  $$LapSplitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (activityId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.activityId,
                        referencedTable: $$LapSplitsTableReferences
                            ._activityIdTable(db),
                        referencedColumn: $$LapSplitsTableReferences
                            ._activityIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LapSplitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LapSplitsTable,
      LapSplitRecord,
      $$LapSplitsTableFilterComposer,
      $$LapSplitsTableOrderingComposer,
      $$LapSplitsTableAnnotationComposer,
      $$LapSplitsTableCreateCompanionBuilder,
      $$LapSplitsTableUpdateCompanionBuilder,
      (LapSplitRecord, $$LapSplitsTableReferences),
      LapSplitRecord,
      PrefetchHooks Function({bool activityId})
    >;
typedef $$UserPreferencesTableTableCreateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      Value<int> id,
      Value<bool> garminLoggedIn,
      Value<DateTime?> lastSyncAt,
      Value<DateTime?> lastActivityStartTime,
      Value<DateTime?> birthDate,
      Value<int?> hrMaxManual,
      Value<List<int>> hrZoneThresholds,
      Value<String> themeMode,
      Value<String> unitSystem,
      Value<String> weeklyMonthlyToggle,
      Value<bool> watermarkEnabled,
      Value<String> defaultTemplateId,
      Value<bool> backgroundSyncEnabled,
      Value<bool> backgroundSyncWifiOnly,
      Value<bool> backgroundSyncRequireCharging,
      Value<int> backgroundSyncIntervalMinutes,
      Value<bool> onboardingCompleted,
      Value<DateTime?> lastBackupAt,
      Value<bool> backupReminderEnabled,
      Value<DateTime?> lastBackupReminderAt,
    });
typedef $$UserPreferencesTableTableUpdateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      Value<int> id,
      Value<bool> garminLoggedIn,
      Value<DateTime?> lastSyncAt,
      Value<DateTime?> lastActivityStartTime,
      Value<DateTime?> birthDate,
      Value<int?> hrMaxManual,
      Value<List<int>> hrZoneThresholds,
      Value<String> themeMode,
      Value<String> unitSystem,
      Value<String> weeklyMonthlyToggle,
      Value<bool> watermarkEnabled,
      Value<String> defaultTemplateId,
      Value<bool> backgroundSyncEnabled,
      Value<bool> backgroundSyncWifiOnly,
      Value<bool> backgroundSyncRequireCharging,
      Value<int> backgroundSyncIntervalMinutes,
      Value<bool> onboardingCompleted,
      Value<DateTime?> lastBackupAt,
      Value<bool> backupReminderEnabled,
      Value<DateTime?> lastBackupReminderAt,
    });

class $$UserPreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get garminLoggedIn => $composableBuilder(
    column: $table.garminLoggedIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastActivityStartTime => $composableBuilder(
    column: $table.lastActivityStartTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrMaxManual => $composableBuilder(
    column: $table.hrMaxManual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int>, List<int>, String>
  get hrZoneThresholds => $composableBuilder(
    column: $table.hrZoneThresholds,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitSystem => $composableBuilder(
    column: $table.unitSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weeklyMonthlyToggle => $composableBuilder(
    column: $table.weeklyMonthlyToggle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get watermarkEnabled => $composableBuilder(
    column: $table.watermarkEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultTemplateId => $composableBuilder(
    column: $table.defaultTemplateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get backgroundSyncEnabled => $composableBuilder(
    column: $table.backgroundSyncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get backgroundSyncWifiOnly => $composableBuilder(
    column: $table.backgroundSyncWifiOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get backgroundSyncRequireCharging => $composableBuilder(
    column: $table.backgroundSyncRequireCharging,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get backgroundSyncIntervalMinutes => $composableBuilder(
    column: $table.backgroundSyncIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get backupReminderEnabled => $composableBuilder(
    column: $table.backupReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastBackupReminderAt => $composableBuilder(
    column: $table.lastBackupReminderAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserPreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get garminLoggedIn => $composableBuilder(
    column: $table.garminLoggedIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastActivityStartTime => $composableBuilder(
    column: $table.lastActivityStartTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrMaxManual => $composableBuilder(
    column: $table.hrMaxManual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hrZoneThresholds => $composableBuilder(
    column: $table.hrZoneThresholds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitSystem => $composableBuilder(
    column: $table.unitSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weeklyMonthlyToggle => $composableBuilder(
    column: $table.weeklyMonthlyToggle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get watermarkEnabled => $composableBuilder(
    column: $table.watermarkEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultTemplateId => $composableBuilder(
    column: $table.defaultTemplateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get backgroundSyncEnabled => $composableBuilder(
    column: $table.backgroundSyncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get backgroundSyncWifiOnly => $composableBuilder(
    column: $table.backgroundSyncWifiOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get backgroundSyncRequireCharging => $composableBuilder(
    column: $table.backgroundSyncRequireCharging,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get backgroundSyncIntervalMinutes => $composableBuilder(
    column: $table.backgroundSyncIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get backupReminderEnabled => $composableBuilder(
    column: $table.backupReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastBackupReminderAt => $composableBuilder(
    column: $table.lastBackupReminderAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get garminLoggedIn => $composableBuilder(
    column: $table.garminLoggedIn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastActivityStartTime => $composableBuilder(
    column: $table.lastActivityStartTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<int> get hrMaxManual => $composableBuilder(
    column: $table.hrMaxManual,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<int>, String> get hrZoneThresholds =>
      $composableBuilder(
        column: $table.hrZoneThresholds,
        builder: (column) => column,
      );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get unitSystem => $composableBuilder(
    column: $table.unitSystem,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weeklyMonthlyToggle => $composableBuilder(
    column: $table.weeklyMonthlyToggle,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get watermarkEnabled => $composableBuilder(
    column: $table.watermarkEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultTemplateId => $composableBuilder(
    column: $table.defaultTemplateId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get backgroundSyncEnabled => $composableBuilder(
    column: $table.backgroundSyncEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get backgroundSyncWifiOnly => $composableBuilder(
    column: $table.backgroundSyncWifiOnly,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get backgroundSyncRequireCharging => $composableBuilder(
    column: $table.backgroundSyncRequireCharging,
    builder: (column) => column,
  );

  GeneratedColumn<int> get backgroundSyncIntervalMinutes => $composableBuilder(
    column: $table.backgroundSyncIntervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get backupReminderEnabled => $composableBuilder(
    column: $table.backupReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastBackupReminderAt => $composableBuilder(
    column: $table.lastBackupReminderAt,
    builder: (column) => column,
  );
}

class $$UserPreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPreferencesTableTable,
          UserPreference,
          $$UserPreferencesTableTableFilterComposer,
          $$UserPreferencesTableTableOrderingComposer,
          $$UserPreferencesTableTableAnnotationComposer,
          $$UserPreferencesTableTableCreateCompanionBuilder,
          $$UserPreferencesTableTableUpdateCompanionBuilder,
          (
            UserPreference,
            BaseReferences<
              _$AppDatabase,
              $UserPreferencesTableTable,
              UserPreference
            >,
          ),
          UserPreference,
          PrefetchHooks Function()
        > {
  $$UserPreferencesTableTableTableManager(
    _$AppDatabase db,
    $UserPreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> garminLoggedIn = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<DateTime?> lastActivityStartTime = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<int?> hrMaxManual = const Value.absent(),
                Value<List<int>> hrZoneThresholds = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> unitSystem = const Value.absent(),
                Value<String> weeklyMonthlyToggle = const Value.absent(),
                Value<bool> watermarkEnabled = const Value.absent(),
                Value<String> defaultTemplateId = const Value.absent(),
                Value<bool> backgroundSyncEnabled = const Value.absent(),
                Value<bool> backgroundSyncWifiOnly = const Value.absent(),
                Value<bool> backgroundSyncRequireCharging =
                    const Value.absent(),
                Value<int> backgroundSyncIntervalMinutes = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<DateTime?> lastBackupAt = const Value.absent(),
                Value<bool> backupReminderEnabled = const Value.absent(),
                Value<DateTime?> lastBackupReminderAt = const Value.absent(),
              }) => UserPreferencesTableCompanion(
                id: id,
                garminLoggedIn: garminLoggedIn,
                lastSyncAt: lastSyncAt,
                lastActivityStartTime: lastActivityStartTime,
                birthDate: birthDate,
                hrMaxManual: hrMaxManual,
                hrZoneThresholds: hrZoneThresholds,
                themeMode: themeMode,
                unitSystem: unitSystem,
                weeklyMonthlyToggle: weeklyMonthlyToggle,
                watermarkEnabled: watermarkEnabled,
                defaultTemplateId: defaultTemplateId,
                backgroundSyncEnabled: backgroundSyncEnabled,
                backgroundSyncWifiOnly: backgroundSyncWifiOnly,
                backgroundSyncRequireCharging: backgroundSyncRequireCharging,
                backgroundSyncIntervalMinutes: backgroundSyncIntervalMinutes,
                onboardingCompleted: onboardingCompleted,
                lastBackupAt: lastBackupAt,
                backupReminderEnabled: backupReminderEnabled,
                lastBackupReminderAt: lastBackupReminderAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> garminLoggedIn = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<DateTime?> lastActivityStartTime = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<int?> hrMaxManual = const Value.absent(),
                Value<List<int>> hrZoneThresholds = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> unitSystem = const Value.absent(),
                Value<String> weeklyMonthlyToggle = const Value.absent(),
                Value<bool> watermarkEnabled = const Value.absent(),
                Value<String> defaultTemplateId = const Value.absent(),
                Value<bool> backgroundSyncEnabled = const Value.absent(),
                Value<bool> backgroundSyncWifiOnly = const Value.absent(),
                Value<bool> backgroundSyncRequireCharging =
                    const Value.absent(),
                Value<int> backgroundSyncIntervalMinutes = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<DateTime?> lastBackupAt = const Value.absent(),
                Value<bool> backupReminderEnabled = const Value.absent(),
                Value<DateTime?> lastBackupReminderAt = const Value.absent(),
              }) => UserPreferencesTableCompanion.insert(
                id: id,
                garminLoggedIn: garminLoggedIn,
                lastSyncAt: lastSyncAt,
                lastActivityStartTime: lastActivityStartTime,
                birthDate: birthDate,
                hrMaxManual: hrMaxManual,
                hrZoneThresholds: hrZoneThresholds,
                themeMode: themeMode,
                unitSystem: unitSystem,
                weeklyMonthlyToggle: weeklyMonthlyToggle,
                watermarkEnabled: watermarkEnabled,
                defaultTemplateId: defaultTemplateId,
                backgroundSyncEnabled: backgroundSyncEnabled,
                backgroundSyncWifiOnly: backgroundSyncWifiOnly,
                backgroundSyncRequireCharging: backgroundSyncRequireCharging,
                backgroundSyncIntervalMinutes: backgroundSyncIntervalMinutes,
                onboardingCompleted: onboardingCompleted,
                lastBackupAt: lastBackupAt,
                backupReminderEnabled: backupReminderEnabled,
                lastBackupReminderAt: lastBackupReminderAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserPreferencesTableTable, UserPreference>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $UserPreferencesTableTable,
                    UserPreference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserPreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPreferencesTableTable,
      UserPreference,
      $$UserPreferencesTableTableFilterComposer,
      $$UserPreferencesTableTableOrderingComposer,
      $$UserPreferencesTableTableAnnotationComposer,
      $$UserPreferencesTableTableCreateCompanionBuilder,
      $$UserPreferencesTableTableUpdateCompanionBuilder,
      (
        UserPreference,
        BaseReferences<
          _$AppDatabase,
          $UserPreferencesTableTable,
          UserPreference
        >,
      ),
      UserPreference,
      PrefetchHooks Function()
    >;
typedef $$ActivityBestEffortsTableCreateCompanionBuilder =
    ActivityBestEffortsCompanion Function({
      Value<int> id,
      required int activityId,
      required String distanceKey,
      required double targetDistanceMeters,
      required int durationSec,
      required double paceSecPerKm,
    });
typedef $$ActivityBestEffortsTableUpdateCompanionBuilder =
    ActivityBestEffortsCompanion Function({
      Value<int> id,
      Value<int> activityId,
      Value<String> distanceKey,
      Value<double> targetDistanceMeters,
      Value<int> durationSec,
      Value<double> paceSecPerKm,
    });

final class $$ActivityBestEffortsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ActivityBestEffortsTable,
          BestEffortRecord
        > {
  $$ActivityBestEffortsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ActivitiesTable _activityIdTable(_$AppDatabase db) => db.activities
      .createAlias('activity_best_efforts__activity_id__activities__id');

  $$ActivitiesTableProcessedTableManager get activityId {
    final $_column = $_itemColumn<int>('activity_id')!;

    final manager = $$ActivitiesTableTableManager(
      $_db,
      $_db.activities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ActivityBestEffortsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityBestEffortsTable> {
  $$ActivityBestEffortsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distanceKey => $composableBuilder(
    column: $table.distanceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetDistanceMeters => $composableBuilder(
    column: $table.targetDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paceSecPerKm => $composableBuilder(
    column: $table.paceSecPerKm,
    builder: (column) => ColumnFilters(column),
  );

  $$ActivitiesTableFilterComposer get activityId {
    final $$ActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityBestEffortsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityBestEffortsTable> {
  $$ActivityBestEffortsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distanceKey => $composableBuilder(
    column: $table.distanceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetDistanceMeters => $composableBuilder(
    column: $table.targetDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paceSecPerKm => $composableBuilder(
    column: $table.paceSecPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActivitiesTableOrderingComposer get activityId {
    final $$ActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityBestEffortsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityBestEffortsTable> {
  $$ActivityBestEffortsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get distanceKey => $composableBuilder(
    column: $table.distanceKey,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetDistanceMeters => $composableBuilder(
    column: $table.targetDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paceSecPerKm => $composableBuilder(
    column: $table.paceSecPerKm,
    builder: (column) => column,
  );

  $$ActivitiesTableAnnotationComposer get activityId {
    final $$ActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivityBestEffortsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityBestEffortsTable,
          BestEffortRecord,
          $$ActivityBestEffortsTableFilterComposer,
          $$ActivityBestEffortsTableOrderingComposer,
          $$ActivityBestEffortsTableAnnotationComposer,
          $$ActivityBestEffortsTableCreateCompanionBuilder,
          $$ActivityBestEffortsTableUpdateCompanionBuilder,
          (BestEffortRecord, $$ActivityBestEffortsTableReferences),
          BestEffortRecord,
          PrefetchHooks Function({bool activityId})
        > {
  $$ActivityBestEffortsTableTableManager(
    _$AppDatabase db,
    $ActivityBestEffortsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityBestEffortsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityBestEffortsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ActivityBestEffortsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> activityId = const Value.absent(),
                Value<String> distanceKey = const Value.absent(),
                Value<double> targetDistanceMeters = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<double> paceSecPerKm = const Value.absent(),
              }) => ActivityBestEffortsCompanion(
                id: id,
                activityId: activityId,
                distanceKey: distanceKey,
                targetDistanceMeters: targetDistanceMeters,
                durationSec: durationSec,
                paceSecPerKm: paceSecPerKm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int activityId,
                required String distanceKey,
                required double targetDistanceMeters,
                required int durationSec,
                required double paceSecPerKm,
              }) => ActivityBestEffortsCompanion.insert(
                id: id,
                activityId: activityId,
                distanceKey: distanceKey,
                targetDistanceMeters: targetDistanceMeters,
                durationSec: durationSec,
                paceSecPerKm: paceSecPerKm,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivityBestEffortsTable, BestEffortRecord>(
                    table,
                  ),
                  $$ActivityBestEffortsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (activityId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.activityId,
                        referencedTable: $$ActivityBestEffortsTableReferences
                            ._activityIdTable(db),
                        referencedColumn: $$ActivityBestEffortsTableReferences
                            ._activityIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ActivityBestEffortsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityBestEffortsTable,
      BestEffortRecord,
      $$ActivityBestEffortsTableFilterComposer,
      $$ActivityBestEffortsTableOrderingComposer,
      $$ActivityBestEffortsTableAnnotationComposer,
      $$ActivityBestEffortsTableCreateCompanionBuilder,
      $$ActivityBestEffortsTableUpdateCompanionBuilder,
      (BestEffortRecord, $$ActivityBestEffortsTableReferences),
      BestEffortRecord,
      PrefetchHooks Function({bool activityId})
    >;
typedef $$StoryPresetsTableCreateCompanionBuilder =
    StoryPresetsCompanion Function({
      Value<int> id,
      required String name,
      required String configJson,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$StoryPresetsTableUpdateCompanionBuilder =
    StoryPresetsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> configJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$StoryPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $StoryPresetsTable> {
  $$StoryPresetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoryPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryPresetsTable> {
  $$StoryPresetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoryPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryPresetsTable> {
  $$StoryPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StoryPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoryPresetsTable,
          StoryPresetRecord,
          $$StoryPresetsTableFilterComposer,
          $$StoryPresetsTableOrderingComposer,
          $$StoryPresetsTableAnnotationComposer,
          $$StoryPresetsTableCreateCompanionBuilder,
          $$StoryPresetsTableUpdateCompanionBuilder,
          (
            StoryPresetRecord,
            BaseReferences<
              _$AppDatabase,
              $StoryPresetsTable,
              StoryPresetRecord
            >,
          ),
          StoryPresetRecord,
          PrefetchHooks Function()
        > {
  $$StoryPresetsTableTableManager(_$AppDatabase db, $StoryPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StoryPresetsCompanion(
                id: id,
                name: name,
                configJson: configJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String configJson,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => StoryPresetsCompanion.insert(
                id: id,
                name: name,
                configJson: configJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoryPresetsTable, StoryPresetRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StoryPresetsTable,
                    StoryPresetRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoryPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoryPresetsTable,
      StoryPresetRecord,
      $$StoryPresetsTableFilterComposer,
      $$StoryPresetsTableOrderingComposer,
      $$StoryPresetsTableAnnotationComposer,
      $$StoryPresetsTableCreateCompanionBuilder,
      $$StoryPresetsTableUpdateCompanionBuilder,
      (
        StoryPresetRecord,
        BaseReferences<_$AppDatabase, $StoryPresetsTable, StoryPresetRecord>,
      ),
      StoryPresetRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$TrackPointsTableTableManager get trackPoints =>
      $$TrackPointsTableTableManager(_db, _db.trackPoints);
  $$LapSplitsTableTableManager get lapSplits =>
      $$LapSplitsTableTableManager(_db, _db.lapSplits);
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(_db, _db.userPreferencesTable);
  $$ActivityBestEffortsTableTableManager get activityBestEfforts =>
      $$ActivityBestEffortsTableTableManager(_db, _db.activityBestEfforts);
  $$StoryPresetsTableTableManager get storyPresets =>
      $$StoryPresetsTableTableManager(_db, _db.storyPresets);
}
