import 'dart:async';
import 'dart:convert';

import 'package:calm_mobil/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A request the fake API received, with its JSON body decoded.
class SentRequest {
  SentRequest(this.method, this.url, this.headers, this.body);

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Object? body;

  String get path => url.path;
}

/// Answers every request with [respond] and records what was sent.
class FakeApi {
  FakeApi(this.respond);

  FutureOr<http.Response> Function(SentRequest request) respond;
  final sent = <SentRequest>[];
  String? token = 'access-1';

  ApiClient client({Duration timeout = const Duration(seconds: 5)}) {
    return ApiClient(
      baseUrl: 'http://10.0.2.2:3000/api',
      accessToken: () => token,
      httpClient: MockClient((request) async {
        final body = request.body.isEmpty ? null : jsonDecode(request.body);
        final sentRequest = SentRequest(request.method, request.url, request.headers, body);
        sent.add(sentRequest);
        return respond(sentRequest);
      }),
      timeout: timeout,
    );
  }
}

http.Response json(Object? body, [int status = 200]) {
  return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});
}

http.Response failure(int status, String code, [String error = 'Algo salió mal']) {
  return json({'error': error, 'code': code}, status);
}

http.Response noContent() => http.Response('', 204);
