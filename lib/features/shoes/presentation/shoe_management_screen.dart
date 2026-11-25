import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/unit_formatter.dart';
import '../application/shoe_providers.dart';
import '../domain/shoe.dart';

class ShoeManagementScreen extends ConsumerWidget {
  const ShoeManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoesAsync = ref.watch(shoesNotifierProvider);
    final unitSystem = ref.watch(userPreferencesProvider).value?.unitSystem;
    final colors = context.fitColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Sepatu Lari'),
      ),
      body: shoesAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.accentSharp),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 36, color: colors.accentDanger),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat data sepatu: $err',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(shoesNotifierProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (shoes) {
          if (shoes.isEmpty) {
            return _buildEmptyState(context, ref, colors);
          }

          final wornCount = shoes
              .where((s) => !s.shoe.isRetired && s.isAlertWorn)
              .length;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              if (wornCount > 0) ...[
                _buildAlertBanner(context, wornCount, colors),
                const SizedBox(height: 16),
              ],
              _buildSummaryHeader(context, shoes, colors, unitSystem),
              const SizedBox(height: 16),
              ...shoes.map(
                (shoeWithUsage) => _buildShoeCard(
                  context,
                  ref,
                  shoeWithUsage,
                  colors,
                  unitSystem,
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Tambah Sepatu'),
        onPressed: () => _showShoeDialog(context, ref, colors),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    FitTraceColors colors,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                shape: BoxShape.circle,
                border: Border.all(color: colors.hairlineBorder),
              ),
              child: Icon(
                Icons.directions_run_rounded,
                size: 56,
                color: colors.accentSuccess,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Sepatu Tercatat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan sepatu lari Anda untuk memantau jarak tempuh dan mendapatkan peringatan keausan saat mencapai 500–800 km.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showShoeDialog(context, ref, colors),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Sepatu Pertama'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(
    BuildContext context,
    int wornCount,
    FitTraceColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.accentDanger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.accentDanger.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colors.accentDanger,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waktunya Ganti Sepatu',
                  style: TextStyle(
                    color: colors.accentDanger,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$wornCount sepatu lari Anda telah melampaui batas jarak rekomendasi.',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    List<ShoeWithUsage> shoes,
    FitTraceColors colors,
    String? unitSystem,
  ) {
    final activeCount = shoes.where((s) => !s.shoe.isRetired).length;
    final totalMeters = shoes.fold<double>(
      0.0,
      (sum, s) => sum + s.totalDistanceMeters,
    );
    final totalDisplay = UnitFormatter.formatDistanceValue(
      totalMeters,
      unitSystem,
      decimals: 1,
    );
    final unitLabel = UnitFormatter.distanceUnitLabel(unitSystem);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                colors: colors,
                label: 'SEPATU AKTIF',
                value: '$activeCount',
                sub: 'dari ${shoes.length} total',
              ),
            ),
            Container(
              height: 36,
              width: 1,
              color: colors.hairlineBorder,
            ),
            Expanded(
              child: _buildMetricItem(
                colors: colors,
                label: 'TOTAL JARAK',
                value: '$totalDisplay $unitLabel',
                sub: 'semua sepatu',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required FitTraceColors colors,
    required String label,
    required String value,
    required String sub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.metricLabel(colors.textSecondary).copyWith(
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.displayFontFamily,
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildShoeCard(
    BuildContext context,
    WidgetRef ref,
    ShoeWithUsage shoeWithUsage,
    FitTraceColors colors,
    String? unitSystem,
  ) {
    final shoe = shoeWithUsage.shoe;
    final isWorn = shoeWithUsage.isAlertWorn;
    final isNear = shoeWithUsage.isNearLimit;

    final Color progressColor;
    if (isWorn) {
      progressColor = colors.accentDanger;
    } else if (isNear) {
      progressColor = colors.accentWarning;
    } else {
      progressColor = colors.accentSuccess;
    }

    final unitLabel = UnitFormatter.distanceUnitLabel(unitSystem);
    final currentDist = UnitFormatter.convertDistanceMeters(
      shoeWithUsage.totalDistanceMeters,
      unitSystem,
    );
    final maxDist = UnitFormatter.convertDistanceMeters(
      shoe.maxDistanceKm * 1000.0,
      unitSystem,
    );
    final remainingDist = UnitFormatter.convertDistanceMeters(
      shoeWithUsage.remainingKm * 1000.0,
      unitSystem,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        shape: isWorn
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colors.accentDanger.withValues(alpha: 0.45),
                ),
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showShoeDialog(
            context,
            ref,
            colors,
            existing: shoeWithUsage,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: progressColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_run_rounded,
                        color: progressColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  shoe.name,
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFontFamily,
                                    color: shoe.isRetired
                                        ? colors.textSecondary
                                        : colors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (shoe.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.accentSuccess
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'UTAMA',
                                    style: TextStyle(
                                      color: colors.accentSuccess,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                              if (shoe.isRetired) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.trackBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'PENSIUN',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (shoe.brand.isNotEmpty)
                            Text(
                              shoe.brand,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: colors.textSecondary),
                      color: colors.bgElevated,
                      onSelected: (val) {
                        if (val == 'default') {
                          ref
                              .read(shoesNotifierProvider.notifier)
                              .setDefaultShoe(shoe.id);
                        } else if (val == 'edit') {
                          _showShoeDialog(
                            context,
                            ref,
                            colors,
                            existing: shoeWithUsage,
                          );
                        } else if (val == 'toggle_retire') {
                          ref.read(shoesNotifierProvider.notifier).updateShoe(
                                id: shoe.id,
                                name: shoe.name,
                                brand: shoe.brand,
                                maxDistanceKm: shoe.maxDistanceKm,
                                isDefault:
                                    shoe.isRetired ? shoe.isDefault : false,
                                isRetired: !shoe.isRetired,
                              );
                        } else if (val == 'delete') {
                          _confirmDelete(context, ref, shoe, colors);
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (!shoe.isDefault && !shoe.isRetired)
                          PopupMenuItem(
                            value: 'default',
                            child: Text(
                              'Jadikan Sepatu Utama',
                              style: TextStyle(color: colors.textPrimary),
                            ),
                          ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            'Edit Sepatu',
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle_retire',
                          child: Text(
                            shoe.isRetired ? 'Aktifkan Kembali' : 'Pensiunkan',
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Hapus Sepatu',
                            style: TextStyle(color: colors.accentDanger),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentDist.toStringAsFixed(1)} $unitLabel / ${maxDist.toStringAsFixed(0)} $unitLabel',
                      style: AppTypography.splitTable(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${shoeWithUsage.wearPercent.toStringAsFixed(1)}% Aus',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFontFamily,
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: shoeWithUsage.wearRatio.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: colors.trackBg,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    semanticsLabel: 'Tingkat keausan ${shoe.name}',
                    semanticsValue:
                        '${shoeWithUsage.wearPercent.toStringAsFixed(0)}%',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isWorn
                            ? 'Melebihi ${(currentDist - maxDist).toStringAsFixed(1)} $unitLabel (Waktunya Ganti)'
                            : 'Sisa ${remainingDist.toStringAsFixed(1)} $unitLabel lagi',
                        style: TextStyle(
                          color: isWorn
                              ? colors.accentDanger
                              : colors.textSecondary,
                          fontSize: 11,
                          fontWeight:
                              isWorn ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '${shoeWithUsage.activitiesCount} sesi',
                      style: AppTypography.metricLabel(colors.textSecondary)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Shoe shoe,
    FitTraceColors colors,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Hapus Sepatu?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${shoe.name}"? Aktivitas terkait tidak akan terhapus, tetapi tautan sepatu akan dilepas.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: colors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.accentDanger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(shoesNotifierProvider.notifier).deleteShoe(shoe.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showShoeDialog(
    BuildContext context,
    WidgetRef ref,
    FitTraceColors colors, {
    ShoeWithUsage? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.shoe.name ?? '');
    final brandCtrl = TextEditingController(text: existing?.shoe.brand ?? '');
    final maxKmCtrl = TextEditingController(
      text: (existing?.shoe.maxDistanceKm ?? 600.0).toStringAsFixed(0),
    );
    bool isDefault = existing?.shoe.isDefault ?? false;
    String? nameError;
    String? maxKmError;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colors.bgElevated,
              title: Text(
                existing == null ? 'Tambah Sepatu Lari' : 'Edit Sepatu',
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: colors.textPrimary),
                      onChanged: (_) => setState(() => nameError = null),
                      decoration: InputDecoration(
                        labelText: 'Model / Nama Sepatu *',
                        labelStyle: TextStyle(color: colors.textSecondary),
                        hintText: 'Contoh: Pegasus 40, Novablast 3',
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withValues(alpha: 0.55),
                        ),
                        errorText: nameError,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: brandCtrl,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Merek / Brand',
                        labelStyle: TextStyle(color: colors.textSecondary),
                        hintText: 'Contoh: Nike, Asics, Hoka, Adidas',
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Batas Jarak Maksimum Rekomendasi:',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [500, 600, 800].map((km) {
                        final isSelected = maxKmCtrl.text.trim() == km.toString();
                        return ChoiceChip(
                          label: Text('$km km'),
                          selected: isSelected,
                          selectedColor: colors.accentSuccess,
                          backgroundColor: colors.trackBg,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colors.bgBase
                                : colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setState(() {
                              maxKmCtrl.text = km.toString();
                              maxKmError = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: maxKmCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: colors.textPrimary),
                      onChanged: (_) => setState(() => maxKmError = null),
                      decoration: InputDecoration(
                        labelText: 'Batas Kustom (km)',
                        labelStyle: TextStyle(color: colors.textSecondary),
                        errorText: maxKmError,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Jadikan Sepatu Utama',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'Otomatis dipasangkan ke aktivitas baru',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      value: isDefault,
                      activeColor: colors.accentSuccess,
                      checkColor: colors.bgBase,
                      onChanged: (val) {
                        setState(() {
                          isDefault = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
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
                    final name = nameCtrl.text.trim();
                    final maxKm = double.tryParse(maxKmCtrl.text.trim());
                    if (name.isEmpty) {
                      setState(() => nameError = 'Nama sepatu wajib diisi');
                      return;
                    }
                    if (maxKm == null || maxKm <= 0) {
                      setState(
                        () => maxKmError = 'Masukkan jarak batas lebih dari 0',
                      );
                      return;
                    }

                    if (existing == null) {
                      ref.read(shoesNotifierProvider.notifier).addShoe(
                            name: name,
                            brand: brandCtrl.text.trim(),
                            maxDistanceKm: maxKm,
                            isDefault: isDefault,
                          );
                    } else {
                      ref.read(shoesNotifierProvider.notifier).updateShoe(
                            id: existing.shoe.id,
                            name: name,
                            brand: brandCtrl.text.trim(),
                            maxDistanceKm: maxKm,
                            isDefault: isDefault,
                            isRetired: existing.shoe.isRetired,
                          );
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      brandCtrl.dispose();
      maxKmCtrl.dispose();
    });
  }
}
