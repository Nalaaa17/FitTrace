import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/shoe_providers.dart';
import '../domain/shoe.dart';

class ShoeManagementScreen extends ConsumerWidget {
  const ShoeManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoesAsync = ref.watch(shoesNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        title: const Text(
          'Tracking Sepatu Lari',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A1D24),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: shoesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00E676)),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Gagal memuat data sepatu: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (shoes) {
          if (shoes.isEmpty) {
            return _buildEmptyState(context);
          }

          final wornCount = shoes
              .where((s) => !s.shoe.isRetired && s.isAlertWorn)
              .length;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              if (wornCount > 0) ...[
                _buildAlertBanner(context, wornCount),
                const SizedBox(height: 16),
              ],
              _buildSummaryHeader(context, shoes),
              const SizedBox(height: 16),
              ...shoes.map(
                (shoeWithUsage) => _buildShoeCard(context, ref, shoeWithUsage),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Sepatu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showShoeDialog(context, ref),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                size: 64,
                color: Color(0xFF00E676),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Sepatu Tercatat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan sepatu lari kamu untuk memantau jarak tempuh (mileage) dan mendapatkan peringatan keausan saat mencapai 500-800 km.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, int wornCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3E1C1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF5252).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF5252),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Waktunya Ganti Sepatu!',
                  style: TextStyle(
                    color: Color(0xFFFF5252),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$wornCount sepatu lari kamu telah melampaui batas jarak rekomendasi (bantalan sol & busa telah aus).',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
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

  Widget _buildSummaryHeader(BuildContext context, List<ShoeWithUsage> shoes) {
    final activeCount = shoes.where((s) => !s.shoe.isRetired).length;
    final totalKm = shoes.fold<double>(
      0.0,
      (sum, s) => sum + s.currentDistanceKm,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              label: 'SEPATU AKTIF',
              value: '$activeCount',
              sub: 'dari ${shoes.length} total',
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Expanded(
            child: _buildMetricItem(
              label: 'TOTAL JARAK',
              value: '${totalKm.toStringAsFixed(1)} km',
              sub: 'semua sepatu',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required String sub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E9BAE),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
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
  ) {
    final shoe = shoeWithUsage.shoe;
    final isWorn = shoeWithUsage.isAlertWorn;
    final isNear = shoeWithUsage.isNearLimit;

    Color progressColor;
    if (isWorn) {
      progressColor = const Color(0xFFFF5252);
    } else if (isNear) {
      progressColor = const Color(0xFFFFB300);
    } else {
      progressColor = const Color(0xFF00E676);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: shoe.isRetired
            ? const Color(0xFF16181E).withValues(alpha: 0.7)
            : const Color(0xFF1E222B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWorn
              ? const Color(0xFFFF5252).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
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
                                color: shoe.isRetired
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.white,
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
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'UTAMA',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
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
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PENSIUN',
                                style: TextStyle(
                                  color: Colors.grey,
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
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: const Color(0xFF232833),
                  onSelected: (val) {
                    if (val == 'default') {
                      ref
                          .read(shoesNotifierProvider.notifier)
                          .setDefaultShoe(shoe.id);
                    } else if (val == 'edit') {
                      _showShoeDialog(context, ref, existing: shoeWithUsage);
                    } else if (val == 'toggle_retire') {
                      ref
                          .read(shoesNotifierProvider.notifier)
                          .updateShoe(
                            id: shoe.id,
                            name: shoe.name,
                            brand: shoe.brand,
                            maxDistanceKm: shoe.maxDistanceKm,
                            isDefault: shoe.isRetired ? shoe.isDefault : false,
                            isRetired: !shoe.isRetired,
                          );
                    } else if (val == 'delete') {
                      _confirmDelete(context, ref, shoe);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!shoe.isDefault && !shoe.isRetired)
                      const PopupMenuItem(
                        value: 'default',
                        child: Text(
                          'Jadikan Sepatu Utama',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'Edit Sepatu',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_retire',
                      child: Text(
                        shoe.isRetired ? 'Aktifkan Kembali' : 'Pensiunkan',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Hapus Sepatu',
                        style: TextStyle(color: Colors.redAccent),
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
                  '${shoeWithUsage.currentDistanceKm.toStringAsFixed(1)} km / ${shoe.maxDistanceKm.toStringAsFixed(0)} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${shoeWithUsage.wearPercent.toStringAsFixed(1)}% Aus',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isWorn
                      ? '🚨 Melebihi ${(shoeWithUsage.currentDistanceKm - shoe.maxDistanceKm).toStringAsFixed(1)} km (Waktunya Ganti)'
                      : 'Sisa ${shoeWithUsage.remainingKm.toStringAsFixed(1)} km lagi',
                  style: TextStyle(
                    color: isWorn
                        ? const Color(0xFFFF5252)
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: isWorn ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  '${shoeWithUsage.activitiesCount} lari',
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Shoe shoe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222B),
        title: const Text(
          'Hapus Sepatu?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${shoe.name}"? Aktivitas terkait tidak akan terhapus, tetapi link sepatu akan dilepas.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
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
    WidgetRef ref, {
    ShoeWithUsage? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.shoe.name ?? '');
    final brandCtrl = TextEditingController(text: existing?.shoe.brand ?? '');
    final maxKmCtrl = TextEditingController(
      text: (existing?.shoe.maxDistanceKm ?? 600.0).toStringAsFixed(0),
    );
    bool isDefault = existing?.shoe.isDefault ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E222B),
              title: Text(
                existing == null ? 'Tambah Sepatu Lari' : 'Edit Sepatu',
                style: const TextStyle(
                  color: Colors.white,
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
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Model / Nama Sepatu *',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'Contoh: Pegasus 40, Novablast 3',
                        hintStyle: TextStyle(color: Colors.white30),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: brandCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Merek / Brand',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'Contoh: Nike, Asics, Hoka, Adidas',
                        hintStyle: TextStyle(color: Colors.white30),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Batas Jarak Maksimum Rekomendasi:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [500, 600, 800].map((km) {
                        final isSelected = maxKmCtrl.text == km.toString();
                        return ChoiceChip(
                          label: Text('$km km'),
                          selected: isSelected,
                          selectedColor: const Color(0xFF00E676),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setState(() {
                              maxKmCtrl.text = km.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: maxKmCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Batas Kustom (KM)',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Jadikan Sepatu Utama',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      subtitle: Text(
                        'Otomatis dipasangkan ke aktivitas baru',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      value: isDefault,
                      activeColor: const Color(0xFF00E676),
                      checkColor: Colors.black,
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
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final maxKm =
                        double.tryParse(maxKmCtrl.text.trim()) ?? 600.0;

                    if (existing == null) {
                      ref
                          .read(shoesNotifierProvider.notifier)
                          .addShoe(
                            name: name,
                            brand: brandCtrl.text.trim(),
                            maxDistanceKm: maxKm,
                            isDefault: isDefault,
                          );
                    } else {
                      ref
                          .read(shoesNotifierProvider.notifier)
                          .updateShoe(
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
