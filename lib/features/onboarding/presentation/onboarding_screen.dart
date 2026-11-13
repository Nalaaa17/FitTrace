import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../garmin_sync/application/garmin_sync_providers.dart';
import '../../garmin_sync/data/runtime_permission_service.dart';
import '../../garmin_sync/presentation/garmin_webview_login_screen.dart';
import '../../shell/presentation/main_shell_screen.dart';

/// Complete 3-page monochrome onboarding carousel + non-blocking runtime
/// permissions + Garmin Connect login or Manual Import Only mode (`PRD §2.2`).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showSetupStep = false;
  bool _isRequestingPermissions = false;
  RuntimePermissionsSnapshot? _permissions;

  static const List<({IconData icon, String title, String subtitle})> _pages =
      <({IconData icon, String title, String subtitle})>[
    (
      icon: Icons.lock_outline_rounded,
      title: 'Privasi Lokal Penuh',
      subtitle:
          'Seluruh data GPS, detak jantung, dan file .FIT tersimpan lokal di perangkat Anda tanpa server pihak ketiga.',
    ),
    (
      icon: Icons.show_chart_rounded,
      title: 'Analisis Lari Garmin',
      subtitle:
          'Parser .FIT native menghitung moving time, split per kilometer, elevasi, dan zona detak jantung 1–5.',
    ),
    (
      icon: Icons.auto_awesome_mosaic_outlined,
      title: 'Bagikan ke Story',
      subtitle:
          'Buat kartu statistik 9:16 monokrom dan kirim langsung ke Instagram Stories tanpa feed sosial.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _enterSetupStep() async {
    setState(() => _showSetupStep = true);
    final snapshot =
        await ref.read(runtimePermissionServiceProvider).checkAll();
    if (mounted) {
      setState(() => _permissions = snapshot);
    }
  }

  Future<void> _requestOptionalPermissions() async {
    if (_isRequestingPermissions) return;
    setState(() => _isRequestingPermissions = true);
    final updated = await ref
        .read(runtimePermissionServiceProvider)
        .requestOptionalPermissions();
    if (!mounted) return;
    setState(() {
      _permissions = updated;
      _isRequestingPermissions = false;
    });
  }

  Future<void> _completeManualMode() async {
    final db = ref.read(appDatabaseProvider);
    await db.updatePreferences(
      const UserPreferencesTableCompanion(
        onboardingCompleted: Value(true),
        garminLoggedIn: Value(false),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShellScreen()),
    );
  }

  Future<void> _openGarminLogin() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const GarminWebViewLoginScreen(),
      ),
    );
    if (loggedIn != true || !mounted) return;

    final db = ref.read(appDatabaseProvider);
    await db.updatePreferences(
      const UserPreferencesTableCompanion(
        onboardingCompleted: Value(true),
        garminLoggedIn: Value(true),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const MainShellScreen(triggerInitialSync: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          child: _showSetupStep
              ? _buildSetupStep(context, colors)
              : _buildCarouselStep(context, colors),
        ),
      ),
    );
  }

  Widget _buildCarouselStep(BuildContext context, FitTraceColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _completeManualMode,
            child: Text(
              'Lewati',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.hairlineBorder),
                      ),
                      child: Icon(
                        page.icon,
                        size: 36,
                        color: colors.accentSharp,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      page.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      page.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(_pages.length, (index) {
            final active = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: active ? 22 : 6,
              decoration: BoxDecoration(
                color: active ? colors.accentSharp : colors.hairlineBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            if (_currentPage < _pages.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            } else {
              _enterSetupStep();
            }
          },
          child: Text(
            _currentPage < _pages.length - 1 ? 'Lanjut' : 'Mulai Pengaturan',
          ),
        ),
      ],
    );
  }

  Widget _buildSetupStep(BuildContext context, FitTraceColors colors) {
    final perms = _permissions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              tooltip: 'Kembali',
              onPressed: () => setState(() => _showSetupStep = false),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            TextButton(
              onPressed: _completeManualMode,
              child: Text(
                'Lewati',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: <Widget>[
              Text(
                'IZIN & KONEKSI AKUN',
                style: AppTypography.metricLabel(colors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Hubungkan Garmin Connect atau Impor Manual',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Semua izin bersifat opsional agar aplikasi tetap dapat digunakan secara offline kapan pun.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'IZIN RUNTIME (OPSIONAL)',
                        style: AppTypography.metricLabel(colors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      _PermissionRow(
                        icon: Icons.location_on_outlined,
                        title: 'Lokasi',
                        subtitle: 'Opsional saat memproses rute & zona waktu lokal.',
                        granted: perms?.locationGranted ?? false,
                        colors: colors,
                      ),
                      const Divider(height: 20),
                      _PermissionRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifikasi',
                        subtitle: 'Status progres sinkronisasi Garmin di latar belakang.',
                        granted: perms?.notificationGranted ?? false,
                        colors: colors,
                      ),
                      const Divider(height: 20),
                      _PermissionRow(
                        icon: Icons.folder_open_outlined,
                        title: 'Penyimpanan (Android <= 12)',
                        subtitle: 'Untuk membaca file .FIT dari folder unduhan.',
                        granted: perms?.storageGranted ?? false,
                        colors: colors,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _isRequestingPermissions
                            ? null
                            : _requestOptionalPermissions,
                        icon: const Icon(Icons.verified_user_outlined, size: 18),
                        label: Text(
                          _isRequestingPermissions
                              ? 'Meminta Izin...'
                              : 'Berikan Izin Opsional',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _openGarminLogin,
          icon: const Icon(Icons.watch_rounded, size: 18),
          label: const Text('Login Garmin Connect'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _completeManualMode,
          child: const Text('Lewati — Mode Import Manual Only'),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final FitTraceColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: colors.accentSharp),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.chartAxis(colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          granted ? 'AKTIF' : 'OPSIONAL',
          style: AppTypography.chartAxis(
            granted ? colors.accentSharp : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
