import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/garmin_connect_client.dart';
import '../domain/garmin_session.dart';
import 'secure_cookie_store.dart';

/// Strict HTTPS Dio implementation of [GarminConnectClient] (`M1-03`, `M1-06`, `NFR-02`).
///
/// Enforces:
/// - HTTPS-only requests (`https://` scheme check + `badCertificateCallback => false`)
/// - Automatic encrypted `Cookie` / `Set-Cookie` synchronization via [SecureCookieStore]
/// - Zero logging of cookies, tokens, or `Authorization` headers
class DioGarminConnectClient implements GarminConnectClient {
  DioGarminConnectClient({
    required this.cookieStore,
    Dio? dio,
    String baseUrl = defaultBaseUrl,
  })  : _baseUrl = _requireHttpsUrl(baseUrl),
        _dio = dio ?? _createStrictDio(_requireHttpsUrl(baseUrl)) {
    _installAuthInterceptor();
  }

  static const String defaultBaseUrl = 'https://connect.garmin.com';
  static const String _activityListPath =
      '/activitylist-service/activities/search/activities';
  static const String _downloadActivityPrefix =
      '/download-service/files/activity';

  final SecureCookieStore cookieStore;
  final String _baseUrl;
  final Dio _dio;

  static String _requireHttpsUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme.toLowerCase() != 'https') {
      throw const SyncAuthFailure(
        'Hanya koneksi HTTPS yang diperbolehkan untuk sinkronisasi Garmin.',
      );
    }
    return url;
  }

  static Dio _createStrictDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 20),
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (!kIsWeb) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          // NFR-02: reject invalid/untrusted TLS certificates strictly.
          client.badCertificateCallback = (_, _, _) => false;
          return client;
        },
      );
    }
    return dio;
  }

  void _installAuthInterceptor() {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.uri.scheme.toLowerCase() != 'https') {
            handler.reject(
              DioException(
                requestOptions: options,
                error: const SyncAuthFailure(
                  'Koneksi non-HTTPS ditolak oleh kebijakan keamanan.',
                ),
              ),
            );
            return;
          }

          final session = await cookieStore.loadSession();
          if (session != null) {
            final cookieHeader = session.buildCookieHeader(options.uri);
            if (cookieHeader.isNotEmpty) {
              options.headers['Cookie'] = cookieHeader;
            }
            if (session.csrfToken != null && session.csrfToken!.isNotEmpty) {
              options.headers['connect-csrf-token'] = session.csrfToken;
            }
            if (session.bearerToken != null && session.bearerToken!.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer ${session.bearerToken}';
            }
          }
          options.headers['NK'] = 'NT';
          options.headers['X-Requested-With'] = 'XMLHttpRequest';
          options.headers.putIfAbsent(
            'Accept',
            () => 'application/json, text/plain, */*',
          );
          handler.next(options);
        },
        onResponse: (response, handler) async {
          await _persistSetCookies(response.requestOptions.uri, response.headers);
          handler.next(response);
        },
        onError: (error, handler) async {
          final response = error.response;
          if (response != null) {
            await _persistSetCookies(
              response.requestOptions.uri,
              response.headers,
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _persistSetCookies(Uri uri, Headers headers) async {
    final setCookies = headers['set-cookie'];
    if (setCookies == null || setCookies.isEmpty) return;
    await cookieStore.mergeSetCookieHeaders(
      requestUri: uri,
      setCookieHeaders: setCookies,
    );
  }

  @override
  Future<SessionProbeResult> probeSession() async {
    final session = await cookieStore.loadSession();
    if (session == null || session.isEmpty) {
      return const SessionProbeResult(
        status: ProbeStatus.expired,
        statusCode: 401,
        message: 'Belum ada sesi Garmin tersimpan.',
      );
    }

    try {
      final response = await _dio.get<dynamic>(
        '$_baseUrl$_activityListPath',
        queryParameters: const <String, Object>{'start': 0, 'limit': 1},
      );
      return classifyResponse(response);
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) {
        return classifyResponse(response);
      }
      AppLogger.warn('GarminDioClient', 'Session probe network failure', error);
      return SessionProbeResult(
        status: ProbeStatus.networkError,
        message: error.message ?? 'Gagal menghubungi server Garmin Connect.',
      );
    }
  }

  /// Classifies HTTP status, redirects, and challenge responses (`M1-03`).
  static SessionProbeResult classifyResponse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final realUri = response.realUri;

    if (status == 429) {
      final retrySec = int.tryParse(response.headers.value('retry-after') ?? '');
      return SessionProbeResult(
        status: ProbeStatus.rateLimited,
        statusCode: status,
        retryAfter: retrySec != null ? Duration(seconds: retrySec) : null,
        message: 'Garmin membatasi permintaan sementara (HTTP 429).',
      );
    }

    if (isCloudflareOrCaptcha(status: status, headers: response.headers, body: response.data, uri: realUri)) {
      return SessionProbeResult(
        status: ProbeStatus.challengeRequired,
        statusCode: status,
        message:
            'Garmin meminta verifikasi keamanan (Cloudflare/CAPTCHA).',
      );
    }

    final redirectedToSso = realUri.host.toLowerCase().contains('sso.garmin.com') ||
        realUri.path.toLowerCase().contains('/signin');

    if (status == 401 || status == 403 || redirectedToSso) {
      return SessionProbeResult(
        status: ProbeStatus.expired,
        statusCode: status,
        message: 'Sesi Garmin Connect berakhir atau perlu login ulang.',
      );
    }

    if (status >= 200 && status < 300) {
      if (response.data is List) {
        return SessionProbeResult(status: ProbeStatus.valid, statusCode: status);
      }
      if (response.data is String) {
        final raw = (response.data as String).trimLeft();
        if (raw.startsWith('[')) {
          return SessionProbeResult(status: ProbeStatus.valid, statusCode: status);
        }
        return SessionProbeResult(
          status: ProbeStatus.expired,
          statusCode: status,
          message: 'Respons Garmin bukan daftar aktivitas (mungkin sesi kedaluwarsa).',
        );
      }
      if (response.data == null) {
        return SessionProbeResult(status: ProbeStatus.valid, statusCode: status);
      }
    }

    return SessionProbeResult(
      status: ProbeStatus.networkError,
      statusCode: status,
      message: 'Respons Garmin tidak terduga (HTTP $status).',
    );
  }

  static bool isCloudflareOrCaptcha({
    required int status,
    required Headers headers,
    required Object? body,
    required Uri uri,
  }) {
    final cfMitigated = (headers.value('cf-mitigated') ?? '').toLowerCase();
    if (cfMitigated.contains('challenge')) return true;

    final pathLower = uri.path.toLowerCase();
    if (pathLower.contains('/cdn-cgi/challenge') || pathLower.contains('captcha')) {
      return true;
    }

    if (status == 403 || status == 503 || status == 429 || body is String) {
      final snippet = (body is String ? body : '').toLowerCase();
      if (snippet.contains('/cdn-cgi/challenge') ||
          snippet.contains('cf-turnstile') ||
          snippet.contains('g-recaptcha') ||
          snippet.contains('hcaptcha') ||
          snippet.contains('verify you are human')) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<List<GarminActivitySummary>> fetchActivitiesPage({
    required int start,
    int limit = 50,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_baseUrl$_activityListPath',
      queryParameters: <String, Object>{
        'start': start,
        'limit': limit,
      },
    );

    final classification = classifyResponse(response);
    if (classification.status == ProbeStatus.rateLimited) {
      throw RateLimitFailure(classification.message ?? 'Rate limited (429)');
    }
    if (classification.status == ProbeStatus.challengeRequired) {
      throw const GarminChallengeException();
    }
    if (classification.status == ProbeStatus.expired) {
      throw SyncAuthFailure(
        classification.message ?? 'Sesi Garmin tidak valid (${response.statusCode})',
      );
    }
    if ((response.statusCode ?? 500) >= 400) {
      throw ImportFailure(
        'Gagal mengambil daftar aktivitas Garmin (HTTP ${response.statusCode}).',
      );
    }

    final rawList = _decodeJsonList(response.data);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(GarminActivitySummary.fromGarminJson)
        .toList(growable: false);
  }

  @override
  Stream<List<int>> downloadFitStream(int garminActivityId) async* {
    final response = await _dio.get<ResponseBody>(
      '$_baseUrl$_downloadActivityPrefix/$garminActivityId',
      options: Options(
        responseType: ResponseType.stream,
        headers: const <String, Object>{'Accept': '*/*'},
      ),
    );

    final status = response.statusCode ?? 0;
    if (status == 429) {
      throw const RateLimitFailure('Garmin rate-limit saat mengunduh .FIT (429).');
    }
    if (isCloudflareOrCaptcha(
      status: status,
      headers: response.headers,
      body: null,
      uri: response.realUri,
    )) {
      throw const GarminChallengeException();
    }
    if (status == 401 ||
        status == 403 ||
        response.realUri.host.toLowerCase().contains('sso.garmin.com')) {
      throw SyncAuthFailure('Sesi Garmin berakhir saat mengunduh aktivitas $garminActivityId.');
    }
    if (status < 200 || status >= 300 || response.data == null) {
      throw ImportFailure(
        'Gagal mengunduh file .FIT aktivitas $garminActivityId (HTTP $status).',
      );
    }

    await for (final chunk in response.data!.stream) {
      yield chunk;
    }
  }

  static List<dynamic> _decodeJsonList(dynamic payload) {
    if (payload is List<dynamic>) return payload;
    if (payload is String && payload.trim().startsWith('[')) {
      final decoded = jsonDecode(payload);
      if (decoded is List<dynamic>) return decoded;
    }
    return const <dynamic>[];
  }
}
