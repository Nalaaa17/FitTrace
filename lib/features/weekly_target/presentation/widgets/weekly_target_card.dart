import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../application/weekly_target_providers.dart';
import '../../domain/weekly_target.dart';

class WeeklyTargetCard extends ConsumerWidget {
  const WeeklyTargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetAsync = ref.watch(weeklyTargetProvider);
    final prefsAsync = ref.watch(userPreferencesProvider);
    final unitSystem = prefsAsync.value?.unitSystem;
    final colors = context.fitColors;

    return targetAsync.when(
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Memuat target mingguan...',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      error: (_, _) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: colors.accentDanger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gagal memuat target mingguan',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(weeklyTargetProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (progress) =>
          _buildCard(context, ref, progress, colors, unitSystem),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    WeeklyTargetProgress progress,
    FitTraceColors colors,
    String? unitSystem,
  ) {
    final isAchieved = progress.isAchieved;
    final accentColor = isAchieved ? colors.accentSuccess : colors.accentInfo;
    final unitLabel = UnitFormatter.distanceUnitLabel(unitSystem);
    final currentDisplay = UnitFormatter.convertDistanceMeters(
      progress.currentKm * 1000.0,
      unitSystem,
    );
    final targetDisplay = UnitFormatter.convertDistanceMeters(
      progress.targetKm * 1000.0,
      unitSystem,
    );
    final remainingDisplay = UnitFormatter.convertDistanceMeters(
      progress.remainingKm * 1000.0,
      unitSystem,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Icon + Label + Ubah Target Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isAchieved
                          ? Icons.emoji_events_rounded
                          : Icons.track_changes_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TARGET MINGGU INI',
                      style: AppTypography.metricLabel(colors.textSecondary),
                    ),
                  ],
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showEditTargetDialog(
                    context,
                    ref,
                    progress.targetKm,
                    colors,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Ubah',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Main Numbers Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentDisplay.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        letterSpacing: -0.5,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${targetDisplay.toStringAsFixed(0)} $unitLabel',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFontFamily,
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(progress.progressPercent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFontFamily,
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.progressPercent,
                minHeight: 6,
                backgroundColor: colors.trackBg,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                semanticsLabel: 'Progres target lari minggu ini',
                semanticsValue:
                    '${(progress.progressPercent * 100).toStringAsFixed(0)}%',
              ),
            ),

            const SizedBox(height: 10),

            // Footer info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isAchieved
                        ? 'Target mingguan tercapai'
                        : 'Sisa ${remainingDisplay.toStringAsFixed(1)} $unitLabel lagi • ${progress.daysRemainingInWeek == 0 ? "Hari terakhir" : "${progress.daysRemainingInWeek} hari tersisa"}',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFontFamily,
                      color: isAchieved
                          ? colors.accentSuccess
                          : colors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          isAchieved ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  '${progress.activityCount} sesi',
                  style: AppTypography.metricLabel(colors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTargetDialog(
    BuildContext context,
    WidgetRef ref,
    double currentTargetKm,
    FitTraceColors colors,
  ) {
    final ctrl =
        TextEditingController(text: currentTargetKm.toStringAsFixed(0));
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colors.bgElevated,
              title: Text(
                'Target Jarak Mingguan',
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tentukan target jarak tempuh yang ingin dicapai setiap minggu:',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [15, 25, 30, 40, 50].map((km) {
                      final isSelected = ctrl.text.trim() == km.toString();
                      return ChoiceChip(
                        label: Text('$km km'),
                        selected: isSelected,
                        selectedColor: colors.accentInfo,
                        backgroundColor: colors.trackBg,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colors.bgBase
                              : colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setState(() {
                            ctrl.text = km.toString();
                            errorText = null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: colors.textPrimary),
                    onChanged: (_) => setState(() => errorText = null),
                    decoration: InputDecoration(
                      labelText: 'Target Kustom (km)',
                      labelStyle: TextStyle(color: colors.textSecondary),
                      suffixText: 'km',
                      suffixStyle: TextStyle(color: colors.textSecondary),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final target = double.tryParse(ctrl.text.trim());
                    if (target == null || target <= 0) {
                      setState(() {
                        errorText = 'Masukkan angka jarak lebih dari 0';
                      });
                      return;
                    }
                    ref
                        .read(weeklyTargetProvider.notifier)
                        .updateTargetKm(target);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => ctrl.dispose());
  }
}
