import 'package:calm_mobil/models/profile_form.dart';
import 'package:flutter_test/flutter_test.dart';

const saved = '998 123 4567';

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

  test('saves the same phone without touching the NIP', () {
    const form = ProfileForm(phone: '998 123 4567', currentNip: '', newNip: '', savedPhone: saved);

    expect(form.changesPhone, isFalse);
    expect(form.changesNip, isFalse);
    expect(form.firstProblem(currentNipMatches: false), isNull);
  });

  test('asks for the current NIP to change the phone', () {
    const form = ProfileForm(phone: '998 765 4321', currentNip: '', newNip: '', savedPhone: saved);

    expect(form.changesPhone, isTrue);
    expectProblem(form, ProfileField.currentNip, 'Escribe tu NIP actual para cambiar tu celular.');
  });

  test('changes only the phone with the current NIP, leaving the NIP as it is', () {
    const form = ProfileForm(phone: '998 765 4321', currentNip: '2580', newNip: '', savedPhone: saved);

    expect(form.changesNip, isFalse);
    expect(form.firstProblem(currentNipMatches: true), isNull);
  });

  test('changes the phone and the NIP together', () {
    expectProblem(
      const ProfileForm(phone: '998 765 4321', currentNip: '2580', newNip: '12', savedPhone: saved),
      ProfileField.newNip,
      'El NIP nuevo necesita 4 dígitos.',
    );
    expect(
      const ProfileForm(phone: '998 765 4321', currentNip: '2580', newNip: '1357', savedPhone: saved)
          .firstProblem(currentNipMatches: true),
      isNull,
    );
  });

  test('reads the saved phone by its digits, whatever its spacing', () {
    const form = ProfileForm(phone: '9981234567', currentNip: '', newNip: '', savedPhone: saved);

    expect(form.changesPhone, isFalse);
  });

  test('asks for the ten phone digits first', () {
    expectProblem(
      const ProfileForm(phone: '998 765', currentNip: '1111', newNip: '', savedPhone: saved),
      ProfileField.phone,
      'Escribe tu celular a 10 dígitos.',
      currentNipMatches: false,
    );
  });

  test('changes the NIP once either NIP field has something', () {
    expect(const ProfileForm(phone: '998 123 4567', currentNip: '', newNip: '1', savedPhone: saved).changesNip, isTrue);
    expect(const ProfileForm(phone: '998 123 4567', currentNip: '2', newNip: '', savedPhone: saved).changesNip, isTrue);
  });

  test('checks the current NIP before the new one', () {
    expectProblem(
      const ProfileForm(phone: '998 123 4567', currentNip: '1111', newNip: '12', savedPhone: saved),
      ProfileField.currentNip,
      'Tu NIP actual no coincide.',
      currentNipMatches: false,
    );
  });

  test('asks for a four-digit new NIP', () {
    expectProblem(
      const ProfileForm(phone: '998 123 4567', currentNip: '2580', newNip: '12', savedPhone: saved),
      ProfileField.newNip,
      'El NIP nuevo necesita 4 dígitos.',
    );
  });

  test('asks for a new NIP different from the current one', () {
    expectProblem(
      const ProfileForm(phone: '998 123 4567', currentNip: '2580', newNip: '2580', savedPhone: saved),
      ProfileField.newNip,
      'El NIP nuevo debe ser distinto del actual.',
    );
  });

  test('has no problem with a valid NIP change', () {
    const form = ProfileForm(phone: '998 123 4567', currentNip: '2580', newNip: '1357', savedPhone: saved);

    expect(form.firstProblem(currentNipMatches: true), isNull);
  });
}
