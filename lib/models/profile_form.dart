import '../utils/telefono_formatter.dart';
import 'field_problem.dart';
import 'login_form.dart';

enum ProfileField { phone, currentNip, newNip }

/// What the client edits on Perfil: the phone always, the NIP only when they fill in a NIP field.
/// A new phone needs her current NIP; the current NIP alone, with a new phone, changes no NIP.
class ProfileForm {
  const ProfileForm({
    required this.phone,
    required this.currentNip,
    required this.newNip,
    required this.savedPhone,
  });

  /// The API words a missing current NIP the same way (`400 current_nip`).
  static const missingCurrentNip = 'Escribe tu NIP actual para cambiar tu celular.';

  final String phone;
  final String currentNip;
  final String newNip;

  /// The phone the workshop has for her now, in any spacing.
  final String savedPhone;

  String get phoneDigits => digitsOf(phone);

  bool get changesPhone => digitsOf(phone) != digitsOf(savedPhone);

  bool get changesNip => newNip.isNotEmpty || (currentNip.isNotEmpty && !changesPhone);

  /// One problem at a time, in the order of the fields; null when ready to save.
  /// Whether [currentNip] is right is the API's call, so the caller passes it in.
  FieldProblem<ProfileField>? firstProblem({required bool currentNipMatches}) {
    if (digitsOf(phone).length != LoginForm.phoneLength) {
      return const FieldProblem(ProfileField.phone, 'Escribe tu celular a 10 dígitos.');
    }
    if (changesPhone && currentNip.isEmpty) {
      return const FieldProblem(ProfileField.currentNip, missingCurrentNip);
    }
    if (!changesNip && !changesPhone) return null;
    if (!currentNipMatches) {
      return const FieldProblem(ProfileField.currentNip, 'Tu NIP actual no coincide.');
    }
    if (!changesNip) return null;
    if (newNip.length != LoginForm.nipLength) {
      return const FieldProblem(ProfileField.newNip, 'El NIP nuevo necesita 4 dígitos.');
    }
    if (newNip == currentNip) {
      return const FieldProblem(ProfileField.newNip, 'El NIP nuevo debe ser distinto del actual.');
    }
    return null;
  }
}
