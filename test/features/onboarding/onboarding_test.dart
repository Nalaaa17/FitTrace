import 'package:drift/native.dart';
import 'package:fit_trace/app.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/core/database/database_provider.dart';
import 'package:fit_trace/features/onboarding/presentation/splash_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigates splash -> onboarding -> main shell and persists flag', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const FitTraceApp(
            home: SplashScreen(minimumDuration: Duration(milliseconds: 50)),
          ),
        ),
      );

      expect(find.text('FITTRACE'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();

      expect(find.text('Privasi Lokal Penuh'), findsOneWidget);

      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      expect(find.text('BELUM ADA AKTIVITAS LARI'), findsOneWidget);
      final prefs = await db.getPreferences();
      expect(prefs.onboardingCompleted, isTrue);
    } finally {
      // Unmount ProviderScope and flush Drift's zero-duration stream cleanup timer.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.runAsync(db.close);
    }
  });
}
