import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/weekly_target_providers.dart';
import '../../domain/weekly_target.dart';

class WeeklyTargetCard extends ConsumerWidget {
  const WeeklyTargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetAsync = ref.watch(weeklyTargetProvider);
    final colors = context.fitColors;

    return targetAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (progress) => _buildCard(context, ref, progress, colors),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    WeeklyTargetProgress progress,
    FitTraceColors colors,
  ) {
    final isAchieved = progress.isAchieved;
    final accentColor = isAchieved ? const Color(0xFF00E676) : const Color(0xFF00E5FF);

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
                  onTap: () =>
                      _showEditTargetDialog(context, ref, progress.targetKm),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          size: 13,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

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
                      progress.currentKm.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${progress.targetKm.toStringAsFixed(0)} km',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(progress.progressPercent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
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
                backgroundColor: colors.bgElevated,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
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
                        ? '🎉 Target mingguan tercapai!'
                        : '🔥 Sisa ${progress.remainingKm.toStringAsFixed(1)} km lagi • ${progress.daysRemainingInWeek == 0 ? "Hari terakhir!" : "${progress.daysRemainingInWeek} hari tersisa"}',
                    style: TextStyle(
                      color: isAchieved
                          ? const Color(0xFF00E676)
                          : colors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          isAchieved ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  '${progress.activityCount} lari',
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
  ) {
    final ctrl =
        TextEditingController(text: currentTargetKm.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E222B),
              title: const Text(
                'Target Jarak Mingguan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tentukan target jarak tempuh yang ingin dicapai setiap minggu:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [15, 25, 30, 40, 50].map((km) {
                      final isSelected = ctrl.text == km.toString();
                      return ChoiceChip(
                        label: Text('$km km'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00E5FF),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setState(() {
                            ctrl.text = km.toString();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Target Kustom (KM)',
                      labelStyle: TextStyle(color: Colors.white70),
                      suffixText: 'km',
                      suffixStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child:
                      const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final target = double.tryParse(ctrl.text.trim());
                    if (target != null && target > 0) {
                      ref
                          .read(weeklyTargetProvider.notifier)
                          .updateTargetKm(target);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
