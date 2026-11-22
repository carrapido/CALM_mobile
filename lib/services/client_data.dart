import 'package:flutter/widgets.dart';

import '../models/appointment_agenda.dart';
import '../models/booking.dart';
import '../models/catalog.dart';
import '../models/order.dart';
import '../models/user_profile.dart';

/// What the client's screens read from the workshop and ask it to do, without knowing where it
/// lives.
///
/// Row level security and the workshop's functions decide what the client reaches and may change;
/// this interface only names what each screen needs. See `odd/tasks/datos-reales-cliente.md` and
/// `odd/tasks/acciones-cliente.md`.
abstract interface class ClientData {
  Future<Catalog> catalog();

  /// Her orders and her appointments that have no order yet, in the order Pedidos lists them.
  Future<List<Order>> orders();

  /// The signed-in client herself.
  Future<UserProfile> profile();

  /// This month's free slots, with or without a session; never who booked the others.
  Future<AppointmentAgenda> agenda();

  /// Books [request], creating her account when the phone is new, and signs her in.
  Future<BookingOutcome> book(BookingRequest request);
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
