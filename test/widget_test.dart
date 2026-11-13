import 'package:drift/native.dart';
import 'package:fit_trace/app.dart';
import 'package:fit_trace/core/database/app_database.dart';
import 'package:fit_trace/core/database/database_provider.dart';
import 'package:fit_trace/features/shell/presentation/main_shell_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders 3-tab monochrome shell and updates settings in SQLite', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const FitTraceApp(home: MainShellScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Feed tab is initially visible with empty state CTA.
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('BELUM ADA AKTIVITAS LARI'), findsOneWidget);

      // Switch to Stats tab.
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.text('Statistik'), findsOneWidget);
      expect(find.text('TOTAL JARAK MINGGU INI'), findsOneWidget);

      // Switch to Settings tab and verify ADR-003 toggles & theme change.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Izinkan Data Seluler'), findsOneWidget);
      expect(find.text('Izinkan Tanpa Charging'), findsOneWidget);

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      final updated = await db.getPreferences();
      expect(updated.themeMode, 'light');
    } finally {
      // Unmount ProviderScope and flush Drift's zero-duration stream cleanup timer.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.runAsync(db.close);
    }
  });
}
