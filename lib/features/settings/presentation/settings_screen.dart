import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrics_engine/metrics_engine.dart';

import '../../../core/config/app_info.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../backup/application/backup_providers.dart';
import '../../backup/data/backup_restore_service.dart';
import '../../garmin_sync/application/garmin_sync_providers.dart';
import '../../garmin_sync/presentation/garmin_webview_login_screen.dart';
import '../../shoes/presentation/shoe_management_screen.dart';
import '../../story_share/domain/story_template_config.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesProvider);
    final syncState = ref.watch(garminSyncControllerProvider);
    final backupState = ref.watch(backupControllerProvider);
    final storageStatsAsync = ref.watch(localStorageStatsProvider);
    final colors = context.fitColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (prefs) {
          final db = ref.read(appDatabaseProvider);
          return ListView(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            children: <Widget>[
              _SectionTitle('TAMPILAN', colors: colors),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Tema Aplikasi',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const <ButtonSegment<String>>[
                            ButtonSegment(value: 'dark', label: Text('Dark')),
                            ButtonSegment(value: 'light', label: Text('Light')),
                            ButtonSegment(
                              value: 'system',
                              label: Text('System'),
                            ),
                          ],
                          selected: <String>{prefs.themeMode},
                          onSelectionChanged: (sel) {
                            db.updatePreferences(
                              UserPreferencesTableCompanion(
                                themeMode: Value(sel.first),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Satuan Jarak',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SegmentedButton<String>(
                            showSelectedIcon: false,
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment(
                                value: 'metric',
                                label: Text('KM'),
                              ),
                              ButtonSegment(
                                value: 'imperial',
                                label: Text('MI'),
                              ),
                            ],
                            selected: <String>{prefs.unitSystem},
                            onSelectionChanged: (sel) {
                              db.updatePreferences(
                                UserPreferencesTableCompanion(
                                  unitSystem: Value(sel.first),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionTitle('SINKRONISASI GARMIN', colors: colors),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: const Text('Status Akun Garmin'),
                      subtitle: Text(
                        _formatAccountSubtitle(
                          prefs: prefs,
                          needsAttention: syncState.needsUserAttention,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _handleGarminAccountTap(
                        context,
                        ref,
                        prefs: prefs,
                      ),
                    ),
                    if (prefs.garminLoggedIn) ...<Widget>[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.sync_rounded),
                        title: Text(
                          syncState.isSyncing
                              ? 'Sedang Menyinkronkan...'
                              : 'Sinkronkan Sekarang',
                        ),
                        subtitle: const Text(
                          'Auto-sync saat app dibuka (threshold 10 menit • debounce 60 detik)',
                        ),
                        enabled: !syncState.isSyncing,
                        onTap: () async {
                          final result = await ref
                              .read(garminSyncControllerProvider.notifier)
                              .syncNow();
                          if (!context.mounted || result == null) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text(result.summaryBannerText)),
                            );
                        },
                      ),
                    ],
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Sinkronisasi Otomatis'),
                      subtitle: const Text(
                        'Jalankan saat aplikasi dibuka atau kembali aktif',
                      ),
                      value: prefs.backgroundSyncEnabled,
                      onChanged: (enabled) {
                        db.updatePreferences(
                          UserPreferencesTableCompanion(
                            backgroundSyncEnabled: Value(enabled),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Izinkan Data Seluler'),
                      subtitle: const Text(
                        'Sinkronisasi otomatis tetap berjalan lewat paket data',
                      ),
                      value: !prefs.backgroundSyncWifiOnly,
                      onChanged: (allowCellular) {
                        db.updatePreferences(
                          UserPreferencesTableCompanion(
                            backgroundSyncWifiOnly: Value(!allowCellular),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Izinkan Tanpa Charging'),
                      subtitle: const Text(
                        'Sinkronisasi tetap berjalan saat perangkat tidak diisi daya',
                      ),
                      value: !prefs.backgroundSyncRequireCharging,
                      onChanged: (allowBattery) {
                        db.updatePreferences(
                          UserPreferencesTableCompanion(
                            backgroundSyncRequireCharging: Value(!allowBattery),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Interval Background Sync (WorkManager / iOS)',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Minimum OS Android 15 menit (default: aktif di seluler & baterai)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<int>(
                              showSelectedIcon: false,
                              segments: const <ButtonSegment<int>>[
                                ButtonSegment(value: 15, label: Text('15m')),
                                ButtonSegment(value: 30, label: Text('30m')),
                                ButtonSegment(value: 60, label: Text('1j')),
                                ButtonSegment(value: 360, label: Text('6j')),
                              ],
                              selected: <int>{
                                <int>{15, 30, 60, 360}.contains(
                                        prefs.backgroundSyncIntervalMinutes)
                                    ? prefs.backgroundSyncIntervalMinutes
                                    : 15,
                              },
                              onSelectionChanged: (sel) {
                                db.updatePreferences(
                                  UserPreferencesTableCompanion(
                                    backgroundSyncIntervalMinutes:
                                        Value(sel.first),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionTitle('SEPATU LARI & PERALATAN', colors: colors),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.accentSuccess.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_run_rounded,
                      color: colors.accentSuccess,
                    ),
                  ),
                  title: const Text(
                    'Tracking Sepatu Lari',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Catat mileage sepatu & alert keausan (500-800 km)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ShoeManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _SectionTitle('KARTU INSTAGRAM STORY', colors: colors),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Template Default',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: StoryTemplateId.values.map((t) {
                          final isSelected = prefs.defaultTemplateId == t.storageKey;
                          return ChoiceChip(
                            label: Text(t.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                db.updatePreferences(
                                  UserPreferencesTableCompanion(
                                    defaultTemplateId: Value(t.storageKey),
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(growable: false),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tampilkan Watermark FitTrace'),
                        subtitle: const Text(
                          'Label monokrom kecil di pojok kartu 9:16',
                        ),
                        value: prefs.watermarkEnabled,
                        onChanged: (enabled) {
                          db.updatePreferences(
                            UserPreferencesTableCompanion(
                              watermarkEnabled: Value(enabled),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionTitle('PROFIL & ZONA DETAK JANTUNG', colors: colors),
              const SizedBox(height: 8),
              _buildHrProfileCard(
                context,
                ref,
                db: db,
                prefs: prefs,
                colors: colors,
              ),
              const SizedBox(height: 20),
              _SectionTitle('MANAJEMEN DATA & BACKUP', colors: colors),
              const SizedBox(height: 8),
              _buildBackupAndStorageCard(
                context,
                ref,
                prefs: prefs,
                backupState: backupState,
                storageStatsAsync: storageStatsAsync,
                colors: colors,
              ),
              const SizedBox(height: 20),
              _SectionTitle('TENTANG & PRIVASI', colors: colors),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Kebijakan Privasi (100% Local-Only)'),
                      subtitle: const Text(
                        'Zero server backend • Zero telemetry • Cookie di Keystore/Keychain',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showPrivacySheet(context, colors),
                    ),
                    const Divider(),
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 36,
                          height: 36,
                        ),
                      ),
                      title: const Text(AppInfo.versionLabel),
                      subtitle: const Text('com.fittrace.app • Local-First Running Analytics'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatAccountSubtitle({
    required UserPreference prefs,
    required bool needsAttention,
  }) {
    if (!prefs.garminLoggedIn) {
      return 'Belum terhubung • Gunakan API Key atau Web';
    }
    if (needsAttention) {
      return 'Terhubung • Perlu login ulang / verifikasi keamanan';
    }
    final last = prefs.lastSyncAt?.toLocal();
    if (last == null) {
      return 'Terhubung • Belum pernah disinkronkan';
    }
    final hh = last.hour.toString().padLeft(2, '0');
    final mm = last.minute.toString().padLeft(2, '0');
    final dd = last.day.toString().padLeft(2, '0');
    final mo = last.month.toString().padLeft(2, '0');
    return 'Terhubung • Sync terakhir $dd/$mo/${last.year} $hh:$mm';
  }

  Future<void> _handleGarminAccountTap(
    BuildContext context,
    WidgetRef ref, {
    required UserPreference prefs,
  }) async {
    if (!prefs.garminLoggedIn) {
      final mode = await showModalBottomSheet<String>(
        context: context,
        builder: (sheetCtx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.key_rounded, color: Colors.amber),
                title: const Text('Garmin Personal API Key (Rekomendasi Resmi)'),
                subtitle: const Text(
                  'Langsung terhubung dengan API resmi Garmin (GCDC_...). Cepat, stabil, tanpa CAPTCHA.',
                ),
                onTap: () => Navigator.of(sheetCtx).pop('apikey'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.public_rounded),
                title: const Text('Login via Web Garmin (Browser)'),
                subtitle: const Text(
                  'Login interaktif via portal Single Sign-On Garmin Connect.',
                ),
                onTap: () => Navigator.of(sheetCtx).pop('webview'),
              ),
            ],
          ),
        ),
      );

      if (!context.mounted || mode == null) return;

      if (mode == 'apikey') {
        await _showPersonalApiKeyDialog(context, ref);
        return;
      }

      if (mode == 'webview') {
        final loggedIn = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => const GarminWebViewLoginScreen(),
          ),
        );
        if (loggedIn == true && context.mounted) {
          final result =
              await ref.read(garminSyncControllerProvider.notifier).syncNow();
          if (!context.mounted || result == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(result.summaryBannerText)));
        }
      }
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.key_rounded, color: Colors.amber),
              title: const Text('Ganti / Perbarui Personal API Key'),
              onTap: () => Navigator.of(sheetCtx).pop('apikey'),
            ),
            ListTile(
              leading: const Icon(Icons.login_rounded),
              title: const Text('Login Ulang via Web Garmin'),
              onTap: () => Navigator.of(sheetCtx).pop('relogin'),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Putuskan Akun Garmin'),
              subtitle: const Text(
                'Menghapus sesi terenkripsi; data lari lokal tetap aman',
              ),
              onTap: () => Navigator.of(sheetCtx).pop('disconnect'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    if (action == 'apikey') {
      await _showPersonalApiKeyDialog(context, ref);
    } else if (action == 'relogin') {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const GarminWebViewLoginScreen(),
        ),
      );
      if (ok == true && context.mounted) {
        await ref.read(garminSyncControllerProvider.notifier).syncNow();
      }
    } else if (action == 'disconnect') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dlgCtx) => AlertDialog(
          title: const Text('Putuskan Akun Garmin?'),
          content: const Text(
            'Sesi dan kunci API terenkripsi akan dihapus dari perangkat. Riwayat lari di SQLite tidak akan terhapus.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dlgCtx).pop(true),
              child: const Text('Putuskan'),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        await ref.read(garminSyncControllerProvider.notifier).disconnectGarmin();
      }
    }
  }

  Future<void> _showPersonalApiKeyDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final session = await ref.read(secureCookieStoreProvider).loadSession();
    if (!context.mounted) return;
    final hasExistingKey = (session?.personalApiKey ?? '').isNotEmpty;
    final textController = TextEditingController();

    final key = await showDialog<String>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Garmin Personal API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              hasExistingKey
                  ? 'API Key sudah tersimpan aman. Masukkan kunci baru jika ingin menggantinya.'
                  : 'Masukkan Personal API Key resmi dari Garmin Connect (dimulai dengan GCDC_...).',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 1,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                labelText: 'Personal API Key',
                hintText: 'GCDC_...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dlgCtx).pop(textController.text.trim()),
            child: const Text('Hubungkan'),
          ),
        ],
      ),
    );
    textController.dispose();

    if (key == null || key.isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Menghubungkan ke Garmin Personal API...')),
    );

    final res = await ref
        .read(garminSyncControllerProvider.notifier)
        .connectWithPersonalApiKey(key);

    if (!context.mounted) return;

    if (!res.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Gagal menghubungkan API Key.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Berhasil terhubung! Memulai sinkronisasi aktivitas...'),
        backgroundColor: Colors.green,
      ),
    );

    final syncResult =
        await ref.read(garminSyncControllerProvider.notifier).syncNow();

    if (!context.mounted || syncResult == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(syncResult.summaryBannerText)));
  }

  Widget _buildHrProfileCard(
    BuildContext context,
    WidgetRef ref, {
    required AppDatabase db,
    required UserPreference prefs,
    required FitTraceColors colors,
  }) {
    final thresholds = prefs.hrZoneThresholds.length == 4
        ? prefs.hrZoneThresholds
        : HrZoneConfig.defaultThresholdsPercent;
    final resolved = HrZoneConfig.resolve(
      hrMaxManual: prefs.hrMaxManual,
      birthDate: prefs.birthDate,
      thresholdsPercent: thresholds,
    );
    final hrSourceLabel = prefs.hrMaxManual != null
        ? '${resolved.hrMaxBpm} bpm (Manual)'
        : prefs.birthDate != null
            ? '${resolved.hrMaxBpm} bpm (220 − Umur)'
            : '${resolved.hrMaxBpm} bpm (Estimasi Default)';

    final birthLabel = prefs.birthDate != null
        ? _formatShortDate(prefs.birthDate!.toLocal())
        : 'Belum diisi (opsional, lokal saja)';

    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.cake_outlined),
            title: const Text('Tanggal Lahir'),
            subtitle: Text(birthLabel),
            trailing: prefs.birthDate != null
                ? IconButton(
                    tooltip: 'Hapus tanggal lahir',
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      db.updatePreferences(
                        const UserPreferencesTableCompanion(
                          birthDate: Value(null),
                        ),
                      );
                    },
                  )
                : const Icon(Icons.chevron_right),
            onTap: () => _pickBirthDate(context, db: db, current: prefs.birthDate),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('HRmax Aktif'),
            subtitle: Text(hrSourceLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editHrMaxDialog(
              context,
              db: db,
              currentManual: prefs.hrMaxManual,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.stacked_bar_chart_rounded),
            title: const Text('Ambang Zona HR 1–5 (%)'),
            subtitle: Text(
              'Batas Z2..Z5: ${thresholds.join('% / ')}%',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editHrThresholdsDialog(
              context,
              db: db,
              current: thresholds,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupAndStorageCard(
    BuildContext context,
    WidgetRef ref, {
    required UserPreference prefs,
    required BackupOperationState backupState,
    required AsyncValue<LocalStorageStats> storageStatsAsync,
    required FitTraceColors colors,
  }) {
    final stats = storageStatsAsync.value;
    final statsSubtitle = stats == null
        ? 'Menghitung penggunaan ruang...'
        : '${stats.activityCount} aktivitas • '
            '${stats.trackPointCount} trackpoints • '
            '${stats.fitArchiveCount} arsip .fit.gz • '
            '${(stats.totalStorageBytes / (1024 * 1024)).toStringAsFixed(2)} MB';

    final lastBackupStr = prefs.lastBackupAt != null
        ? _formatShortDate(prefs.lastBackupAt!.toLocal())
        : 'Belum pernah';

    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Penyimpanan Lokal (SQLite + Cache)'),
            subtitle: Text('$statsSubtitle\nBackup terakhir: $lastBackupStr'),
            isThreeLine: true,
          ),
          if (backupState.isRunning)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    backupState.stage,
                    style: AppTypography.chartAxis(colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: backupState.progress),
                ],
              ),
            ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Pengingat Backup Bulanan'),
            subtitle: const Text(
              'Tampilkan pengingat jika backup terakhir > 30 hari',
            ),
            value: prefs.backupReminderEnabled,
            onChanged: (enabled) {
              ref.read(appDatabaseProvider).updatePreferences(
                    UserPreferencesTableCompanion(
                      backupReminderEnabled: Value(enabled),
                    ),
                  );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.compress_rounded),
            title: const Text('Compact DB (VACUUM)'),
            subtitle: const Text(
              'Padatkan halaman kosong SQLite & perbarui statistik storage',
            ),
            enabled: !backupState.isRunning,
            onTap: () => _runCompactDb(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.layers_clear_outlined),
            title: const Text('Hapus Cache Peta (OSM)'),
            subtitle: const Text(
              'Hapus cache tile peta offline tanpa menghapus aktivitas lari',
            ),
            enabled: !backupState.isRunning,
            onTap: () => _runClearTileCache(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Ekspor Ringkasan (.CSV)'),
            subtitle: const Text(
              'Ekspor tabel seluruh aktivitas lari dalam format CSV standar',
            ),
            enabled: !backupState.isRunning,
            onTap: () => _runCsvExport(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Backup Penuh (.ZIP)'),
            subtitle: const Text(
              'Ekspor DB, splits, trackpoints biner & .fit.gz (tanpa cookie/token)',
            ),
            enabled: !backupState.isRunning,
            onTap: () => _runFullBackup(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore_page_outlined),
            title: const Text('Restore dari Backup (.ZIP)'),
            subtitle: const Text(
              'Validasi skema & gabungkan tanpa duplikat garminActivityId',
            ),
            enabled: !backupState.isRunning,
            onTap: () => _runRestoreBackup(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: colors.accentSharp),
            title: const Text('Factory Reset Lokal'),
            subtitle: const Text(
              'Hapus permanen semua aktivitas, arsip, cache & sesi Garmin di perangkat',
            ),
            enabled: !backupState.isRunning,
            onTap: () => _confirmDoubleFactoryReset(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBirthDate(
    BuildContext context, {
    required AppDatabase db,
    DateTime? current,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current?.toLocal() ?? DateTime(now.year - 28, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year - 10, 12, 31),
    );
    if (picked == null) return;
    await db.updatePreferences(
      UserPreferencesTableCompanion(birthDate: Value(picked.toUtc())),
    );
  }

  Future<void> _editHrMaxDialog(
    BuildContext context, {
    required AppDatabase db,
    int? currentManual,
  }) async {
    final result = await showDialog<TextInputDialogResult>(
      context: context,
      builder: (_) => TextInputDialog(
        title: 'Atur HRmax Manual',
        initialValue: currentManual?.toString() ?? '',
        keyboardType: TextInputType.number,
        labelText: 'HRmax (100–230 bpm)',
        hintText: 'Contoh: 192',
        secondaryActionLabel: 'Gunakan Otomatis',
        secondaryActionKey: 'clear',
        confirmLabel: 'Simpan',
      ),
    );

    if (result == null) return;
    if (result.action == 'clear') {
      await db.updatePreferences(
        const UserPreferencesTableCompanion(hrMaxManual: Value(null)),
      );
    } else if (result.action == 'save') {
      final parsed = int.tryParse(result.text.trim());
      if (parsed == null || parsed < 100 || parsed > 230) {
        if (context.mounted) {
          _showSnack(context, 'Masukkan nilai HRmax antara 100 hingga 230 bpm.');
        }
        return;
      }
      await db.updatePreferences(
        UserPreferencesTableCompanion(hrMaxManual: Value(parsed)),
      );
    }
  }

  Future<void> _editHrThresholdsDialog(
    BuildContext context, {
    required AppDatabase db,
    required List<int> current,
  }) async {
    final result = await showDialog<TextInputDialogResult>(
      context: context,
      builder: (_) => TextInputDialog(
        title: 'Batas Zona HR 2–5 (%)',
        initialValue: current.join(','),
        labelText: '4 angka persen (dipisah koma)',
        hintText: '60,70,80,90',
        secondaryActionLabel: 'Default',
        secondaryActionKey: 'reset',
        confirmLabel: 'Simpan',
      ),
    );

    if (result == null) return;
    if (result.action == 'reset') {
      await db.updatePreferences(
        const UserPreferencesTableCompanion(
          hrZoneThresholds: Value(HrZoneConfig.defaultThresholdsPercent),
        ),
      );
    } else if (result.action == 'save') {
      final parsed = result.text
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList(growable: false);
      final monotonic = parsed.length == 4 &&
          parsed[0] >= 40 &&
          parsed[0] < parsed[1] &&
          parsed[1] < parsed[2] &&
          parsed[2] < parsed[3] &&
          parsed[3] <= 99;
      if (!monotonic) {
        if (context.mounted) {
          _showSnack(
            context,
            'Format harus 4 persentase naik (mis. 60,70,80,90).',
          );
        }
        return;
      }
      await db.updatePreferences(
        UserPreferencesTableCompanion(hrZoneThresholds: Value(parsed)),
      );
    }
  }

  Future<void> _runCompactDb(BuildContext context, WidgetRef ref) async {
    final res =
        await ref.read(backupControllerProvider.notifier).compactDatabase();
    if (!context.mounted || res == null) return;
    final savedKb = (res.savedBytes / 1024).toStringAsFixed(1);
    _showSnack(context, 'SQLite VACUUM selesai (hemat $savedKb KB).');
  }

  Future<void> _runClearTileCache(BuildContext context, WidgetRef ref) async {
    final freedBytes =
        await ref.read(backupControllerProvider.notifier).clearTileCache();
    if (!context.mounted) return;
    final mb = (freedBytes / (1024 * 1024)).toStringAsFixed(2);
    _showSnack(context, 'Cache peta OSM dibersihkan (hemat $mb MB).');
  }

  Future<void> _runCsvExport(BuildContext context, WidgetRef ref) async {
    final res =
        await ref.read(backupControllerProvider.notifier).exportCsvSummary();
    if (!context.mounted) return;
    final state = ref.read(backupControllerProvider);
    if (state.errorMessage != null) {
      _showSnack(context, 'Ekspor CSV gagal: ${state.errorMessage}');
    } else if (res.saved) {
      _showSnack(context, 'Berhasil mengekspor ${res.rowCount} aktivitas ke CSV.');
    } else {
      _showSnack(context, 'Ekspor CSV dibatalkan.');
    }
  }

  Future<void> _runFullBackup(BuildContext context, WidgetRef ref) async {
    final res =
        await ref.read(backupControllerProvider.notifier).exportFullBackupZip();
    if (!context.mounted) return;
    final state = ref.read(backupControllerProvider);
    if (state.errorMessage != null) {
      _showSnack(context, 'Backup gagal: ${state.errorMessage}');
    } else if (res.saved) {
      _showSnack(context, 'Backup ZIP berhasil disimpan.');
    } else {
      _showSnack(context, 'Penyimpanan backup dibatalkan.');
    }
  }

  Future<void> _runRestoreBackup(BuildContext context, WidgetRef ref) async {
    final summary =
        await ref.read(backupControllerProvider.notifier).restoreBackupFromPicker();
    if (!context.mounted) return;
    final state = ref.read(backupControllerProvider);
    if (state.errorMessage != null) {
      _showSnack(context, 'Restore gagal: ${state.errorMessage}');
    } else if (summary != null) {
      _showSnack(
        context,
        'Restore: ${summary.restoredActivities} aktivitas • '
        '${summary.skippedDuplicates} duplikat dilewati',
      );
    }
  }

  Future<void> _confirmDoubleFactoryReset(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final step1 = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Factory Reset Lokal?'),
        content: const Text(
          'Semua riwayat lari SQLite, trackpoints, splits, arsip .fit.gz, cache peta, Story cache, dan sesi Garmin akan dihapus permanen dari perangkat ini.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dlgCtx).pop(true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (step1 != true || !context.mounted) return;

    final result = await showDialog<TextInputDialogResult>(
      context: context,
      builder: (_) => const TextInputDialog(
        title: 'Konfirmasi Terakhir',
        promptText:
            'Ketik RESET untuk menghapus seluruh data lokal secara permanen:',
        hintText: 'RESET',
        textCapitalization: TextCapitalization.characters,
        confirmLabel: 'Hapus Permanen',
      ),
    );

    if (result == null || result.action != 'save') return;
    if (result.text.trim().toUpperCase() != 'RESET') {
      if (context.mounted) {
        _showSnack(context, 'Factory reset dibatalkan (konfirmasi tidak cocok).');
      }
      return;
    }

    await ref.read(backupControllerProvider.notifier).performFactoryReset();
    if (context.mounted) {
      _showSnack(context, 'Seluruh data lokal berhasil direset.');
    }
  }

  void _showPrivacySheet(BuildContext context, FitTraceColors colors) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'KEBIJAKAN PRIVASI — 100% LOCAL-ONLY',
                style: AppTypography.metricLabel(colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                'FitTrace beroperasi tanpa backend server dan tanpa pelacakan analitik.',
                style: Theme.of(sheetCtx).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                '• Seluruh data GPS, detak jantung, splits, dan file .FIT hanya disimpan lokal di SQLite perangkat Anda.\n'
                '• Kredensial & cookie Garmin hanya disimpan di Android Keystore / iOS Keychain dan tidak pernah masuk ke file backup atau log.\n'
                '• Data hanya dikirim keluar perangkat bila Anda sendiri menekan Bagikan ke Instagram Stories atau mengekspor file backup.',
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatShortDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year}';
  }

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.colors});

  final String text;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.metricLabel(colors.textSecondary));
  }
}

