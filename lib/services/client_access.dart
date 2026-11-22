/// How Entrada asks whether a phone and a NIP open a session, without knowing who answers.
///
/// The NIP is never checked on the device: it travels once to the backend, which holds the
/// argon2id hash. See `odd/tasks/acceso-cliente-supabase.md` (S2).
abstract interface class ClientAccess {
  Future<SignInOutcome> signIn({required String phoneDigits, required String nip});
}

/// The client the backend let in.
class SignedInClient {
  const SignedInClient({required this.id, required this.name, required this.phone});

  final int id;
  final String name;
  final String phone;
}

sealed class SignInOutcome {
  const SignInOutcome();
}

class SignInGranted extends SignInOutcome {
  const SignInGranted(this.client);

  final SignedInClient client;
}

/// The pair does not open anything. An unknown phone and a wrong NIP are the same answer, so a
/// stranger cannot learn which phones are clients (S6).
class SignInRejected extends SignInOutcome {
  const SignInRejected();
}

/// Too many failed attempts for this phone; the backend is making the client wait (S7).
class SignInThrottled extends SignInOutcome {
  const SignInThrottled();
}

/// The backend could not be reached or failed. Nothing is known about the pair.
class SignInUnavailable extends SignInOutcome {
  const SignInUnavailable();
}
