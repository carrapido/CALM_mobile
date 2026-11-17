import '../utils/telefono_formatter.dart';
import 'user_profile.dart';

/// Stand-in for the sign-in API: only the panel's demo client ([UserProfile.mock]) gets in.
/// The real check belongs to the API, which must throttle NIP attempts per phone.
class DemoClientAccess {
  DemoClientAccess._();

  static const _nip = '2580';

  static bool owns({required String phoneDigits, required String nip}) {
    return phoneDigits == digitsOf(UserProfile.mock.phone) && hasNip(nip);
  }

  static bool hasNip(String nip) => nip == _nip;
}
