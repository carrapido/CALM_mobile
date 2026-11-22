import 'package:supabase_flutter/supabase_flutter.dart';

import 'client_access.dart';

/// Signs the client in through the `client-sign-in` Edge Function and installs her session.
///
/// The function is the only place that sees the NIP: it verifies the argon2id hash in
/// `clients.nip_hash`, throttles attempts per phone, and answers with a session. From then on it
/// is row level security, not this app, that decides what the client reaches.
class SupabaseClientAccess implements ClientAccess {
  const SupabaseClientAccess(this._supabase);

  static const _functionName = 'client-sign-in';

  final SupabaseClient _supabase;

  @override
  Future<SignInOutcome> signIn({required String phoneDigits, required String nip}) async {
    try {
      final response = await _supabase.functions.invoke(
        _functionName,
        body: {'phone': phoneDigits, 'nip': nip},
      );
      return await _grantedFrom(response.data);
    } on FunctionException catch (failure) {
      return _refusalFor(failure.status);
    } catch (_) {
      // No network, a malformed answer, a session that would not install: nothing is known
      // about the pair, so the client is told to try again rather than that she typed it wrong.
      return const SignInUnavailable();
    }
  }

  Future<SignInOutcome> _grantedFrom(dynamic data) async {
    final body = data as Map<String, dynamic>;
    await _supabase.auth.setSession(body['refresh_token'] as String);
    final client = body['client'] as Map<String, dynamic>;
    return SignInGranted(
      SignedInClient(
        id: client['id'] as int,
        name: client['name'] as String,
        phone: client['phone'] as String,
      ),
    );
  }

  SignInOutcome _refusalFor(int status) {
    return switch (status) {
      401 => const SignInRejected(),
      429 => const SignInThrottled(),
      _ => const SignInUnavailable(),
    };
  }
}
