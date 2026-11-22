import '../utils/telefono_formatter.dart';

/// The signed-in client, as Perfil shows them.
class UserProfile {
  const UserProfile({required this.fullName, required this.phone});

  /// Her row of `clients`; the phone arrives as 10 digits and reads grouped, "998 123 4567".
  factory UserProfile.fromRow(Map<String, dynamic> row) {
    return UserProfile(
      fullName: row['name'] as String,
      phone: groupedPhone(row['phone'] as String? ?? ''),
    );
  }

  final String fullName;
  final String phone;

  /// First letters of the first two words: "Carlos Ruiz" → "CR".
  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}
