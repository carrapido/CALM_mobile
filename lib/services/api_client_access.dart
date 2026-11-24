import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';
import 'client_access.dart';

/// Signs the client in through `POST /api/client/sign-in` and installs her session.
///
/// The backend is the only place that sees the NIP: it verifies the argon2id hash, throttles
/// attempts per phone, and answers with a Supabase Auth refresh token. From then on the API reads
/// who she is from her access token.
class ApiClientAccess implements ClientAccess {
  ApiClientAccess(ApiClient api, SupabaseClient supabase)
      : this.using(api: api, installSession: (refreshToken) => supabase.auth.setSession(refreshToken));

  /// The same rules over any API and session store; tests use it with stand-ins.
  const ApiClientAccess.using({required this.api, required this.installSession});

  final ApiClient api;
  final SessionInstaller installSession;

  @override
  Future<SignInOutcome> signIn({required String phoneDigits, required String nip}) async {
    final String refreshToken;
    try {
      final answer = await api.post('/client/sign-in', {'phone': phoneDigits, 'nip': nip});
      final token = _refreshTokenIn(answer);
      if (token == null) return const SignInUnavailable();
      refreshToken = token;
    } on ApiException catch (failure) {
      return switch (failure.status) {
        401 => const SignInRejected(),
        429 => const SignInThrottled(),
        _ => const SignInUnavailable(),
      };
    } catch (_) {
      // No network, no answer in time, or an answer of another shape: nothing is known about the
      // pair, so the client is told to try again rather than that she typed it wrong.
      return const SignInUnavailable();
    }

    // Installed last, once the answer is known to be whole, so a failure never leaves a session
    // on the device while the screen says the sign-in did not work.
    try {
      await installSession(refreshToken);
      return const SignInGranted();
    } catch (_) {
      return const SignInUnavailable();
    }
  }

  static String? _refreshTokenIn(Object? answer) {
    if (answer is! Map) return null;
    final token = answer['refreshToken'];
    return token is String && token.isNotEmpty ? token : null;
  }
}
