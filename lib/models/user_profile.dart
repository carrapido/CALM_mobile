/// The signed-in client, as Perfil shows them.
class UserProfile {
  const UserProfile({required this.fullName, required this.phone});

  /// The panel's sample client, owner of ticket 7720.
  static const UserProfile mock = UserProfile(fullName: 'Carlos Ruiz', phone: '998 123 4567');

  final String fullName;
  final String phone;

  /// First letters of the first two words: "Carlos Ruiz" → "CR".
  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}
