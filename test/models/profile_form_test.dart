import 'package:calm_mobil/models/profile_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void expectProblem(
    ProfileForm form,
    ProfileField field,
    String message, {
    bool currentNipMatches = true,
  }) {
    final problem = form.firstProblem(currentNipMatches: currentNipMatches);
    expect(problem?.field, field);
    expect(problem?.message, message);
  }

  test('saves a new phone without touching the NIP', () {
    const form = ProfileForm(phone: '998 765 4321', currentNip: '', newNip: '');

    expect(form.changesNip, isFalse);
    expect(form.firstProblem(currentNipMatches: false), isNull);
  });

  test('asks for the ten phone digits first', () {
    expectProblem(
      const ProfileForm(phone: '998 765', currentNip: '1111', newNip: ''),
      ProfileField.phone,
      'Escribe tu celular a 10 dígitos.',
      currentNipMatches: false,
    );
  });

  test('changes the NIP once either NIP field has something', () {
    expect(const ProfileForm(phone: '998 123 4567', currentNip: '', newNip: '1').changesNip, isTrue);
    expect(const ProfileForm(phone: '998 123 4567', currentNip: '2', newNip: '').changesNip, isTrue);
  });

  test('checks the current NIP before the new one', () {
    expectProblem(
      const ProfileForm(phone: '998 123 4567', currentNip: '1111', newNip: '12'),
      ProfileField.currentNip,
      'Tu NIP actual no coincide.',
      currentNipMatches: false,
    );
  });

  test('asks for a four-digit new NIP', () {
    expectProblem(
      const ProfileForm(phone: '998 123 4567', currentNip: '2580', newNip: '12'),
      ProfileField.newNip,
      'El NIP nuevo necesita 4 dígitos.',
    );
  });

  test('asks for a new NIP different from the current one', () {
    expectProblem(
      const ProfileForm(phone: '998 123 4567', currentNip: '2580', newNip: '2580'),
      ProfileField.newNip,
      'El NIP nuevo debe ser distinto del actual.',
    );
  });

  test('has no problem with a valid NIP change', () {
    const form = ProfileForm(phone: '998 123 4567', currentNip: '2580', newNip: '1357');

    expect(form.firstProblem(currentNipMatches: true), isNull);
  });
}
