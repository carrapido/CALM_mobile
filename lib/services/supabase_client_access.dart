import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'client_access.dart';

/// Sends the phone and NIP to the backend and answers with whatever comes back.
typedef InvokeSignIn = Future<Object?> Function(Map<String, String> body);

/// Installs a session on this device from a refresh token.
typedef InstallSession = Future<void> Function(String refreshToken);

/// Signs the client in through the `client-sign-in` Edge Function and installs her session.
///
/// The function is the only place that sees the NIP: it verifies the argon2id hash in
/// `clients.nip_hash`, throttles attempts per phone, and answers with a refresh token. From then
/// on it is row level security, not this app, that decides what the client reaches.
class SupabaseClientAccess implements ClientAccess {
  SupabaseClientAccess(SupabaseClient supabase, {Duration timeout = defaultTimeout})
      : this.using(
          invoke: (body) async =>
              (await supabase.functions.invoke('client-sign-in', body: body)).data,
          installSession: (refreshToken) => supabase.auth.setSession(refreshToken),
          timeout: timeout,
        );

  /// The same rules over any backend; tests use it with stand-ins.
  const SupabaseClientAccess.using({
    required this.invoke,
    required this.installSession,
    this.timeout = defaultTimeout,
  });

  /// Past this, a stalled connection is told as unavailable instead of a button that never answers.
  static const defaultTimeout = Duration(seconds: 15);

  final InvokeSignIn invoke;
  final InstallSession installSession;
  final Duration timeout;

  @override
  Future<SignInOutcome> signIn({required String phoneDigits, required String nip}) async {
    final String refreshToken;
    try {
      final answer = await invoke({'phone': phoneDigits, 'nip': nip}).timeout(timeout);
      final token = _refreshTokenIn(answer);
      if (token == null) return const SignInUnavailable();
      refreshToken = token;
    } on FunctionException catch (failure) {
      return _refusalFor(failure.status);
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
    final token = answer['refresh_token'];
    return token is String && token.isNotEmpty ? token : null;
  }

  static SignInOutcome _refusalFor(int status) {
    return switch (status) {
      401 => const SignInRejected(),
      429 => const SignInThrottled(),
      _ => const SignInUnavailable(),
    };
  }
}
