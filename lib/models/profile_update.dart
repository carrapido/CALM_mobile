import 'profile_form.dart';
import 'user_profile.dart';

/// What Perfil sends: the phone always, both NIPs only when the client changes her NIP.
class ProfileChange {
  const ProfileChange({required this.phoneDigits, this.currentNip = '', this.newNip = ''});

  final String phoneDigits;
  final String currentNip;
  final String newNip;
}

/// How the workshop answered Perfil. It checks the current NIP, never the app.
sealed class ProfileUpdateOutcome {
  const ProfileUpdateOutcome();
}

class ProfileSaved extends ProfileUpdateOutcome {
  const ProfileSaved(this.profile);

  final UserProfile profile;
}

/// Not saved: her session ended, so she has to sign in again.
class ProfileSignedOut extends ProfileUpdateOutcome {
  const ProfileSignedOut();
}

/// Refused for a reason worded for the client; [field] turns red when it is one of hers.
class ProfileRefused extends ProfileUpdateOutcome {
  const ProfileRefused(this.message, {this.field});

  final String message;
  final ProfileField? field;
}
