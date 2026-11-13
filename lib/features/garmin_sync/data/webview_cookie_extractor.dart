import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/garmin_session.dart';

/// Reads WebView cookies (including `HttpOnly` session cookies on Android via
/// native `CookieManager`) without logging any sensitive values (`NFR-02`).
abstract interface class WebViewCookieExtractor {
  Future<GarminSessionBundle> extractGarminSession({
    Future<String?> Function()? jsCookieFallback,
  });

  Future<void> clearAllWebViewCookies();
}

class MethodChannelWebViewCookieExtractor implements WebViewCookieExtractor {
  MethodChannelWebViewCookieExtractor({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'com.fittrace.app/webview_cookies';

  static const List<String> garminCookieUrls = <String>[
    'https://connect.garmin.com',
    'https://connect.garmin.com/modern',
    'https://sso.garmin.com',
  ];

  final MethodChannel _channel;

  @override
  Future<GarminSessionBundle> extractGarminSession({
    Future<String?> Function()? jsCookieFallback,
  }) async {
    final now = DateTime.now().toUtc();
    final cookies = <String, GarminCookieEntry>{};

    try {
      final rawMap = await _channel.invokeMapMethod<String, String>(
        'getCookies',
        <String, Object?>{'urls': garminCookieUrls},
      );
      if (rawMap != null) {
        for (final entry in rawMap.entries) {
          final uri = Uri.tryParse(entry.key);
          final domain = uri?.host ?? '.garmin.com';
          _parseCookieHeaderIntoMap(
            entry.value,
            cookies: cookies,
            domain: domain,
            httpOnly: true,
          );
        }
      }
    } on MissingPluginException {
      AppLogger.info(
        'WebViewCookieExtractor',
        'Native cookie channel unavailable; falling back to JS reader',
      );
    } on PlatformException catch (error) {
      AppLogger.warn('WebViewCookieExtractor', 'Cookie channel failed', error);
    }

    if (jsCookieFallback != null) {
      try {
        final rawJsCookies = await jsCookieFallback();
        if (rawJsCookies != null && rawJsCookies.trim().isNotEmpty) {
          final cleaned = _stripWrappingQuotes(rawJsCookies.trim());
          _parseCookieHeaderIntoMap(
            cleaned,
            cookies: cookies,
            domain: '.garmin.com',
            httpOnly: false,
          );
        }
      } on Object catch (error) {
        AppLogger.warn('WebViewCookieExtractor', 'JS cookie read failed', error);
      }
    }

    return GarminSessionBundle(
      cookies: cookies,
      capturedAtUtc: now,
      lastValidatedAtUtc: now,
    );
  }

  @override
  Future<void> clearAllWebViewCookies() async {
    try {
      if (WebViewPlatform.instance != null) {
        await WebViewCookieManager().clearCookies();
      }
    } on Object catch (error) {
      AppLogger.warn('WebViewCookieExtractor', 'Failed clearing WebView cookies', error);
    }
  }

  static bool looksAuthenticated(GarminSessionBundle bundle) {
    if (bundle.bearerToken != null && bundle.bearerToken!.isNotEmpty) {
      return true;
    }
    const authCookieNames = <String>{
      'SESSIONID',
      'SESSION',
      'GARMIN-SSO',
      'GARMIN-SSO-GUID',
      'GARMIN-SSO-CUST-GUID',
      'JWT_FGP',
      'JWT',
      'CASTGC',
      'DI-OAUTH2-TOKEN',
    };
    for (final name in bundle.cookies.keys) {
      if (authCookieNames.contains(name.toUpperCase())) {
        return true;
      }
    }
    return false;
  }

  static void _parseCookieHeaderIntoMap(
    String cookieHeader, {
    required Map<String, GarminCookieEntry> cookies,
    required String domain,
    required bool httpOnly,
  }) {
    final segments = cookieHeader.split(';');
    for (final segment in segments) {
      final trimmed = segment.trim();
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex <= 0) continue;
      final name = trimmed.substring(0, eqIndex).trim();
      final value = trimmed.substring(eqIndex + 1).trim();
      if (name.isEmpty || value.isEmpty) continue;
      cookies[name] = GarminCookieEntry(
        name: name,
        value: value,
        domain: domain,
        httpOnly: httpOnly,
        secure: true,
      );
    }
  }

  static String _stripWrappingQuotes(String input) {
    if (input.length >= 2 &&
        ((input.startsWith('"') && input.endsWith('"')) ||
            (input.startsWith("'") && input.endsWith("'")))) {
      return input.substring(1, input.length - 1);
    }
    return input;
  }
}

