import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logging/app_logger.dart';

class BackupReminderDecision {
  const BackupReminderDecision({
    required this.isDue,
    this.daysSinceBackup,
    this.reason,
  });

  final bool isDue;
  final int? daysSinceBackup;
  final String? reason;
}

abstract interface class LocalNotificationDispatcher {
  Future<void> showMonthlyBackupReminder({
    required String title,
    required String body,
  });
}

class MethodChannelLocalNotificationDispatcher
    implements LocalNotificationDispatcher {
  const MethodChannelLocalNotificationDispatcher([
    this._channel = const MethodChannel('com.fittrace.app/notifications'),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> showMonthlyBackupReminder({
    required String title,
    required String body,
  }) async {
    try {
      await _channel.invokeMethod<bool>('showBackupReminder', <String, dynamic>{
        'title': title,
        'body': body,
      });
    } on MissingPluginException {
      // Ignored in tests or desktop hosts without mobile notification channel.
    } on PlatformException catch (error) {
      AppLogger.warn(
        'BackupReminder',
        'Failed invoking local backup reminder notification',
        error,
      );
    }
  }
}

/// Evaluates whether the monthly local backup reminder (`PRD M5-06`) is due
/// (> 30 days since `lastBackupAt` or since oldest activity when never backed up).
class BackupReminderService {
  BackupReminderService({
    required this.db,
    required this.notificationDispatcher,
    DateTime Function()? nowUtc,
  }) : _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const Duration backupMaxAge = Duration(days: 30);
  static const Duration snoozeInterval = Duration(days: 7);

  final AppDatabase db;
  final LocalNotificationDispatcher notificationDispatcher;
  final DateTime Function() _nowUtc;

  static BackupReminderDecision evaluate({
    required UserPreference prefs,
    required int activityCount,
    DateTime? oldestActivityCreatedAtUtc,
    DateTime? nowUtc,
  }) {
    if (!prefs.backupReminderEnabled || activityCount <= 0) {
      return const BackupReminderDecision(isDue: false);
    }

    final now = (nowUtc ?? DateTime.now()).toUtc();
    if (prefs.lastBackupReminderAt != null &&
        now.difference(prefs.lastBackupReminderAt!.toUtc()) < snoozeInterval) {
      return const BackupReminderDecision(isDue: false);
    }

    final reference =
        (prefs.lastBackupAt ?? oldestActivityCreatedAtUtc)?.toUtc();
    if (reference == null) {
      return const BackupReminderDecision(isDue: false);
    }

    final elapsed = now.difference(reference);
    if (elapsed <= backupMaxAge) {
      return BackupReminderDecision(
        isDue: false,
        daysSinceBackup: elapsed.inDays,
      );
    }

    final msg = prefs.lastBackupAt == null
        ? 'Anda belum pernah membuat backup ZIP dalam ${elapsed.inDays} hari terakhir.'
        : 'Backup lokal terakhir sudah ${elapsed.inDays} hari yang lalu.';
    return BackupReminderDecision(
      isDue: true,
      daysSinceBackup: elapsed.inDays,
      reason: msg,
    );
  }

  Future<BackupReminderDecision> checkAndNotifyIfDue() async {
    final prefs = await db.getPreferences();
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS cnt, MIN(created_at) AS oldest FROM activities;',
        )
        .getSingle();

    final count = row.read<int>('cnt');
    final oldestRaw = row.readNullable<DateTime>('oldest');
    final decision = evaluate(
      prefs: prefs,
      activityCount: count,
      oldestActivityCreatedAtUtc: oldestRaw,
      nowUtc: _nowUtc(),
    );

    if (decision.isDue && decision.reason != null) {
      await notificationDispatcher.showMonthlyBackupReminder(
        title: 'Waktunya Backup Data Lari',
        body: '${decision.reason} Simpan arsip ZIP agar riwayat tetap aman.',
      );
    }
    return decision;
  }

  Future<void> snoozeReminder() {
    return db.updatePreferences(
      UserPreferencesTableCompanion(
        lastBackupReminderAt: Value(_nowUtc()),
      ),
    );
  }
}

