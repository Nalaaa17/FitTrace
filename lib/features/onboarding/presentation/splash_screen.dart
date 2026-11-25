import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../shell/presentation/main_shell_screen.dart';
import 'onboarding_screen.dart';

/// Monochrome splash screen (PRD §2.2: 800ms logo display).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.minimumDuration = const Duration(milliseconds: 400),
  });

  final Duration minimumDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.minimumDuration, _navigateNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    try {
      final prefs = await ref.read(appDatabaseProvider).getPreferences();
      if (!mounted) return;
      final destination = prefs.onboardingCompleted
          ? const MainShellScreen()
          : const OnboardingScreen();

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => destination),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _startupError = 'Gagal memuat basis data lokal: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  semanticLabel: 'Logo FitTrace',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'FITTRACE',
                style: AppTypography.heroDistance(colors.textPrimary).copyWith(
                  fontSize: 28,
                  letterSpacing: 3.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'LOCAL-FIRST RUNNING ANALYTICS',
                style: AppTypography.metricLabel(colors.textSecondary),
              ),
              if (_startupError != null) ...<Widget>[
                const SizedBox(height: 20),
                Text(
                  _startupError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.accentDanger, fontSize: 13),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => _startupError = null);
                    _navigateNext();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
