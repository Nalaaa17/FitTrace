import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/garmin_session.dart';

/// Minimal key-value storage abstraction so encrypted storage can be cleanly
/// swapped with an in-memory fake in unit/widget tests.
abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Production backing store using Android Keystore / iOS Keychain (`M1-02`, `NFR-02`).
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory key-value store strictly for automated tests.
class InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

/// Encrypted persistence layer for Garmin cookies and session tokens (`M1-02`, `NFR-02`).
///
/// Cookies are never written to SQLite/Drift, app documents, or debug logs.
class SecureCookieStore {
  SecureCookieStore(this._store);

  static const String _sessionKey = 'fittrace_garmin_session_v1';
  static const Duration defaultAssumedTtl = Duration(days: 7);

  final SecureKeyValueStore _store;

  Future<GarminSessionBundle?> loadSession() async {
    try {
      final raw = await _store.read(_sessionKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final bundle = GarminSessionBundle.fromJson(decoded);
      if (bundle.isEmpty) return null;
      return bundle;
    } on Object catch (error) {
      AppLogger.warn('SecureCookieStore', 'Failed to load encrypted session', error);
      return null;
    }
  }

  Future<void> saveSession(GarminSessionBundle session) async {
    await _store.write(_sessionKey, session.toJsonString());
    AppLogger.info(
      'SecureCookieStore',
      'Saved encrypted Garmin session (${session.cookies.length} cookies)',
    );
  }

  /// Parses raw `Set-Cookie` headers into the encrypted session bundle.
  Future<GarminSessionBundle> mergeSetCookieHeaders({
    required Uri requestUri,
    required List<String> setCookieHeaders,
    String? csrfToken,
    String? bearerToken,
    DateTime? nowUtc,
  }) async {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final current = await loadSession() ??
        GarminSessionBundle(
          cookies: const <String, GarminCookieEntry>{},
          capturedAtUtc: now,
        );

    final updatedCookies = Map<String, GarminCookieEntry>.from(current.cookies);
    for (final rawHeader in setCookieHeaders) {
      final parsed = _parseSetCookieHeader(rawHeader, defaultDomain: requestUri.host, nowUtc: now);
      if (parsed == null) continue;
      if (parsed.value.isEmpty || parsed.isExpiredAt(now)) {
        updatedCookies.remove(parsed.name);
      } else {
        updatedCookies[parsed.name] = parsed;
      }
    }

    final next = current.copyWith(
      cookies: updatedCookies,
      csrfToken: csrfToken != null ? () => csrfToken : null,
      bearerToken: bearerToken != null ? () => bearerToken : null,
      lastValidatedAtUtc: () => now,
    );
    await saveSession(next);
    return next;
  }

  Future<void> markValidated(DateTime utcNow) async {
    final current = await loadSession();
    if (current == null) return;
    await saveSession(
      current.copyWith(lastValidatedAtUtc: () => utcNow.toUtc()),
    );
  }

  Future<void> clearSession() async {
    await _store.delete(_sessionKey);
    AppLogger.info('SecureCookieStore', 'Cleared encrypted Garmin session');
  }

  static GarminCookieEntry? _parseSetCookieHeader(
    String rawHeader, {
    required String defaultDomain,
    required DateTime nowUtc,
  }) {
    try {
      final cookie = Cookie.fromSetCookieValue(rawHeader);
      if (cookie.name.trim().isEmpty) return null;
      DateTime? expiresUtc = cookie.expires?.toUtc();
      if (expiresUtc == null && cookie.maxAge != null) {
        expiresUtc = nowUtc.add(Duration(seconds: cookie.maxAge!));
      }
      final rawDomain = cookie.domain?.trim();
      final effectiveDomain = (rawDomain != null &&
              rawDomain.isNotEmpty &&
              _isDomainMatch(defaultDomain, rawDomain))
          ? rawDomain
          : defaultDomain;
      return GarminCookieEntry(
        name: cookie.name.trim(),
        value: cookie.value,
        domain: effectiveDomain,
        path: cookie.path ?? '/',
        expiresAtUtc: expiresUtc,
        httpOnly: cookie.httpOnly,
        secure: cookie.secure,
      );
    } on Object {
      // Fall back to simple KEY=VALUE; ... parsing if Dart Cookie throws on odd attributes.
      final parts = rawHeader.split(';');
      if (parts.isEmpty) return null;
      final eqIndex = parts.first.indexOf('=');
      if (eqIndex <= 0) return null;
      final name = parts.first.substring(0, eqIndex).trim();
      final value = parts.first.substring(eqIndex + 1).trim();
      if (name.isEmpty) return null;
      DateTime? expiresUtc;
      var httpOnly = false;
      var secure = false;
      var path = '/';
      for (final attr in parts.skip(1)) {
        final trimmed = attr.trim();
        final lower = trimmed.toLowerCase();
        if (lower == 'httponly') {
          httpOnly = true;
        } else if (lower == 'secure') {
          secure = true;
        } else if (lower.startsWith('path=')) {
          path = trimmed.substring(5).trim();
        } else if (lower.startsWith('max-age=')) {
          final secs = int.tryParse(trimmed.substring(8).trim());
          if (secs != null) {
            expiresUtc = nowUtc.add(Duration(seconds: secs));
          }
        }
      }
      return GarminCookieEntry(
        name: name,
        value: value,
        domain: defaultDomain,
        path: path,
        expiresAtUtc: expiresUtc,
        httpOnly: httpOnly,
        secure: secure,
      );
    }
  }

  static bool _isDomainMatch(String requestHost, String cookieDomain) {
    final host = requestHost.toLowerCase();
    final domain = cookieDomain.toLowerCase().replaceFirst(RegExp(r'^\.'), '');
    return host == domain || host.endsWith('.$domain');
  }
}

