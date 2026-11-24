import 'package:flutter/widgets.dart';

import '../routes/app_routes.dart';
import '../services/client_data.dart';
import '../utils/app_constants.dart';

/// Her session ended (the API refused her token, or Supabase would not refresh it): signs her
/// out on this device and opens Entrada, with nothing to go back to, saying why.
///
/// The one way every screen tells it, so she never sees a connection error or the signed-in tabs
/// for a session that is gone.
Future<void> endSession(BuildContext context) async {
  final navigator = Navigator.of(context);
  await ClientDataScope.of(context).signOut();
  if (!navigator.mounted) return;
  navigator.pushNamedAndRemoveUntil(
    AppRoutes.initial,
    (_) => false,
    arguments: AppConstants.bookingSignedOut,
  );
}
