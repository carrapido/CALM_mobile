import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import '../utils/app_constants.dart';

/// The access token to send for the session open on this device, or null without one.
///
/// It may throw [ApiUnreachable], [ApiTimeout] or [ApiException.signedOut] when the session
/// needed a refresh that could not be done.
typedef AccessToken = FutureOr<String?> Function();

/// Installs a session on this device from a refresh token.
typedef SessionInstaller = Future<void> Function(String refreshToken);

/// Talks JSON to the CALM API (`/api/client/*`), with the client's Supabase access token as a
/// Bearer, the same way the admin panel talks to `/api/*`.
///
/// A refusal arrives as [ApiException]; a backend that does not answer in time as [ApiTimeout];
/// one that cannot be reached at all as [ApiUnreachable].
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this._accessToken,
    http.Client? httpClient,
    this.timeout = defaultTimeout,
  })  : _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _http = httpClient ?? http.Client();

  /// [ApiConfig.url], with the token of the session Supabase Auth keeps on this device.
  factory ApiClient.forSupabase(SupabaseClient supabase) {
    return ApiClient.forAuth(supabase.auth, baseUrl: ApiConfig.url);
  }

  /// [baseUrl], with the access token of [auth]'s session, refreshed first when it is missing,
  /// expired or about to expire.
  ///
  /// Supabase only refreshes in the background while the app is in the foreground, and a refresh
  /// that failed for the network keeps the expired session; sending that token would make the API
  /// answer 401 `signed_out` to a client who is still signed in.
  factory ApiClient.forAuth(
    GoTrueClient auth, {
    required String baseUrl,
    http.Client? httpClient,
    Duration timeout = defaultTimeout,
  }) {
    return ApiClient(
      baseUrl: baseUrl,
      accessToken: () => _freshAccessToken(auth, timeout),
      httpClient: httpClient,
      timeout: timeout,
    );
  }

  /// A token closer than this to its expiry is refreshed before it is sent.
  static const refreshMargin = Duration(seconds: 60);

  static Future<String?> _freshAccessToken(GoTrueClient auth, Duration timeout) async {
    final session = auth.currentSession;
    if (session == null) return null;
    if (session.accessToken.isNotEmpty && !_expiresSoon(session.expiresAt)) return session.accessToken;

    final Session? refreshed;
    try {
      refreshed = (await auth.refreshSession().timeout(timeout)).session;
    } on TimeoutException {
      throw const ApiTimeout();
    } on AuthRetryableFetchException catch (cause) {
      // No network or Supabase failing: the session stays on the device for the next try.
      throw ApiUnreachable(cause);
    } on AuthException {
      // The refresh token is no longer valid (Supabase already dropped the session) or missing.
      throw ApiException.signedOut;
    }
    final token = refreshed?.accessToken;
    if (token == null || token.isEmpty) throw ApiException.signedOut;
    return token;
  }

  static bool _expiresSoon(int? expiresAt) {
    if (expiresAt == null) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return !DateTime.now().add(refreshMargin).isBefore(expiry);
  }

  /// Past this, a stalled connection is told as unavailable instead of a button that never answers.
  static const defaultTimeout = Duration(seconds: 15);

  final String _baseUrl;
  final AccessToken _accessToken;
  final http.Client _http;
  final Duration timeout;

  Future<Object?> get(String path) => _send('GET', path);

  Future<Object?> post(String path, [Object? body]) => _send('POST', path, body);

  Future<Object?> put(String path, Object? body) => _send('PUT', path, body);

  Future<Object?> delete(String path) => _send('DELETE', path);

  Future<Object?> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    request.headers['Accept'] = 'application/json';
    final token = await _accessToken();
    if (token != null && token.isNotEmpty) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await _http.send(request).then(http.Response.fromStream).timeout(timeout);
    } on TimeoutException {
      throw const ApiTimeout();
    } on http.ClientException catch (cause) {
      throw ApiUnreachable(cause);
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      return response.body.isEmpty ? null : jsonDecode(response.body);
    }
    throw ApiException.from(status, response.body);
  }
}

/// The API answered with an error: `{error, code}` as the admin API does.
class ApiException implements Exception {
  const ApiException(this.status, {this.code, this.message});

  /// Reads `{error, code}` from [body]; an answer of another shape keeps only the status.
  factory ApiException.from(int status, String body) {
    Object? decoded;
    try {
      decoded = body.isEmpty ? null : jsonDecode(body);
    } on FormatException {
      decoded = null;
    }
    final error = decoded is Map ? decoded['error'] : null;
    final code = decoded is Map ? decoded['code'] : null;
    return ApiException(
      status,
      code: code is String ? code : null,
      message: error is String ? error : null,
    );
  }

  /// Her session ended: what the API answers for a token it no longer takes, and what a refresh
  /// Supabase refused is told as.
  static const signedOut = ApiException(401, code: 'signed_out', message: AppConstants.bookingSignedOut);

  final int status;
  final String? code;

  /// Worded for the client by the backend, when it sent one.
  final String? message;

  @override
  String toString() => 'ApiException($status, $code, $message)';
}

/// The API did not answer within [ApiClient.timeout].
class ApiTimeout implements Exception {
  const ApiTimeout();

  @override
  String toString() => 'ApiTimeout';
}

/// The API could not be reached: no network, no server listening, a dropped connection.
class ApiUnreachable implements Exception {
  const ApiUnreachable(this.cause);

  final Object cause;

  @override
  String toString() => 'ApiUnreachable($cause)';
}
