/// Datos del cliente que muestra la pantalla de perfil.
class UserProfile {
  final String fullName;
  final String phone;
  final String ticket;

  const UserProfile({
    required this.fullName,
    required this.phone,
    required this.ticket,
  });

  static const UserProfile mock = UserProfile(
    fullName: 'Carlos Ruiz',
    phone: '998 123 4567',
    ticket: '7720',
  );
}
