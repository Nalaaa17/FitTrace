import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/splash_screen.dart';
import 'l10n/app_localizations.dart';

class FitTraceApp extends ConsumerWidget {
  const FitTraceApp({
    super.key,
    this.home,
  });

  /// Optional test hook to bypass the splash timer in widget tests.
  final Widget? home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesProvider);
    final themeMode = parseThemeMode(prefsAsync.value?.themeMode);

    return MaterialApp(
      title: 'FitTrace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: home ?? const SplashScreen(),
    );
  }
}
