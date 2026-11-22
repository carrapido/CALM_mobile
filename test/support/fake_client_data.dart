import 'package:calm_mobil/models/catalog.dart';
import 'package:calm_mobil/models/service_item.dart';
import 'package:calm_mobil/services/client_data.dart';
import 'package:flutter/widgets.dart';

/// The panel's demo catalog, the data the Servicios design was drawn with.
const demoCatalog = Catalog(
  services: [
    ServiceItem(id: 'waist', title: 'Ajuste de cintura', priceMxn: 180),
    ServiceItem(id: 'party-dress', title: 'Ajuste de vestido de fiesta', priceMxn: 300),
    ServiceItem(id: 'custom-dress', title: 'Vestido Personalizado'),
    ServiceItem(id: 'zipper', title: 'Cambio de cierre', priceMxn: 130),
    ServiceItem(id: 'hem', title: 'Dobladillo de pantalón', priceMxn: 100),
    ServiceItem(id: 'patch', title: 'Parche', priceMxn: 40),
  ],
);

/// Stands in for the database in screen tests. Set [fails] to make every load throw.
class FakeClientData implements ClientData {
  FakeClientData({this.catalogResult = demoCatalog});

  Catalog catalogResult;
  bool fails = false;
  int loads = 0;

  @override
  Future<Catalog> catalog() => _answer(catalogResult);

  Future<T> _answer<T>(T result) async {
    loads++;
    if (fails) throw StateError('the fake database is down');
    return result;
  }
}

/// [app] with [data] above it, as `main` provides the real one.
Widget withClientData(Widget app, {ClientData? data}) {
  return ClientDataScope(data: data ?? FakeClientData(), child: app);
}
