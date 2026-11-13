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
    this.minimumDuration = const Duration(milliseconds: 800),
  });

  final Duration minimumDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

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
    final prefs = await ref.read(appDatabaseProvider).getPreferences();
    if (!mounted) return;
    final destination = prefs.onboardingCompleted
        ? const MainShellScreen()
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.route_rounded,
              size: 48,
              color: colors.accentSharp,
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
          ],
        ),
      ),
    );
  }
}

