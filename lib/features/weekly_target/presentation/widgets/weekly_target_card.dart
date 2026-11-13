import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/weekly_target_providers.dart';
import '../../domain/weekly_target.dart';

class WeeklyTargetCard extends ConsumerWidget {
  const WeeklyTargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetAsync = ref.watch(weeklyTargetProvider);

    return targetAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (progress) => _buildCard(context, ref, progress),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    WeeklyTargetProgress progress,
  ) {
    final isAchieved = progress.isAchieved;
    final primaryColor = isAchieved
        ? const Color(0xFF00E676)
        : const Color(0xFF00E5FF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAchieved
              ? const Color(0xFF00E676).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isAchieved
                            ? Icons.emoji_events_rounded
                            : Icons.track_changes_rounded,
                        color: primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'TARGET MINGGU INI',
                      style: TextStyle(
                        color: Color(0xFF8E9BAE),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showEditTargetDialog(context, ref, progress.targetKm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          'Ubah Target',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress text & percentage
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      ' / ${progress.targetKm.toStringAsFixed(0)} km',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(progress.progressPercent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.progressPercent,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),

            const SizedBox(height: 10),

            // Bottom summary: status message & activity count
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
                          : Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                      fontWeight: isAchieved ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  '${progress.activityCount} lari',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
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
    final ctrl = TextEditingController(text: currentTargetKm.toStringAsFixed(0));

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
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
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
