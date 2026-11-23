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
  });

  group('LoginForm.incompleteProblem', () {
    test('is the first rule of the form that is not met', () {
      final problem = const LoginForm(phone: '998 123 4', nip: '').incompleteProblem;

      expect(problem?.field, LoginField.phone);
      expect(problem?.message, 'Al celular le faltan 3 dígitos.');
    });

    test('is null for a complete pair, whoever owns it', () {
      expect(const LoginForm(phone: '998 123 4567', nip: '1357').incompleteProblem, isNull);
    });
  });

  group('LoginForm.mismatch', () {
    test('blames the NIP with the workshop wording', () {
      expect(LoginForm.mismatch.field, LoginField.nip);
      expect(LoginForm.mismatch.message, 'Tu celular o tu NIP no coinciden. Revísalos o escríbele al taller.');
    });

    test('counts only the digits of the phone', () {
      expect(const LoginForm(phone: '998 123 4567', nip: '').phoneDigits, '9981234567');
    });
  });
}
