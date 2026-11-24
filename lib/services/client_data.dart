import 'package:flutter/widgets.dart';

import '../models/booking.dart';
import '../models/booking_months.dart';
import '../models/catalog.dart';
import '../models/client_action.dart';
import '../models/order.dart';
import '../models/profile_update.dart';
import '../models/user_profile.dart';

/// What the client's screens read from the workshop and ask it to do, without knowing where it
/// lives.
///
/// The CALM API decides what the client reaches and may change from her session's access token;
/// this interface only names what each screen needs. See `odd/tasks/datos-reales-cliente.md` and
/// `odd/tasks/acciones-cliente.md`.
abstract interface class ClientData {
  /// Whether a session is open on this device, so the workshop already knows who she is.
  bool get isSignedIn;

  Future<Catalog> catalog();

  /// Her orders and her appointments that have no order yet, in the order Pedidos lists them.
  Future<List<Order>> orders();

  /// The signed-in client herself.
  Future<UserProfile> profile();

  /// This month's and next month's free slots, with or without a session; never who booked the
  /// others.
  Future<BookingMonths> agenda();

  /// Books [request], creating her account when the phone is new, and signs her in.
  Future<BookingOutcome> book(BookingRequest request);

  /// Cancels her appointment [ticket]: only one with no order yet, more than 24 hours ahead.
  Future<ClientActionOutcome> cancelAppointment(String ticket);

  /// Tells the workshop she is on her way to pick up her ready order [ticket].
  Future<ClientActionOutcome> markOnMyWay(String ticket);

  /// Saves Perfil: the phone she signs in with and, when she asks, a new NIP.
  Future<ProfileUpdateOutcome> saveProfile(ProfileChange change);

  /// Ends her session on this device.
  Future<void> signOut();
}

/// A read found her session ended: the workshop no longer knows who she is.
class SessionEnded implements Exception {
  const SessionEnded();

  @override
  String toString() => 'SessionEnded';
}

/// Hands [data] to every screen below it, including the ones pushed as routes or sheets.
class ClientDataScope extends InheritedWidget {
  const ClientDataScope({super.key, required this.data, required super.child});

  final ClientData data;

  static ClientData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ClientDataScope>();
    assert(scope != null, 'No ClientDataScope above this widget');
    return scope!.data;
  }

  @override
  bool updateShouldNotify(ClientDataScope oldWidget) => data != oldWidget.data;
}
