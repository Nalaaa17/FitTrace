import 'dart:convert';

import 'package:metrics_engine/metrics_engine.dart';

/// Authentication and session status of Garmin Connect integration.
enum GarminAuthStatus {
  disconnected,
  connected,
  reloginRequired,
  challengeRequired,
}

/// Single HTTP cookie persisted inside encrypted storage (`M1-02`).
class GarminCookieEntry {
  const GarminCookieEntry({
    required this.name,
    required this.value,
    this.domain = '.garmin.com',
    this.path = '/',
    this.expiresAtUtc,
    this.httpOnly = true,
    this.secure = true,
  });

  factory GarminCookieEntry.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['expiresAtUtc'] as String?;
    return GarminCookieEntry(
      name: json['name'] as String,
      value: json['value'] as String,
      domain: (json['domain'] as String?) ?? '.garmin.com',
      path: (json['path'] as String?) ?? '/',
      expiresAtUtc: expiresRaw != null ? DateTime.tryParse(expiresRaw)?.toUtc() : null,
      httpOnly: (json['httpOnly'] as bool?) ?? true,
      secure: (json['secure'] as bool?) ?? true,
    );
  }

  final String name;
  final String value;
  final String domain;
  final String path;
  final DateTime? expiresAtUtc;
  final bool httpOnly;
  final bool secure;

  bool isExpiredAt(DateTime utcNow) =>
      expiresAtUtc != null && !utcNow.isBefore(expiresAtUtc!);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'value': value,
        'domain': domain,
        'path': path,
        if (expiresAtUtc != null) 'expiresAtUtc': expiresAtUtc!.toIso8601String(),
        'httpOnly': httpOnly,
        'secure': secure,
      };

  @override
  String toString() => 'GarminCookieEntry(name: $name, domain: $domain)';
}

/// Encrypted session state persisted strictly in `flutter_secure_storage` (`M1-02`).
class GarminSessionBundle {
  const GarminSessionBundle({
    required this.cookies,
    this.csrfToken,
    this.bearerToken,
    required this.capturedAtUtc,
    this.lastValidatedAtUtc,
  });

  factory GarminSessionBundle.fromJson(Map<String, dynamic> json) {
    final rawCookies = json['cookies'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final parsedCookies = <String, GarminCookieEntry>{};
    for (final entry in rawCookies.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        parsedCookies[entry.key] = GarminCookieEntry.fromJson(value);
      }
    }
    return GarminSessionBundle(
      cookies: parsedCookies,
      csrfToken: json['csrfToken'] as String?,
      bearerToken: json['bearerToken'] as String?,
      capturedAtUtc: DateTime.parse(json['capturedAtUtc'] as String).toUtc(),
      lastValidatedAtUtc: (json['lastValidatedAtUtc'] as String?) != null
          ? DateTime.tryParse(json['lastValidatedAtUtc'] as String)?.toUtc()
          : null,
    );
  }

  final Map<String, GarminCookieEntry> cookies;
  final String? csrfToken;
  final String? bearerToken;
  final DateTime capturedAtUtc;
  final DateTime? lastValidatedAtUtc;

  bool get isEmpty => cookies.isEmpty && (bearerToken == null || bearerToken!.isEmpty);

  /// Builds an RFC `Cookie` header matching [targetUri.host], excluding expired cookies.
  String buildCookieHeader(Uri targetUri, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final host = targetUri.host.toLowerCase();
    final pairs = <String>[];

    for (final entry in cookies.values) {
      if (entry.isExpiredAt(now)) continue;
      if (entry.secure && targetUri.scheme != 'https') continue;
      if (!_domainMatches(host, entry.domain)) continue;
      pairs.add('${entry.name}=${entry.value}');
    }
    return pairs.join('; ');
  }

  static bool _domainMatches(String host, String cookieDomain) {
    final normalized = cookieDomain.toLowerCase().replaceFirst(RegExp(r'^\.'), '');
    if (normalized.isEmpty) return true;
    return host == normalized || host.endsWith('.$normalized');
  }

