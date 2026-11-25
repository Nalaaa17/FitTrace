import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/garmin_session_refresher.dart';
import 'garmin_dio_client.dart';
import 'secure_cookie_store.dart';
import 'webview_cookie_extractor.dart';

/// Attempts a single headless WebView refresh of Garmin Connect cookies (`M1-04`).
///
/// If Garmin shows `/signin` or an interactive CAPTCHA/Cloudflare challenge,
/// this immediately aborts and delegates back to user-resolvable WebView login.
class WebViewSilentSessionRefresher implements GarminSessionRefresher {
  WebViewSilentSessionRefresher({
    required this.cookieStore,
    required this.cookieExtractor,
    this.timeout = const Duration(seconds: 10),
  });

  static const String _refreshUrl = 'https://connect.garmin.com/modern/';

  final SecureCookieStore cookieStore;
  final WebViewCookieExtractor cookieExtractor;
  final Duration timeout;

  @override
  Future<RefreshOutcome> attemptSilentRefresh() async {
    final session = await cookieStore.loadSession();
    if (session != null && session.isPersonalApi) {
      try {
        final token = await DioGarminConnectClient.exchangePersonalApiKey(session.personalApiKey!);
        final updated = session.copyWith(
          bearerToken: () => token,
          lastValidatedAtUtc: () => DateTime.now().toUtc(),
        );
        await cookieStore.saveSession(updated);
        AppLogger.info('WebViewSilentSessionRefresher', 'Personal API token refreshed successfully');
        return RefreshOutcome.refreshed;
      } on Object catch (e) {
        AppLogger.warn('WebViewSilentSessionRefresher', 'Failed to refresh Personal API token', e);
        return RefreshOutcome.expiredOrLoginRequired;
      }
    }

    if (WebViewPlatform.instance == null) {
      return RefreshOutcome.failed;
    }

    final completer = Completer<RefreshOutcome>();
    Timer? guardTimer;

    void finish(RefreshOutcome outcome) {
      guardTimer?.cancel();
      if (!completer.isCompleted) {
        completer.complete(outcome);
      }
    }

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);

      guardTimer = Timer(timeout, () => finish(RefreshOutcome.failed));

      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || uri.scheme.toLowerCase() != 'https') {
              return NavigationDecision.prevent;
            }
            if (_isChallengeUrl(request.url.toLowerCase())) {
              finish(RefreshOutcome.challengeRequired);
              return NavigationDecision.prevent;
            }
            if (!_isAllowedGarminHost(uri.host)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) async {
            if (completer.isCompleted) return;
            final uri = Uri.tryParse(url);
            if (uri == null || uri.scheme.toLowerCase() != 'https') return;
            final host = uri.host.toLowerCase();
            final lower = url.toLowerCase();
            if (_isChallengeUrl(lower)) {
              finish(RefreshOutcome.challengeRequired);
              return;
            }
            if (host == 'sso.garmin.com' || lower.contains('/signin')) {
              finish(RefreshOutcome.expiredOrLoginRequired);
              return;
            }
            if (host == 'connect.garmin.com') {
              final extracted = await cookieExtractor.extractGarminSession(
                jsCookieFallback: () async {
                  final raw = await controller
                      .runJavaScriptReturningResult('document.cookie');
                  return raw.toString();
                },
              );
              if (MethodChannelWebViewCookieExtractor.looksAuthenticated(
                extracted,
              )) {
                await cookieStore.saveSession(extracted);
                finish(RefreshOutcome.refreshed);
              } else {
                finish(RefreshOutcome.expiredOrLoginRequired);
              }
            }
          },
          onWebResourceError: (error) {
            AppLogger.warn(
              'SilentRefresh',
              'Headless refresh resource error: ${error.description}',
            );
          },
        ),
      );

      await controller.loadRequest(Uri.parse(_refreshUrl));
      return await completer.future;
    } on Object catch (error) {
      guardTimer?.cancel();
      AppLogger.warn('SilentRefresh', 'Silent refresh aborted', error);
      return RefreshOutcome.failed;
    }
  }

  static bool _isAllowedGarminHost(String host) {
    final lower = host.toLowerCase();
    return lower == 'garmin.com' || lower.endsWith('.garmin.com');
  }

  static bool _isChallengeUrl(String lowerUrl) =>
      lowerUrl.contains('/cdn-cgi/challenge') ||
      lowerUrl.contains('captcha') ||
      lowerUrl.contains('turnstile');
}
