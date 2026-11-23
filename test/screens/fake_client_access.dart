import 'dart:async';

import 'package:calm_mobil/services/client_access.dart';

/// Stands in for the backend in Entrada's tests, and records what it was asked.
/// With [holdsAnswer], each sign-in waits until the test calls [answer].
class FakeClientAccess implements ClientAccess {
  FakeClientAccess({this.outcome = const SignInGranted(), this.holdsAnswer = false});

  SignInOutcome outcome;
  final bool holdsAnswer;
  Completer<SignInOutcome>? _pending;

  final calls = <({String phoneDigits, String nip})>[];

  @override
  Future<SignInOutcome> signIn({required String phoneDigits, required String nip}) {
    calls.add((phoneDigits: phoneDigits, nip: nip));
    if (!holdsAnswer) return Future.value(outcome);
    return (_pending = Completer<SignInOutcome>()).future;
  }

  void answer(SignInOutcome held) => _pending!.complete(held);
}
