import 'dart:async';

import 'package:calm_mobil/services/client_access.dart';
import 'package:calm_mobil/services/supabase_client_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final installed = <String>[];

  SupabaseClientAccess accessAnswering(
    FutureOr<Object?> Function() answer, {
    Future<void> Function(String token)? install,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return SupabaseClientAccess.using(
      invoke: (_) async => await answer(),
      installSession: install ?? (token) async => installed.add(token),
      timeout: timeout,
    );
  }

  Future<SignInOutcome> signIn(SupabaseClientAccess access) {
    return access.signIn(phoneDigits: '9981234567', nip: '1357');
  }

  setUp(installed.clear);

  group('SupabaseClientAccess', () {
    test('installs the session it was given and lets the client in', () async {
      final outcome = await signIn(accessAnswering(() => {'refresh_token': 'token-1', 'client': {}}));

      expect(outcome, isA<SignInGranted>());
      expect(installed, ['token-1']);
    });

    test('sends the phone digits and the NIP', () async {
      Map<String, String>? sent;
      final access = SupabaseClientAccess.using(
        invoke: (body) async {
          sent = body;
          return {'refresh_token': 'token-1'};
        },
        installSession: (_) async {},
      );

      await signIn(access);

      expect(sent, {'phone': '9981234567', 'nip': '1357'});
    });

    test('reads 401 as a pair that does not match', () async {
      final outcome = await signIn(accessAnswering(() => throw const FunctionException(status: 401)));

      expect(outcome, isA<SignInRejected>());
      expect(installed, isEmpty);
    });

    test('reads 429 as too many attempts', () async {
      final outcome = await signIn(accessAnswering(() => throw const FunctionException(status: 429)));

      expect(outcome, isA<SignInThrottled>());
    });

    test('reads any other status as unavailable', () async {
      for (final status in [400, 500, 503]) {
        final outcome = await signIn(accessAnswering(() => throw FunctionException(status: status)));

        expect(outcome, isA<SignInUnavailable>(), reason: '$status');
      }
    });

    test('reads a failure to reach the backend as unavailable', () async {
      final outcome = await signIn(accessAnswering(() => throw Exception('no network')));

      expect(outcome, isA<SignInUnavailable>());
    });

    test('installs no session from an answer without a token', () async {
      for (final body in <Object?>[null, 'text', <String, Object?>{}, {'refresh_token': ''}, {'refresh_token': 7}]) {
        final outcome = await signIn(accessAnswering(() => body));

        expect(outcome, isA<SignInUnavailable>(), reason: '$body');
      }
      expect(installed, isEmpty);
    });

    test('says unavailable when the session cannot be installed', () async {
      final access = accessAnswering(
        () => {'refresh_token': 'token-1'},
        install: (_) async => throw Exception('storage failed'),
      );

      expect(await signIn(access), isA<SignInUnavailable>());
    });

    test('gives up on a backend that does not answer in time', () async {
      final never = Completer<Object?>();
      final access = accessAnswering(() => never.future, timeout: const Duration(milliseconds: 20));

      expect(await signIn(access), isA<SignInUnavailable>());
      expect(installed, isEmpty);
    });
  });
}
