import 'package:calm_mobil/models/demo_client_access.dart';
import 'package:calm_mobil/models/login_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginForm.firstProblem', () {
    LoginProblem? problemFor(String phone, String nip, {bool credentialsMatch = false}) {
      return LoginForm(phone: phone, nip: nip).firstProblem(credentialsMatch: credentialsMatch);
    }

    void expectProblem(LoginProblem? problem, LoginField field, String message) {
      expect(problem?.field, field);
      expect(problem?.message, message);
    }

    test('asks for the phone when it has no digits', () {
      expectProblem(problemFor('', ''), LoginField.phone, 'Escribe tu celular a 10 dígitos.');
    });

    test('says one phone digit is missing in singular', () {
      expectProblem(problemFor('998 123 456', ''), LoginField.phone, 'Al celular le falta 1 dígito.');
    });

    test('says how many phone digits are missing in plural', () {
      expectProblem(problemFor('998 123 4', ''), LoginField.phone, 'Al celular le faltan 3 dígitos.');
    });

    test('asks for the NIP once the phone is complete', () {
      expectProblem(problemFor('998 123 4567', ''), LoginField.nip, 'Escribe tu NIP de 4 dígitos.');
    });

    test('says one NIP digit is missing in singular', () {
      expectProblem(problemFor('998 123 4567', '258'), LoginField.nip, 'Al NIP le falta 1 dígito.');
    });

    test('says how many NIP digits are missing in plural', () {
      expectProblem(problemFor('998 123 4567', '25'), LoginField.nip, 'Al NIP le faltan 2 dígitos.');
    });

    test('blames the NIP when a complete pair does not match', () {
      expectProblem(
        problemFor('998 123 4567', '1111'),
        LoginField.nip,
        'Tu celular o tu NIP no coinciden. Revísalos o escríbele al taller.',
      );
    });

    test('has no problem when a complete pair matches', () {
      expect(problemFor('998 123 4567', '2580', credentialsMatch: true), isNull);
    });

    test('counts only the digits of the phone', () {
      expect(const LoginForm(phone: '998 123 4567', nip: '').phoneDigits, '9981234567');
    });
  });

  group('DemoClientAccess.owns', () {
    test('accepts the demo client phone and NIP', () {
      expect(DemoClientAccess.owns(phoneDigits: '9981234567', nip: '2580'), isTrue);
    });

    test('rejects any other NIP', () {
      expect(DemoClientAccess.owns(phoneDigits: '9981234567', nip: '1111'), isFalse);
    });

    test('rejects any other phone', () {
      expect(DemoClientAccess.owns(phoneDigits: '9980000000', nip: '2580'), isFalse);
    });
  });
}
