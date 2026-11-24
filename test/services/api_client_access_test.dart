import 'dart:async';

import 'package:calm_mobil/services/api_client_access.dart';
import 'package:calm_mobil/services/client_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'api_fakes.dart';

void main() {
  final installed = <String>[];

  ApiClientAccess accessOver(
    FakeApi api, {
    Future<void> Function(String token)? install,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return ApiClientAccess.using(
      api: api.client(timeout: timeout),
      installSession: install ?? (token) async => installed.add(token),
    );
  }

  Future<SignInOutcome> signIn(ApiClientAccess access) {
    return access.signIn(phoneDigits: '9981234567', nip: '1357');
  }

  final granted = {
    'refreshToken': 'token-1',
    'client': {'id': 1, 'name': 'María López', 'phone': '9981234567'},
  };

  setUp(installed.clear);

  group('ApiClientAccess', () {
    test('installs the session it was given and lets the client in', () async {
      final outcome = await signIn(accessOver(FakeApi((_) => json(granted))));

      expect(outcome, isA<SignInGranted>());
      expect(installed, ['token-1']);
    });

    test('posts the phone digits and the NIP to /client/sign-in', () async {
      final api = FakeApi((_) => json(granted));

      await signIn(accessOver(api));

      expect(api.sent.single.method, 'POST');
      expect(api.sent.single.path, '/api/client/sign-in');
      expect(api.sent.single.body, {'phone': '9981234567', 'nip': '1357'});
    });

    test('reads 401 as a pair that does not match', () async {
      final outcome = await signIn(accessOver(FakeApi((_) => failure(401, 'rejected'))));

      expect(outcome, isA<SignInRejected>());
      expect(installed, isEmpty);
    });

    test('reads 429 as too many attempts', () async {
      final outcome = await signIn(accessOver(FakeApi((_) => failure(429, 'throttled'))));

      expect(outcome, isA<SignInThrottled>());
      expect(installed, isEmpty);
    });

    test('reads any other status as unavailable', () async {
      for (final (status, code) in [(400, 'phone'), (400, 'nip'), (500, 'internal'), (503, 'down')]) {
        final outcome = await signIn(accessOver(FakeApi((_) => failure(status, code))));

        expect(outcome, isA<SignInUnavailable>(), reason: '$status');
      }
      expect(installed, isEmpty);
    });

    test('reads a failure to reach the backend as unavailable', () async {
      final outcome = await signIn(accessOver(FakeApi((_) => throw http.ClientException('offline'))));

      expect(outcome, isA<SignInUnavailable>());
    });

    test('installs no session from an answer without a token', () async {
      for (final body in <Object?>[
        null,
        'text',
        <String, Object?>{},
        {'refreshToken': ''},
        {'refreshToken': 7},
        {'refresh_token': 'token-1'},
      ]) {
        final outcome = await signIn(accessOver(FakeApi((_) => json(body))));

        expect(outcome, isA<SignInUnavailable>(), reason: '$body');
      }
      expect(installed, isEmpty);
    });

    test('says unavailable when the session cannot be installed', () async {
      final access = accessOver(
        FakeApi((_) => json(granted)),
        install: (_) async => throw Exception('storage failed'),
      );

      expect(await signIn(access), isA<SignInUnavailable>());
    });

    test('gives up on a backend that does not answer in time', () async {
      final access = accessOver(
        FakeApi((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 20),
      );

      expect(await signIn(access), isA<SignInUnavailable>());
      expect(installed, isEmpty);
    });
  });
}
