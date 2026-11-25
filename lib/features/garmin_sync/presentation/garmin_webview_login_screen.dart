import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../application/garmin_sync_providers.dart';
import '../data/webview_cookie_extractor.dart';

/// Embedded user-resolvable Garmin Connect SSO WebView (`M1-01`).
///
/// Handles standard sign-in, 2FA/MFA, AND any interactive Cloudflare/CAPTCHA
/// challenge completed directly by the user in the visible WebView UI.
/// Cookies are only saved to `flutter_secure_storage` if the session probe
/// succeeds (`PRD §2.2`).
class GarminWebViewLoginScreen extends ConsumerStatefulWidget {
  const GarminWebViewLoginScreen({
    super.key,
    this.isChallengeFallback = false,
    this.initialUrl = defaultLoginUrl,
  });

  static const String defaultLoginUrl =
      'https://sso.garmin.com/portal/sso/en-US/sign-in?clientId=GarminConnect&service=https%3A%2F%2Fconnect.garmin.com%2Fmodern%2F';
  static const String ssoAccountPortalUrl =
      'https://sso.garmin.com/portal/sso/en-US/sign-in?clientId=ACCOUNT_MANAGEMENT_CENTER&service=https%3A%2F%2Fwww.garmin.com%2Fen-US%2Faccount%2F';
  static const String challengeRecoveryUrl = 'https://connect.garmin.com/modern/';

  final bool isChallengeFallback;
  final String initialUrl;

  @override
  ConsumerState<GarminWebViewLoginScreen> createState() =>
      _GarminWebViewLoginScreenState();
}

