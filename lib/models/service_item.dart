/// A repair of the workshop's active catalog; without [priceMxn] it is quoted at the workshop.
class ServiceItem {
  const ServiceItem({required this.id, required this.title, this.priceMxn});

  final String id;
  final String title;
  final int? priceMxn;

  String get priceLabel => priceMxn == null ? 'A cotizar' : '\$$priceMxn';

  /// The panel's active catalog; deactivated services are not shown to clients.
  static const catalog = [
    ServiceItem(id: 'waist', title: 'Ajuste de cintura', priceMxn: 180),
    ServiceItem(id: 'party-dress', title: 'Ajuste de vestido de fiesta', priceMxn: 300),
    ServiceItem(id: 'custom-dress', title: 'Vestido Personalizado'),
    ServiceItem(id: 'zipper', title: 'Cambio de cierre', priceMxn: 130),
    ServiceItem(id: 'hem', title: 'Dobladillo de pantalón', priceMxn: 100),
    ServiceItem(id: 'patch', title: 'Parche', priceMxn: 40),
  ];
}
