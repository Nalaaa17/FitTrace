import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/unit_formatter.dart';
import '../../activity_detail/presentation/activity_detail_screen.dart';
import '../../feed/application/feed_providers.dart';
import '../../garmin_sync/application/garmin_sync_providers.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/stats_providers.dart';
import 'widgets/consistency_heatmap_card.dart';
import 'widgets/weekly_trend_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static String _periodHeroLabel(String period) {
    switch (period) {
      case 'monthly':
        return 'TOTAL JARAK BULAN INI';
      case 'yearly':
        return 'TOTAL JARAK TAHUN INI';
      case 'allTime':
        return 'TOTAL JARAK KESELURUHAN (ALL-TIME)';
      case 'weekly':
      default:
        return 'TOTAL JARAK MINGGU INI';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesProvider);
    final statsAsync = ref.watch(aggregateStatsProvider);
    final prsAsync = ref.watch(allTimeBestEffortsProvider);
    final vdotAsync = ref.watch(vdotEstimateProvider);
    final heatmapAsync = ref.watch(consistencyHeatmapProvider);
    final syncState = ref.watch(garminSyncControllerProvider);
    final colors = context.fitColors;
    final period = prefsAsync.value?.weeklyMonthlyToggle ?? 'weekly';
    final unitSystem = prefsAsync.value?.unitSystem ?? 'metric';
    final isGarminConnected = prefsAsync.value?.garminLoggedIn ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui Statistik',
            onPressed: () {
              ref.invalidate(aggregateStatsProvider);
              ref.invalidate(allTimeBestEffortsProvider);
              ref.invalidate(vdotEstimateProvider);
              ref.invalidate(consistencyHeatmapProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(aggregateStatsProvider);
          ref.invalidate(allTimeBestEffortsProvider);
          ref.invalidate(vdotEstimateProvider);
          ref.invalidate(consistencyHeatmapProvider);
          try {
            await ref.read(aggregateStatsProvider.future);
          } on Object catch (_) {}
        },
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
        children: <Widget>[
          _GarminSyncBanner(
            isConnected: isGarminConnected,
            syncState: syncState,
            colors: colors,
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: 'weekly',
                label: Text('Mingguan'),
              ),
              ButtonSegment<String>(
                value: 'monthly',
                label: Text('Bulanan'),
              ),
              ButtonSegment<String>(
                value: 'yearly',
                label: Text('Tahunan'),
              ),
              ButtonSegment<String>(
                value: 'allTime',
                label: Text('Semua'),
              ),
            ],
            selected: <String>{
              const <String>['weekly', 'monthly', 'yearly', 'allTime'].contains(period)
                  ? period
                  : 'weekly',
            },
            onSelectionChanged: (selection) {
              setWeeklyMonthlyMode(ref, selection.first);
            },
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Gagal menghitung statistik: $err'),
              ),
            ),
            data: (stats) {
              final dist = UnitFormatter.formatDistanceValue(
                stats.totalDistanceMeters,
                unitSystem,
              );
              final distUnit = UnitFormatter.distanceUnitLabel(
                unitSystem,
                upperCase: true,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _periodHeroLabel(period),
                            style: AppTypography.metricLabel(colors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: <Widget>[
                              Text(
                                dist,
                                style:
                                    AppTypography.heroDistance(colors.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                distUnit,
                                style: AppTypography.metricLabel(
                                  colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _SubStat(
                                  label: 'PACE RATA-RATA',
                                  value: UnitFormatter.formatPaceWithUnit(
                                    stats.avgPaceSecPerKm,
                                    unitSystem,
                                  ),
                                  colors: colors,
                                ),
                              ),
                              Expanded(
                                child: _SubStat(
                                  label: 'WAKTU BERGERAK',
                                  value: formatDuration(
                                    stats.totalMovingDurationSec,
                                  ),
                                  colors: colors,
                                ),
                              ),
                              Expanded(
                                child: _SubStat(
                                  label: 'AKTIVITAS',
                                  value: '${stats.activityCount} sesi',
                                  colors: colors,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _SubStat(
                                  label: 'LARI TERJAUH',
                                  value: stats.longestDistanceMeters > 0
                                      ? '${UnitFormatter.formatDistanceValue(stats.longestDistanceMeters, unitSystem)} $distUnit'
                                      : '—',
                                  colors: colors,
                                ),
                              ),
                              Expanded(
                                child: _SubStat(
                                  label: 'RATA-RATA / SESI',
                                  value: stats.avgDistanceMeters > 0
                                      ? '${UnitFormatter.formatDistanceValue(stats.avgDistanceMeters, unitSystem)} $distUnit'
                                      : '—',
                                  colors: colors,
                                ),
                              ),
                              Expanded(
                                child: _SubStat(
                                  label: 'LOKASI LARI',
                                  value: stats.activityCount > 0
                                      ? '${stats.outdoorRunsCount} Outdoor • ${stats.indoorRunsCount} Treadmill'
                                      : '—',
                                  colors: colors,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GarminCardioCard(
                    stats: stats,
                    colors: colors,
                  ),
                  const SizedBox(height: 16),
                  _GarminElevationCadenceCard(
                    stats: stats,
                    unitSystem: unitSystem,
                    colors: colors,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          WeeklyTrendCard(
            colors: colors,
            unitSystem: unitSystem,
          ),
          const SizedBox(height: 16),
          if (heatmapAsync.hasValue)
            ConsistencyHeatmapCard(
              data: heatmapAsync.value!,
              colors: colors,
            ),
          const SizedBox(height: 16),
          _PersonalRecordsCard(
            prsAsync: prsAsync,
            unitSystem: unitSystem,
            colors: colors,
          ),
          const SizedBox(height: 16),
          _VdotPredictorCard(
            vdotAsync: vdotAsync,
            unitSystem: unitSystem,
            colors: colors,
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
}

class _GarminSyncBanner extends ConsumerWidget {
  const _GarminSyncBanner({
    required this.isConnected,
    required this.syncState,
    required this.colors,
  });

  final bool isConnected;
  final GarminSyncState syncState;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = syncState.isSyncing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border.all(color: colors.hairlineBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFF81C784) : colors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isConnected ? 'Garmin Connect Resmi Aktif' : 'Garmin Belum Terhubung',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  isSyncing
                      ? (syncState.statusMessage ?? 'Sedang menyinkronkan aktivitas Garmin...')
                      : (isConnected
                          ? 'Data lari, cardio & elevasi sinkron via Personal API'
                          : 'Hubungkan API Key untuk mengambil semua data lari Garmin'),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isConnected)
            IconButton(
              icon: isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 20),
              tooltip: 'Sinkronkan Sekarang',
              onPressed: isSyncing
                  ? null
                  : () {
                      ref.read(garminSyncControllerProvider.notifier).syncNow();
                    },
            )
          else
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                );
              },
              child: const Text('Hubungkan', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _GarminCardioCard extends StatelessWidget {
  const _GarminCardioCard({
    required this.stats,
    required this.colors,
  });

  final ActivityAggregateStats stats;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final zones = stats.zoneDurationsSec;
    final totalZoneSec = zones.fold<int>(0, (a, b) => a + b);
    final hasHrData = stats.avgHeartRate != null || totalZoneSec > 0;

    const zoneShades = <Color>[
      Color(0xFF64B5F6), // Z1: Blue (Recovery)
      Color(0xFF81C784), // Z2: Green (Aerobic Base)
      Color(0xFFFFD54F), // Z3: Amber (Tempo)
      Color(0xFFFF8A65), // Z4: Orange (Threshold)
      Color(0xFFE57373), // Z5: Crimson (Max)
    ];

    const zoneLabels = <String>[
      'Z1 Pemulihan (<60% HR)',
      'Z2 Aerobik Santai / Base (60–70% HR)',
      'Z3 Tempo / Aerobik Sedang (70–80% HR)',
      'Z4 Ambang Laktat / Threshold (80–90% HR)',
      'Z5 Anaerobik / Maksimal (>90% HR)',
    ];

    var dominantZone = 1;
    var maxZoneSec = 0;
    for (var i = 0; i < 5 && i < zones.length; i++) {
      if (zones[i] > maxZoneSec) {
        maxZoneSec = zones[i];
        dominantZone = i;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.favorite, size: 18, color: Color(0xFFE57373)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GARMIN CARDIO & ZONA DETAK JANTUNG',
                    style: AppTypography.metricLabel(colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _SubStat(
                    label: 'HR RATA-RATA',
                    value: stats.avgHeartRate != null
                        ? '${stats.avgHeartRate!.round()} BPM'
                        : '—',
                    colors: colors,
                  ),
                ),
                Expanded(
                  child: _SubStat(
                    label: 'HR MAKSIMAL',
                    value: stats.maxHeartRate != null
                        ? '${stats.maxHeartRate!.round()} BPM'
                        : '—',
                    colors: colors,
                  ),
                ),
                Expanded(
                  child: _SubStat(
                    label: 'TOTAL KALORI',
                    value: stats.totalCaloriesKcal > 0
                        ? '${stats.totalCaloriesKcal} kcal'
                        : '—',
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (!hasHrData)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Data detak jantung akan otomatis muncul setelah sinkronisasi aktivitas dari Garmin.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              )
            else ...<Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'DISTRIBUSI WAKTU DI ZONA (Z1 - Z5)',
                    style: AppTypography.chartAxis(colors.textSecondary),
                  ),
                  if (totalZoneSec > 0 && dominantZone == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C784).withValues(alpha: 0.15),
                        border: Border.all(color: const Color(0xFF81C784)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '✨ Base Dominan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF81C784),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: List<Widget>.generate(5, (i) {
                      final sec = i < zones.length ? zones[i] : 0;
                      if (sec <= 0) return const SizedBox.shrink();
                      return Expanded(
                        flex: sec,
                        child: Container(color: zoneShades[i]),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < 5 && i < zones.length; i++) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: zoneShades[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          zoneLabels[i],
                          style: AppTypography.chartAxis(colors.textSecondary),
                        ),
                      ),
                      Text(
                        formatDuration(zones[i]),
                        style: AppTypography.splitTable(colors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          totalZoneSec > 0
                              ? '${((zones[i] / totalZoneSec) * 100).round()}%'
                              : '0%',
                          textAlign: TextAlign.right,
                          style: AppTypography.chartAxis(colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _GarminElevationCadenceCard extends StatelessWidget {
  const _GarminElevationCadenceCard({
    required this.stats,
    required this.unitSystem,
    required this.colors,
  });

  final ActivityAggregateStats stats;
  final String unitSystem;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final cad = stats.avgCadence;
    String cadStatus;
    Color cadColor;
    if (cad == null || cad <= 0) {
      cadStatus = '—';
      cadColor = colors.textSecondary;
    } else if (cad >= 170) {
      cadStatus = 'Optimal (Efisiensi Tinggi)';
      cadColor = const Color(0xFF81C784);
    } else if (cad >= 155) {
      cadStatus = 'Baik (Standar)';
      cadColor = const Color(0xFFFFD54F);
    } else {
      cadStatus = 'Santai';
      cadColor = colors.textSecondary;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.terrain, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ELEVASI & KADENSI LANGKAH GARMIN',
                    style: AppTypography.metricLabel(colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _SubStat(
                    label: 'TOTAL MENDAKI (D+)',
                    value: UnitFormatter.formatElevation(
                      stats.totalElevationGainM,
                      unitSystem,
                      signed: true,
                    ),
                    colors: colors,
                  ),
                ),
                Expanded(
                  child: _SubStat(
                    label: 'TOTAL MENURUN (D-)',
                    value: UnitFormatter.formatElevation(
                      -stats.totalElevationLossM,
                      unitSystem,
                      signed: true,
                    ),
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'RATA-RATA KADENSI',
                        style: AppTypography.metricLabel(colors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Text(
                            cad != null ? '${cad.round()} SPM' : '—',
                            style: AppTypography.splitTable(colors.textPrimary),
                          ),
                          if (cad != null && cad > 0) ...<Widget>[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cadColor.withValues(alpha: 0.15),
                                border: Border.all(color: cadColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cadStatus,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: cadColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _SubStat(
                    label: 'RATA-RATA ELEVASI / LARI',
                    value: stats.activityCount > 0
                        ? UnitFormatter.formatElevation(
                            stats.totalElevationGainM / stats.activityCount,
                            unitSystem,
                          )
                        : '—',
                    colors: colors,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalRecordsCard extends StatelessWidget {
  const _PersonalRecordsCard({
    required this.prsAsync,
    required this.unitSystem,
    required this.colors,
  });

  final AsyncValue<Map<String, BestEffortPrRecord>> prsAsync;
  final String unitSystem;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final prs = prsAsync.value ?? const <String, BestEffortPrRecord>{};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'BEST EFFORT PR',
              style: AppTypography.metricLabel(colors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (prs.isEmpty)
              Text(
                'Belum ada PR 5K / 10K / Half Marathon / Marathon. Catat minimal 5 km untuk mendeteksi segmen tercepat.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              for (final dist in BestEffortDistance.values)
                _PrRow(
                  distance: dist,
                  record: prs[dist.storageKey],
                  unitSystem: unitSystem,
                  colors: colors,
                ),
          ],
        ),
      ),
    );
  }
}

class _PrRow extends StatelessWidget {
  const _PrRow({
    required this.distance,
    required this.record,
    required this.unitSystem,
    required this.colors,
  });

  final BestEffortDistance distance;
  final BestEffortPrRecord? record;
  final String unitSystem;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final r = record;
    return InkWell(
      onTap: r == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ActivityDetailScreen(activityId: r.activityId),
                ),
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: r != null ? colors.accentSharp : colors.hairlineBorder,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                distance == BestEffortDistance.halfMarathon
                    ? 'HM'
                    : distance == BestEffortDistance.marathon
                        ? 'FM'
                        : distance.label,
                textAlign: TextAlign.center,
                style: AppTypography.chartAxis(
                  r != null ? colors.accentSharp : colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    r != null ? formatDuration(r.durationSec) : '—',
                    style: AppTypography.splitTable(colors.textPrimary),
                  ),
                  if (r != null)
                    Text(
                      '${r.activityTitle} • ${UnitFormatter.formatPaceWithUnit(r.paceSecPerKm, unitSystem)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.chartAxis(colors.textSecondary),
                    ),
                ],
              ),
            ),
            if (r != null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _VdotPredictorCard extends StatelessWidget {
  const _VdotPredictorCard({
    required this.vdotAsync,
    required this.unitSystem,
    required this.colors,
  });

  final AsyncValue<VdotEstimate?> vdotAsync;
  final String unitSystem;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    final est = vdotAsync.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'VO2MAX & PREDIKSI LOMBA',
                    style: AppTypography.metricLabel(colors.textSecondary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.hairlineBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ESTIMASI',
                    style: AppTypography.chartAxis(colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (est == null)
              Text(
                'Selesaikan minimal 1 aktivitas lari ≥ 1.5 km untuk menghitung estimasi VO2max & prediksi lomba.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    est.vo2Max.toStringAsFixed(1),
                    style: AppTypography.paceLarge(colors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ml/kg/min (VDOT-lite • estimasi)',
                    style: AppTypography.chartAxis(colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Basis: ${est.sourceTitle} (${formatDuration(est.sourceDurationSec)})',
                style: AppTypography.chartAxis(colors.textSecondary),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              for (final pred in est.predictions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 112,
                        child: Text(
                          pred.distance.label,
                          style: AppTypography.splitTable(colors.textSecondary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          formatDuration(pred.predictedDurationSec),
                          style: AppTypography.splitTable(colors.textPrimary),
                        ),
                      ),
                      Text(
                        UnitFormatter.formatPaceWithUnit(
                          pred.predictedPaceSecPerKm,
                          unitSystem,
                        ),
                        style: AppTypography.chartAxis(colors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubStat extends StatelessWidget {
  const _SubStat({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTypography.metricLabel(colors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.splitTable(colors.textPrimary)),
      ],
    );
  }
}
