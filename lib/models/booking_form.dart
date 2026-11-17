import '../utils/telefono_formatter.dart';
import 'field_problem.dart';
import 'login_form.dart';

enum BookingField { name, phone, nip }

/// The client's data on the Agendar sheet; the phone and NIP become their sign-in.
class BookingForm {
  const BookingForm({required this.name, required this.phone, required this.nip});

  final String name;
  final String phone;
  final String nip;

  /// One problem at a time, in the order of the fields; null when ready to confirm.
  FieldProblem<BookingField>? firstProblem() {
    if (name.trim().isEmpty) {
      return const FieldProblem(BookingField.name, 'Escribe tu nombre.');
    }
    if (digitsOf(phone).length != LoginForm.phoneLength) {
      return const FieldProblem(BookingField.phone, 'Escribe los 10 dígitos de tu celular.');
    }
    if (nip.length != LoginForm.nipLength) {
      return const FieldProblem(BookingField.nip, 'Elige un NIP de 4 dígitos.');
    }
    return null;
  }
}
