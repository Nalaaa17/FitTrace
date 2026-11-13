import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Singleton Drift database provider for the application lifecycle.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Reactive singleton preferences stream backed by SQLite `user_preferences`.
final userPreferencesProvider = StreamProvider<UserPreference>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchPreferences();
});

/// Maps persisted `themeMode` string (`dark` | `light` | `system`) to [ThemeMode].
ThemeMode parseThemeMode(String? rawMode) {
  switch (rawMode) {
    case 'light':
      return ThemeMode.light;
    case 'system':
      return ThemeMode.system;
    case 'dark':
    default:
      return ThemeMode.dark;
  }
}