class _GarminWebViewLoginScreenState
    extends ConsumerState<GarminWebViewLoginScreen> {
  WebViewController? _controller;
  double _progress = 0;
  bool _isVerifying = false;
  String? _errorBanner;
  bool _platformSupported = true;
  bool _autoCaptureTriggered = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    if (WebViewPlatform.instance == null) {
      _platformSupported = false;
      return;
    }

    final candidateUrl = widget.isChallengeFallback &&
            widget.initialUrl == GarminWebViewLoginScreen.defaultLoginUrl
        ? GarminWebViewLoginScreen.challengeRecoveryUrl
        : widget.initialUrl;
    final initialUri = Uri.tryParse(candidateUrl);
    final safeUri = (initialUri != null &&
            initialUri.scheme.toLowerCase() == 'https' &&
            _isAllowedAuthHost(initialUri.host))
        ? initialUri
        : Uri.parse(GarminWebViewLoginScreen.defaultLoginUrl);

    final controller = WebViewController()
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || uri.scheme.toLowerCase() != 'https') {
              return NavigationDecision.prevent;
            }
            if (!_isAllowedAuthHost(uri.host)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress / 100.0);
          },
          onPageFinished: (url) async {
            await _handlePageFinished(url);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            AppLogger.warn(
              'GarminWebViewLogin',
              'WebView resource error: ${error.description}',
            );
          },
        ),
      );

    _controller = controller;
    controller.loadRequest(safeUri);
  }

  static bool _isAllowedAuthHost(String host) {
    final lower = host.toLowerCase();
    return lower == 'garmin.com' ||
        lower.endsWith('.garmin.com') ||
        lower.endsWith('.cloudflare.com') ||
        lower == 'challenges.cloudflare.com' ||
        lower.endsWith('.hcaptcha.com') ||
        lower.endsWith('.recaptcha.net');
  }

  Future<void> _handlePageFinished(String url) async {
    if (!mounted || _isVerifying || _autoCaptureTriggered) return;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.toLowerCase() != 'https') return;
    final host = uri.host.toLowerCase();
    final lower = url.toLowerCase();

    if (host == 'www.garmin.com' &&
        !lower.contains('/signin') &&
        !lower.contains('/login') &&
        !lower.contains('/sign-in') &&
        !lower.contains('/portal/sso')) {
      // Sesi SSO Garmin Account Management berhasil, arahkan ke Garmin Connect
      // agar tiket sesi Connect langsung aktif.
      _controller?.loadRequest(Uri.parse('https://connect.garmin.com/modern/'));
      return;
    }

    final isAuthenticatedLanding =
        host == 'connect.garmin.com' &&
            !lower.contains('/signin') &&
            !lower.contains('/login') &&
            !lower.contains('/sign-in') &&
            !lower.contains('/portal/sso') &&
            !lower.contains('/cdn-cgi/challenge') &&
            !lower.contains('captcha');

    if (isAuthenticatedLanding) {
      _autoCaptureTriggered = true;
      await _verifyCapturedSession(silentOnIncomplete: true);
    }
  }

  static String? _decodeJsStringResult(Object? raw) {
    if (raw == null) return null;
    final rawStr = raw.toString().trim();
    if (rawStr.isEmpty || rawStr == 'null') return null;
    try {
      final decoded = jsonDecode(rawStr);
      if (decoded is String) {
        final trimmed = decoded.trim();
        return (trimmed.isEmpty || trimmed == 'null') ? null : trimmed;
      }
    } on Object {
      // Fallback for platforms returning unquoted string directly.
    }
    return rawStr;
  }

  Future<void> _verifyCapturedSession({bool silentOnIncomplete = false}) async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _errorBanner = null;
    });

    try {
      final extractor = ref.read(webViewCookieExtractorProvider);
      final session = await extractor.extractGarminSession(
        jsCookieFallback: () async {
          final ctrl = _controller;
          if (ctrl == null) return null;
          final raw = await ctrl.runJavaScriptReturningResult('document.cookie');
          return raw.toString();
        },
      );

      if (session.isEmpty ||
          !MethodChannelWebViewCookieExtractor.looksAuthenticated(session)) {
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
          _autoCaptureTriggered = false;
          if (!silentOnIncomplete) {
            _errorBanner =
                'Sesi login Garmin belum terdeteksi. Pastikan Anda sudah masuk hingga halaman dashboard Connect terbuka.';
          }
        });
        return;
      }

      String? bearerToken;
      String? csrfToken;
      try {
        final rawToken = await _controller?.runJavaScriptReturningResult(
          'window.localStorage.getItem("token") || window.localStorage.getItem("jwt") || window.sessionStorage.getItem("token") || ""',
        );
        bearerToken = _decodeJsStringResult(rawToken);
        final rawCsrf = await _controller?.runJavaScriptReturningResult(
          'window.localStorage.getItem("connect-csrf-token") || ""',
        );
        csrfToken = _decodeJsStringResult(rawCsrf);
      } on Object catch (_) {}

      final effectiveSession = session.copyWith(
        bearerToken: bearerToken != null ? () => bearerToken : null,
        csrfToken: csrfToken != null ? () => csrfToken : null,
      );

      final result = await ref
          .read(garminSyncControllerProvider.notifier)
          .verifyAndSaveLoginSession(effectiveSession);

      if (!mounted) return;
      if (result.success) {
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _isVerifying = false;
        _autoCaptureTriggered = false;
        _errorBanner = result.errorMessage ??
            'Validasi sesi Garmin gagal. Cookie tidak disimpan.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _autoCaptureTriggered = false;
        _errorBanner = 'Gagal memvalidasi sesi: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isChallengeFallback
              ? 'Verifikasi Garmin'
              : 'Login Garmin Connect',
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Ganti Halaman Login',
            onSelected: (url) {
              _autoCaptureTriggered = false;
              _controller?.loadRequest(Uri.parse(url));
            },
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: GarminWebViewLoginScreen.defaultLoginUrl,
                child: Text('Garmin Connect SSO'),
              ),
              PopupMenuItem(
                value: GarminWebViewLoginScreen.ssoAccountPortalUrl,
                child: Text('Garmin Account Management (SSO)'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: () => _controller?.reload(),
          ),
          TextButton(
            onPressed: _isVerifying || !_platformSupported
                ? null
                : () => _verifyCapturedSession(silentOnIncomplete: false),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_progress > 0 && _progress < 1)
            LinearProgressIndicator(value: _progress),
          if (widget.isChallengeFallback)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                border: Border(
                  bottom: BorderSide(color: colors.hairlineBorder),
                ),
              ),
              child: Text(
                'Selesaikan verifikasi keamanan (Cloudflare/CAPTCHA) langsung di halaman ini, lalu FitTrace akan menyambung ulang.',
                style: AppTypography.chartAxis(colors.textPrimary)
                    .copyWith(fontSize: 12),
              ),
            ),
          if (_errorBanner != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                border: Border(
                  bottom: BorderSide(
                    color: colors.accentSharp.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _errorBanner!,
                      style: AppTypography.chartAxis(colors.accentSharp)
                          .copyWith(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _errorBanner = null);
                      _controller?.reload();
                    },
                    child: const Text('Muat Ulang'),
                  ),
                ],
              ),
            ),
          if (_isVerifying)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colors.bgElevated,
              child: Row(
                children: <Widget>[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Memvalidasi sesi Garmin Connect...',
                    style: AppTypography.chartAxis(colors.textSecondary)
                        .copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _platformSupported && _controller != null
                ? WebViewWidget(controller: _controller!)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.pagePadding),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.public_off_rounded,
                                size: 36,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'WebView tidak tersedia di platform ini.',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Buka FitTrace di perangkat Android atau iOS untuk masuk ke Garmin Connect.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

