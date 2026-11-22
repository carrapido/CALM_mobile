import '../utils/telefono_formatter.dart';
import 'field_problem.dart';
import 'login_form.dart';

enum ProfileField { phone, currentNip, newNip }

/// What the client edits on Perfil: the phone always, the NIP only when they fill in either NIP field.
class ProfileForm {
  const ProfileForm({required this.phone, required this.currentNip, required this.newNip});

  final String phone;
  final String currentNip;
  final String newNip;

  String get phoneDigits => digitsOf(phone);

  bool get changesNip => currentNip.isNotEmpty || newNip.isNotEmpty;

  /// One problem at a time, in the order of the fields; null when ready to save.
  /// Whether [currentNip] is right is the API's call, so the caller passes it in.
  FieldProblem<ProfileField>? firstProblem({required bool currentNipMatches}) {
    if (digitsOf(phone).length != LoginForm.phoneLength) {
      return const FieldProblem(ProfileField.phone, 'Escribe tu celular a 10 dígitos.');
    }
    if (!changesNip) return null;
    if (!currentNipMatches) {
      return const FieldProblem(ProfileField.currentNip, 'Tu NIP actual no coincide.');
    }
    if (newNip.length != LoginForm.nipLength) {
      return const FieldProblem(ProfileField.newNip, 'El NIP nuevo necesita 4 dígitos.');
    }
    if (newNip == currentNip) {
      return const FieldProblem(ProfileField.newNip, 'El NIP nuevo debe ser distinto del actual.');
    }
    return null;
  }
}
