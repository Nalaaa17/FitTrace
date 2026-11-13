import 'package:flutter/foundation.dart';

/// Application logger that scrubs cookies, bearer tokens, and auth headers
/// before emitting any log message (PRD NFR-02).
class AppLogger {
  AppLogger._();

  static final List<RegExp> _secretPatterns = <RegExp>[
    RegExp(
      r'(GARMIN-SSO[^\s;=]*|SESSIONID|SESSION[^\s;=]*|JWT[^\s;=]*|CASTGC|DI-OAUTH2[^\s;=]*|connect-csrf-token)=([^\s;]+)',
      caseSensitive: false,
    ),
    RegExp(
      r'(Cookie|Set-Cookie|Authorization|X-CSRF-Token|connect-csrf-token)\s*:\s*([^\r\n]+)',
      caseSensitive: false,
    ),
    RegExp(
      r'"(access_token|refresh_token|id_token|session_token|cookie)"\s*:\s*"([^"]+)"',
      caseSensitive: false,
    ),
    RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
    RegExp(r'ticket=ST-[A-Za-z0-9\-]+', caseSensitive: false),
  ];

  /// Redacts sensitive credential fragments from [input].
  static String scrub(String input) {
    var sanitized = input;
    for (final pattern in _secretPatterns) {
      sanitized = sanitized.replaceAllMapped(pattern, (match) {
        if (match.groupCount >= 2 && match.group(1) != null) {
          return '${match.group(1)}=[REDACTED]';
        }
        return '[REDACTED]';
      });
    }
    return sanitized;
  }

  static void info(String tag, String message) {
    _emit('INFO', tag, message);
  }

  static void warn(String tag, String message, [Object? error]) {
    final suffix = error == null ? '' : ' | error: ${scrub(error.toString())}';
    _emit('WARN', tag, '$message$suffix');
  }

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final suffix = error == null ? '' : ' | error: ${scrub(error.toString())}';
    _emit('ERROR', tag, '$message$suffix');
    if (kDebugMode && stackTrace != null) {
      debugPrint(scrub(stackTrace.toString()));
    }
  }

  static void _emit(String level, String tag, String message) {
    if (!kDebugMode) return;
    debugPrint('[$level][$tag] ${scrub(message)}');
  }
}

