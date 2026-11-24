import 'dart:async';

import 'package:calm_mobil/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'api_fakes.dart';

void main() {
  group('ApiClient', () {
    test('joins the base URL and sends the access token as a Bearer', () async {
      final api = FakeApi((_) => json({'ok': true}));

      final answer = await api.client().get('/client/profile');

      expect(answer, {'ok': true});
      expect(api.sent.single.method, 'GET');
      expect(api.sent.single.url.toString(), 'http://10.0.2.2:3000/api/client/profile');
      expect(api.sent.single.headers['Authorization'], 'Bearer access-1');
      expect(api.sent.single.headers['Accept'], 'application/json');
    });

    test('sends no Authorization header without a session', () async {
      final api = FakeApi((_) => json([]))..token = null;

      await api.client().get('/client/services');

      expect(api.sent.single.headers.containsKey('Authorization'), isFalse);
    });

    test('sends a JSON body', () async {
      final api = FakeApi((_) => json({}));

      await api.client().post('/client/sign-in', {'phone': '9981234567', 'nip': '1357'});
      await api.client().put('/client/profile', {'phone': '9981234567'});

      expect(api.sent.first.body, {'phone': '9981234567', 'nip': '1357'});
      expect(api.sent.first.headers['Content-Type'], startsWith('application/json'));
      expect(api.sent.last.method, 'PUT');
    });

    test('answers null for 204', () async {
      final api = FakeApi((_) => noContent());

      expect(await api.client().delete('/client/appointments/4821'), isNull);
      expect(api.sent.single.method, 'DELETE');
    });

    test('turns {error, code} into an ApiException', () async {
      final api = FakeApi((_) => failure(409, 'slot_taken', 'Ese horario ya está ocupado.'));

      await expectLater(
        api.client().post('/client/appointments', {}),
        throwsA(isA<ApiException>()
            .having((e) => e.status, 'status', 409)
            .having((e) => e.code, 'code', 'slot_taken')
            .having((e) => e.message, 'message', 'Ese horario ya está ocupado.')),
      );
    });

    test('keeps the status of an error without a JSON body', () async {
      final api = FakeApi((_) => http.Response('<html>Bad gateway</html>', 502));

      await expectLater(
        api.client().get('/client/services'),
        throwsA(isA<ApiException>()
            .having((e) => e.status, 'status', 502)
            .having((e) => e.code, 'code', isNull)
            .having((e) => e.message, 'message', isNull)),
      );
    });

    test('tells a timeout apart from a network failure', () async {
      final stalled = FakeApi((_) => Completer<http.Response>().future);
      final offline = FakeApi((_) => throw http.ClientException('Connection refused'));

      await expectLater(
        stalled.client(timeout: const Duration(milliseconds: 20)).get('/client/services'),
        throwsA(isA<ApiTimeout>()),
      );
      await expectLater(offline.client().get('/client/services'), throwsA(isA<ApiUnreachable>()));
    });

    test('waits 15 seconds by default, as the app did before', () {
      expect(ApiClient.defaultTimeout, const Duration(seconds: 15));
    });
  });
}