  GarminSessionBundle copyWith({
    Map<String, GarminCookieEntry>? cookies,
    String? Function()? csrfToken,
    String? Function()? bearerToken,
    DateTime? capturedAtUtc,
    DateTime? Function()? lastValidatedAtUtc,
  }) {
    return GarminSessionBundle(
      cookies: cookies ?? this.cookies,
      csrfToken: csrfToken != null ? csrfToken() : this.csrfToken,
      bearerToken: bearerToken != null ? bearerToken() : this.bearerToken,
      capturedAtUtc: capturedAtUtc ?? this.capturedAtUtc,
      lastValidatedAtUtc:
          lastValidatedAtUtc != null ? lastValidatedAtUtc() : this.lastValidatedAtUtc,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cookies': cookies.map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        if (csrfToken != null) 'csrfToken': csrfToken,
        if (bearerToken != null) 'bearerToken': bearerToken,
        'capturedAtUtc': capturedAtUtc.toIso8601String(),
        if (lastValidatedAtUtc != null)
          'lastValidatedAtUtc': lastValidatedAtUtc!.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  /// Deliberately omits cookie and token values to prevent accidental leaks (`NFR-02`).
  @override
  String toString() =>
      'GarminSessionBundle(cookies: ${cookies.length}, hasBearer: ${bearerToken != null})';
}

/// Summary metadata item returned by Garmin Connect `activitylist-service`.
class GarminActivitySummary {
  const GarminActivitySummary({
    required this.activityId,
    required this.activityName,
    required this.startTimeUtc,
    required this.sportType,
    this.distanceMeters = 0,
    this.durationTotalSec = 0,
    this.updatedAtUtc,
  });

  factory GarminActivitySummary.fromGarminJson(Map<String, dynamic> json) {
    final rawId = json['activityId'];
    final activityId = rawId is int ? rawId : int.parse(rawId.toString());
    final name = (json['activityName'] as String?)?.trim();
    final activityTypeMap = json['activityType'] as Map<String, dynamic>?;
    final typeKey = (activityTypeMap?['typeKey'] as String?)?.toLowerCase() ?? '';

    final sport = _mapSportType(typeKey);
    final startUtc = _parseGarminTimestamp(
      beginTimestampMs: json['beginTimestamp'],
      gmtString: json['startTimeGMT'] as String?,
    );
    final updatedUtc = _parseGarminTimestamp(
      beginTimestampMs: json['updateDate'] ?? json['lastUpdateDate'],
      gmtString: (json['updateDate'] ?? json['lastUpdateDate'])?.toString(),
    );

    final rawDistance = json['distance'];
    final distanceM = rawDistance is num ? rawDistance.toDouble() : 0.0;
    final rawDuration = json['duration'];
    final durationSec = rawDuration is num ? rawDuration.round() : 0;

    return GarminActivitySummary(
      activityId: activityId,
      activityName: (name != null && name.isNotEmpty) ? name : 'Garmin Run #$activityId',
      startTimeUtc: startUtc ?? DateTime.now().toUtc(),
      sportType: sport,
      distanceMeters: distanceM,
      durationTotalSec: durationSec,
      updatedAtUtc: updatedUtc,
    );
  }

  final int activityId;
  final String activityName;
  final DateTime startTimeUtc;
  final SportType sportType;
  final double distanceMeters;
  final int durationTotalSec;
  final DateTime? updatedAtUtc;

  static SportType _mapSportType(String typeKey) {
    if (typeKey.contains('trail')) return SportType.trailRun;
    if (typeKey.contains('treadmill') || typeKey.contains('indoor')) {
      return SportType.treadmill;
    }
    if (typeKey.contains('run') || typeKey.contains('track')) {
      return SportType.run;
    }
    return SportType.other;
  }

  static DateTime? _parseGarminTimestamp({
    Object? beginTimestampMs,
    String? gmtString,
  }) {
    if (beginTimestampMs is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        beginTimestampMs.round(),
        isUtc: true,
      );
    }
    if (gmtString != null && gmtString.trim().isNotEmpty) {
      final normalized = gmtString.trim().replaceFirst(' ', 'T');
      final withUtc = normalized.endsWith('Z') || normalized.contains('+')
          ? normalized
          : '${normalized}Z';
      return DateTime.tryParse(withUtc)?.toUtc();
    }
    return null;
  }
}

/// Thrown when Cloudflare or a CAPTCHA challenge blocks automated sync,
/// signaling the UI to prompt the user-resolvable WebView.
class GarminChallengeException implements Exception {
  const GarminChallengeException([
    this.message =
        'Garmin meminta verifikasi keamanan (CAPTCHA/Cloudflare). Silakan selesaikan lewat browser login.',
  ]);

  final String message;

  @override
  String toString() => 'GarminChallengeException: $message';
}

/// Summary returned after completing a Garmin Connect sync pass (PRD §2.3 step 5).
class SyncResult {
  const SyncResult({
    required this.importedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.failedCount,
    required this.syncedAtUtc,
    this.abortedReason,
  });

  final int importedCount;
  final int updatedCount;
  final int skippedCount;
  final int failedCount;
  final DateTime syncedAtUtc;
  final String? abortedReason;

  String get summaryBannerText {
    final base = '$importedCount aktivitas baru • '
        '$updatedCount diperbarui • '
        '$skippedCount dilewati';
    if (failedCount > 0) {
      return '$base • $failedCount gagal';
    }
    return base;
  }
}

