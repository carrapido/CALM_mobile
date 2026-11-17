import '../utils/telefono_formatter.dart';
import 'field_problem.dart';

/// The field whose label turns red when signing in needs attention.
enum LoginField { phone, nip }

typedef LoginProblem = FieldProblem<LoginField>;

/// The phone and NIP the client types on Entrada.
class LoginForm {
  const LoginForm({required this.phone, required this.nip});

  static const phoneLength = 10;
  static const nipLength = 4;

  final String phone;
  final String nip;

  String get phoneDigits => digitsOf(phone);

  bool get hasCompletePhone => phoneDigits.length == phoneLength;

  /// One problem at a time, in the order the client fills the form; null when ready to sign in.
  LoginProblem? firstProblem({required bool credentialsMatch}) {
    final missingPhoneDigits = phoneLength - phoneDigits.length;
    if (missingPhoneDigits == phoneLength) {
      return const LoginProblem(LoginField.phone, 'Escribe tu celular a 10 dígitos.');
    }
    if (missingPhoneDigits > 0) {
      return LoginProblem(LoginField.phone, 'Al celular le ${_missingText(missingPhoneDigits)}.');
    }
    if (nip.isEmpty) {
      return const LoginProblem(LoginField.nip, 'Escribe tu NIP de 4 dígitos.');
    }
    if (nip.length < nipLength) {
      return LoginProblem(LoginField.nip, 'Al NIP le ${_missingText(nipLength - nip.length)}.');
    }
    if (!credentialsMatch) {
      return const LoginProblem(
        LoginField.nip,
        'Tu celular o tu NIP no coinciden. Revísalos o escríbele al taller.',
      );
    }
    return null;
  }

  String _missingText(int missingDigits) {
    return missingDigits == 1 ? 'falta 1 dígito' : 'faltan $missingDigits dígitos';
  }
}
