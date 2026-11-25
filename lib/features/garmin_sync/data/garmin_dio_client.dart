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
  static const String personalApiBaseUrl = 'https://personal.connectapi.garmin.com';
  static const String _activityListPath =
      '/modern/proxy/activitylist-service/activities/search/activities';
  static const String _appActivityListPath =
      '/app/proxy/activitylist-service/activities/search/activities';
  static const String _downloadActivityPrefix =
      '/modern/proxy/download-service/files/activity';
  static const String _appDownloadActivityPrefix =
      '/app/proxy/download-service/files/activity';

  /// Exchanges a Garmin Personal API Key (GCDC_...) for a temporary 24h OAuth access token.
  static Future<String> exchangePersonalApiKey(String apiKey, {Dio? dio}) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const SyncAuthFailure('Garmin Personal API Key tidak boleh kosong.');
    }
    final client = dio ?? _createStrictDio(personalApiBaseUrl);
    try {
      final res = await client.post<dynamic>(
        '$personalApiBaseUrl/personalapitoken-service/personal-api/personal-api-key/token',
        options: Options(
          extra: const <String, Object?>{'skipSessionAuth': true},
          headers: <String, String>{
            'Authorization': 'ApiKey $trimmedKey',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (res.statusCode == 200 && res.data != null) {
        final token = res.data.toString().trim();
        if (_isValidBearerToken(token)) return token;
      }
      throw SyncAuthFailure(
        'Gagal menukarkan Garmin Personal API Key (HTTP ${res.statusCode ?? '-'}). Pastikan API Key benar.',
      );
    } on DioException catch (e) {
      throw SyncAuthFailure(
        'Koneksi gagal saat menukarkan Personal API Key: ${e.message}',
      );
    }
  }

  static bool _isValidBearerToken(String token) {
    if (token.isEmpty) return false;
    if (token.startsWith('<') || token.startsWith('{')) return false;
    if (token.contains(RegExp(r'\s'))) return false;
    return token.length >= 16;
  }

  static bool _isGarminHost(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'garmin.com' || host.endsWith('.garmin.com');
  }

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
        headers: const <String, String>{
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
          'Referer': 'https://connect.garmin.com/modern/',
          'Origin': 'https://connect.garmin.com',
        },
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

          final skipSessionAuth = options.extra['skipSessionAuth'] == true;
          if (!skipSessionAuth && _isGarminHost(options.uri)) {
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
          await _persistSetCookies(response.realUri, response.headers);
          handler.next(response);
        },
        onError: (error, handler) async {
          final response = error.response;
          if (response != null) {
            await _persistSetCookies(
              response.realUri,
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

    if (session.isPersonalApi) {
      try {
        var token = session.bearerToken;
        if (token == null || token.isEmpty) {
          token = await exchangePersonalApiKey(session.personalApiKey!, dio: _dio);
          await cookieStore.saveSession(session.copyWith(bearerToken: () => token));
        }

        var response = await _dio.get<dynamic>(
          '$personalApiBaseUrl/activitylist-service/activities/search/activities',
          queryParameters: const <String, Object>{'start': 0, 'limit': 1},
          options: Options(
            headers: <String, Object>{
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (response.statusCode == 401 || response.statusCode == 403) {
          token = await exchangePersonalApiKey(session.personalApiKey!, dio: _dio);
          await cookieStore.saveSession(session.copyWith(bearerToken: () => token));
          response = await _dio.get<dynamic>(
            '$personalApiBaseUrl/activitylist-service/activities/search/activities',
            queryParameters: const <String, Object>{'start': 0, 'limit': 1},
            options: Options(
              headers: <String, Object>{
                'Authorization': 'Bearer $token',
              },
            ),
          );
        }

        return classifyResponse(response);
      } on DioException catch (error) {
        if (error.response != null) {
          return classifyResponse(error.response!);
        }
        return SessionProbeResult(
          status: ProbeStatus.networkError,
          message: error.message ?? 'Gagal menghubungi server Garmin Personal API.',
        );
      }
    }

    try {
      var response = await _dio.get<dynamic>(
        '$_baseUrl$_activityListPath',
        queryParameters: const <String, Object>{'start': 0, 'limit': 1},
      );
      if (response.statusCode == 404) {
        response = await _dio.get<dynamic>(
          '$_baseUrl$_appActivityListPath',
          queryParameters: const <String, Object>{'start': 0, 'limit': 1},
        );
      }
      return classifyResponse(response);
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) {
        if (response.statusCode == 404) {
          try {
            final fallbackResponse = await _dio.get<dynamic>(
              '$_baseUrl$_appActivityListPath',
              queryParameters: const <String, Object>{'start': 0, 'limit': 1},
            );
            return classifyResponse(fallbackResponse);
          } on DioException catch (fallbackError) {
            if (fallbackError.response != null) {
              return classifyResponse(fallbackError.response!);
            }
          }
        }
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
      if (response.data is List || response.data is Map) {
        return SessionProbeResult(status: ProbeStatus.valid, statusCode: status);
      }
      if (response.data is String) {
        final raw = (response.data as String).trimLeft();
        if (raw.startsWith('[') || raw.startsWith('{')) {
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
    final session = await cookieStore.loadSession();
    if (session != null && session.isPersonalApi) {
      var token = session.bearerToken;
      if (token == null || token.isEmpty) {
        token = await exchangePersonalApiKey(session.personalApiKey!, dio: _dio);
        await cookieStore.saveSession(session.copyWith(bearerToken: () => token));
      }

      Response<dynamic> response;
      try {
        response = await _dio.get<dynamic>(
          '$personalApiBaseUrl/activitylist-service/activities/search/activities',
          queryParameters: <String, Object>{
            'start': start,
            'limit': limit,
          },
          options: Options(
            headers: <String, Object>{
              'Authorization': 'Bearer $token',
            },
          ),
        );

        if (response.statusCode == 401 || response.statusCode == 403) {
          token = await exchangePersonalApiKey(session.personalApiKey!, dio: _dio);
          await cookieStore.saveSession(session.copyWith(bearerToken: () => token));
          response = await _dio.get<dynamic>(
            '$personalApiBaseUrl/activitylist-service/activities/search/activities',
            queryParameters: <String, Object>{
              'start': start,
              'limit': limit,
            },
            options: Options(
              headers: <String, Object>{
                'Authorization': 'Bearer $token',
              },
            ),
          );
        }
      } on DioException catch (error) {
        if (error.response != null) {
          response = error.response!;
        } else {
          rethrow;
        }
      }

      final classification = classifyResponse(response);
      if (classification.status == ProbeStatus.rateLimited) {
        throw RateLimitFailure(classification.message ?? 'Rate limited (429)');
      }
      if (classification.status == ProbeStatus.expired) {
        throw SyncAuthFailure(
          classification.message ?? 'Garmin Personal API Key kedaluwarsa (${response.statusCode})',
        );
      }
      if ((response.statusCode ?? 500) >= 400) {
        throw ImportFailure(
          'Gagal mengambil daftar aktivitas Garmin Personal API (HTTP ${response.statusCode}).',
        );
      }

      final rawList = _decodeJsonList(response.data);
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(GarminActivitySummary.fromGarminJson)
          .toList(growable: false);
    }

    Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        '$_baseUrl$_activityListPath',
        queryParameters: <String, Object>{
          'start': start,
          'limit': limit,
        },
      );
      if (response.statusCode == 404) {
        response = await _dio.get<dynamic>(
          '$_baseUrl$_appActivityListPath',
          queryParameters: <String, Object>{
            'start': start,
            'limit': limit,
          },
        );
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        response = await _dio.get<dynamic>(
          '$_baseUrl$_appActivityListPath',
          queryParameters: <String, Object>{
            'start': start,
            'limit': limit,
          },
        );
      } else {
        rethrow;
      }
    }

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
    final session = await cookieStore.loadSession();
    if (session != null && session.isPersonalApi) {
      var token = session.bearerToken;
      if (token == null || token.isEmpty) {
        token = await exchangePersonalApiKey(session.personalApiKey!, dio: _dio);
        await cookieStore.saveSession(session.copyWith(bearerToken: () => token));
      }

      Response<ResponseBody> response;
      try {
        response = await _dio.get<ResponseBody>(
          '$personalApiBaseUrl/download-service/files/activity/$garminActivityId',
          options: Options(
            responseType: ResponseType.stream,
            headers: <String, Object>{
              'Authorization': 'Bearer $token',
              'Accept': '*/*',
            },
          ),
        );

        if (response.statusCode == 401 || response.statusCode == 403) {
          token = await exchangePersonalApiKey(session.personalApiKey!, dio: _dio);
          await cookieStore.saveSession(session.copyWith(bearerToken: () => token));
          response = await _dio.get<ResponseBody>(
            '$personalApiBaseUrl/download-service/files/activity/$garminActivityId',
            options: Options(
              responseType: ResponseType.stream,
              headers: <String, Object>{
                'Authorization': 'Bearer $token',
                'Accept': '*/*',
              },
            ),
          );
        }
      } on DioException catch (error) {
        if (error.response?.data is ResponseBody) {
          response = Response<ResponseBody>(
            requestOptions: error.requestOptions,
            data: error.response!.data as ResponseBody,
            statusCode: error.response!.statusCode,
          );
        } else {
          rethrow;
        }
      }

      final status = response.statusCode ?? 0;
      if (status == 429) {
        throw const RateLimitFailure('Garmin rate-limit saat mengunduh .FIT (429).');
      }
      if (status == 401 || status == 403) {
        throw SyncAuthFailure(
          'Sesi Garmin Personal API berakhir saat mengunduh aktivitas $garminActivityId.',
        );
      }
      if (status < 200 || status >= 300 || response.data == null) {
        throw ImportFailure(
          'Gagal mengunduh file .FIT aktivitas $garminActivityId (HTTP $status).',
        );
      }

      await for (final chunk in response.data!.stream) {
        yield chunk;
      }
      return;
    }

    Response<ResponseBody> response;
    try {
      response = await _dio.get<ResponseBody>(
        '$_baseUrl$_downloadActivityPrefix/$garminActivityId',
        options: Options(
          responseType: ResponseType.stream,
          headers: const <String, Object>{'Accept': '*/*'},
        ),
      );
      if (response.statusCode == 404) {
        response = await _dio.get<ResponseBody>(
          '$_baseUrl$_appDownloadActivityPrefix/$garminActivityId',
          options: Options(
            responseType: ResponseType.stream,
            headers: const <String, Object>{'Accept': '*/*'},
          ),
        );
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        response = await _dio.get<ResponseBody>(
          '$_baseUrl$_appDownloadActivityPrefix/$garminActivityId',
          options: Options(
            responseType: ResponseType.stream,
            headers: const <String, Object>{'Accept': '*/*'},
          ),
        );
      } else {
        rethrow;
      }
    }

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
