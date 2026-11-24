import 'dart:convert';

import 'package:calm_mobil/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The session Supabase Auth keeps on the device, with a real auth client over a fake Auth server:
/// what happens to the access token the app sends when it is about to expire or has expired.
void main() {
  late List<http.Request> authCalls;
  late List<http.Request> apiCalls;
  late http.Response Function(http.Request request) authAnswer;

  setUp(() {
    authCalls = [];
    apiCalls = [];
    authAnswer = (_) => _json(_sessionJson(_jwt(const Duration(hours: 1), 'access-new'), 'refresh-2'));
  });

  Future<GoTrueClient> authWith(Duration expiresIn) async {
    final auth = GoTrueClient(
      url: 'http://supabase.test/auth/v1',
      autoRefreshToken: false,
      httpClient: MockClient((request) async {
        authCalls.add(request);
        return authAnswer(request);
      }),
    );
    await auth.setInitialSession(jsonEncode(_sessionJson(_jwt(expiresIn, 'access-old'), 'refresh-1')));
    return auth;
  }

  ApiClient apiOver(GoTrueClient auth, {Duration timeout = const Duration(seconds: 5)}) {
    return ApiClient.forAuth(
      auth,
      baseUrl: 'http://10.0.2.2:3000/api',
      timeout: timeout,
      httpClient: MockClient((request) async {
        apiCalls.add(request);
        return _json({'name': 'María López', 'phone': '9981234567'});
      }),
    );
  }

  String? bearerSent() => apiCalls.single.headers['Authorization'];

  test('sends a fresh access token as it is, without refreshing', () async {
    final auth = await authWith(const Duration(hours: 1));

    await apiOver(auth).get('/client/profile');

    expect(authCalls, isEmpty);
    expect(bearerSent(), 'Bearer ${auth.currentSession!.accessToken}');
    expect(_jwtName(bearerSent()!), 'access-old');
  });

  test('refreshes an expired session before the request and sends the new token', () async {
    final auth = await authWith(const Duration(minutes: -5));

    await apiOver(auth).get('/client/profile');

    expect(authCalls.single.url.path, '/auth/v1/token');
    expect(authCalls.single.url.queryParameters['grant_type'], 'refresh_token');
    expect(jsonDecode(authCalls.single.body), {'refresh_token': 'refresh-1'});
    expect(_jwtName(bearerSent()!), 'access-new');
    expect(auth.currentSession!.refreshToken, 'refresh-2');
  });

  test('refreshes a session that expires within 60 seconds', () async {
    final auth = await authWith(const Duration(seconds: 45));

    await apiOver(auth).get('/client/orders');

    expect(authCalls, hasLength(1));
    expect(_jwtName(bearerSent()!), 'access-new');
  });

  test('a refresh token the server no longer takes ends the session, nothing is sent', () async {
    authAnswer = (_) => _json(
          {'code': 400, 'error_code': 'refresh_token_not_found', 'msg': 'Invalid Refresh Token: Refresh Token Not Found'},
          400,
        );
    final auth = await authWith(const Duration(minutes: -5));

    await expectLater(
      apiOver(auth).get('/client/orders'),
      throwsA(isA<ApiException>()
          .having((e) => e.status, 'status', 401)
          .having((e) => e.code, 'code', 'signed_out')),
    );
    expect(apiCalls, isEmpty);
    expect(auth.currentSession, isNull);
  });

  test('a refresh that cannot reach Supabase is unreachable, and the session stays', () async {
    authAnswer = (_) => throw http.ClientException('Network is unreachable');
    final auth = await authWith(const Duration(minutes: -5));

    await expectLater(
      apiOver(auth, timeout: const Duration(seconds: 20)).get('/client/orders'),
      throwsA(isA<ApiUnreachable>()),
    );
    expect(apiCalls, isEmpty);
    expect(auth.currentSession, isNotNull);
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('a refresh that does not answer in time is a timeout', () async {
    final slowAuth = GoTrueClient(
      url: 'http://supabase.test/auth/v1',
      autoRefreshToken: false,
      httpClient: MockClient((request) => Future.delayed(const Duration(seconds: 2), () => _json({}))),
    );
    await slowAuth.setInitialSession(jsonEncode(_sessionJson(_jwt(const Duration(minutes: -5), 'old'), 'r')));

    await expectLater(
      ApiClient.forAuth(
        slowAuth,
        baseUrl: 'http://10.0.2.2:3000/api',
        timeout: const Duration(milliseconds: 50),
        httpClient: MockClient((request) async {
          apiCalls.add(request);
          return _json({});
        }),
      ).get('/client/orders'),
      throwsA(isA<ApiTimeout>()),
    );
    expect(apiCalls, isEmpty);
  });

  test('without a session the request goes out with no token and no refresh', () async {
    final auth = GoTrueClient(
      url: 'http://supabase.test/auth/v1',
      autoRefreshToken: false,
      httpClient: MockClient((request) async {
        authCalls.add(request);
        return _json({});
      }),
    );

    await apiOver(auth).get('/client/services');

    expect(authCalls, isEmpty);
    expect(apiCalls.single.headers.containsKey('Authorization'), isFalse);
  });
}

http.Response _json(Object body, [int status = 200]) {
  return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
}

Map<String, dynamic> _sessionJson(String accessToken, String refreshToken) {
  return {
    'access_token': accessToken,
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': refreshToken,
    'user': {
      'id': '11111111-1111-1111-1111-111111111111',
      'aud': 'authenticated',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-11-22T00:00:00Z',
    },
  };
}

/// An unsigned JWT that expires [expiresIn] from now; [name] tells tokens apart in assertions.
String _jwt(Duration expiresIn, String name) {
  String part(Object value) => base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final exp = DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': '1', 'exp': exp, 'name': name})}.sig';
}

String _jwtName(String bearer) {
  final payload = bearer.substring('Bearer '.length).split('.')[1];
  return (jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload)))) as Map)['name'] as String;
}
