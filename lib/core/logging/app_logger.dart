import 'package:flutter/foundation.dart';

/// Application logger that scrubs cookies, bearer tokens, API keys, and auth
/// headers before emitting or retaining any diagnostic entry (PRD NFR-02).
class AppLogger {
  AppLogger._();

  static const int _maxRetainedEntries = 200;
  static final List<String> _recentDiagnostics = <String>[];

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
    RegExp(r'ApiKey\s+[^\s"]+', caseSensitive: false),
    RegExp(r'GCDC_[^\s"]+', caseSensitive: false),
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

  /// Recent scrubbed WARN/ERROR diagnostic entries (retained in-memory even in
  /// release builds so local crash/sync diagnostics can be inspected offline).
  static List<String> get recentDiagnostics =>
      List<String>.unmodifiable(_recentDiagnostics);

  static String exportDiagnosticsText() => _recentDiagnostics.join('\n');

  static void clearDiagnostics() => _recentDiagnostics.clear();

  static void info(String tag, String message) {
    _emit('INFO', tag, message, retain: false);
  }

  static void warn(String tag, String message, [Object? error]) {
    final suffix = error == null ? '' : ' | error: ${scrub(error.toString())}';
    _emit('WARN', tag, '$message$suffix', retain: true);
  }

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final suffix = error == null ? '' : ' | error: ${scrub(error.toString())}';
    _emit('ERROR', tag, '$message$suffix', retain: true);
    if (stackTrace != null) {
      final scrubbedStack = scrub(stackTrace.toString());
      _appendDiagnostic(scrubbedStack);
      if (kDebugMode) {
        debugPrint(scrubbedStack);
      }
    }
  }

  static void _emit(
    String level,
    String tag,
    String message, {
    required bool retain,
  }) {
    final formatted = '[$level][$tag] ${scrub(message)}';
    if (retain) {
      final ts = DateTime.now().toUtc().toIso8601String();
      _appendDiagnostic('$ts $formatted');
    }
    if (!kDebugMode) return;
    debugPrint(formatted);
  }

  static void _appendDiagnostic(String entry) {
    _recentDiagnostics.add(entry);
    if (_recentDiagnostics.length > _maxRetainedEntries) {
      _recentDiagnostics.removeRange(
        0,
        _recentDiagnostics.length - _maxRetainedEntries,
      );
    }
  }
}
