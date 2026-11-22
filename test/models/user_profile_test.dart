import 'package:calm_mobil/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile.fromRow', () {
    test('reads the name and groups the phone as the app writes it', () {
      final profile = UserProfile.fromRow({'name': 'María López', 'phone': '9981234567'});

      expect(profile.fullName, 'María López');
      expect(profile.phone, '998 123 4567');
      expect(profile.initials, 'ML');
    });
  });
}
