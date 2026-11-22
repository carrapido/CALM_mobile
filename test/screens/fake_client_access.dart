import 'package:calm_mobil/services/client_access.dart';

/// Stands in for the backend in Entrada's tests, and records what it was asked.
class FakeClientAccess implements ClientAccess {
  FakeClientAccess({this.outcome = const SignInGranted(demoClient)});

  static const demoClient = SignedInClient(id: 2, name: 'María López', phone: '9981234567');

  SignInOutcome outcome;

  final calls = <({String phoneDigits, String nip})>[];

  @override
  Future<SignInOutcome> signIn({required String phoneDigits, required String nip}) async {
    calls.add((phoneDigits: phoneDigits, nip: nip));
    return outcome;
  }
}
