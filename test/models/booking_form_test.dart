import 'package:calm_mobil/models/booking_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void expectProblem(BookingForm form, BookingField field, String message) {
    final problem = form.firstProblem();
    expect(problem?.field, field);
    expect(problem?.message, message);
  }

  test('asks for the name first, ignoring blank spaces', () {
    expectProblem(
      const BookingForm(name: '  ', phone: '998 123 4567', nip: '2580'),
      BookingField.name,
      'Escribe tu nombre.',
    );
  });

  test('asks for all ten phone digits', () {
    expectProblem(
      const BookingForm(name: 'Ana', phone: '998 123 456', nip: '2580'),
      BookingField.phone,
      'Escribe los 10 dígitos de tu celular.',
    );
  });

  test('asks for a four-digit NIP', () {
    expectProblem(
      const BookingForm(name: 'Ana', phone: '998 123 4567', nip: '258'),
      BookingField.nip,
      'Elige un NIP de 4 dígitos.',
    );
  });

  test('has no problem when everything is filled in', () {
    expect(const BookingForm(name: 'Ana', phone: '998 123 4567', nip: '2580').firstProblem(), isNull);
  });
}
