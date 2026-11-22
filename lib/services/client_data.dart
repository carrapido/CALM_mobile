import 'package:flutter/widgets.dart';

import '../models/catalog.dart';
import '../models/order.dart';

/// What the client's screens read from the workshop, without knowing where it comes from.
///
/// Row level security decides what the signed-in client reaches; this interface only names
/// what each screen needs. See `odd/tasks/datos-reales-cliente.md`.
abstract interface class ClientData {
  Future<Catalog> catalog();

  /// Her orders and her appointments that have no order yet, in the order Pedidos lists them.
  Future<List<Order>> orders();
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
