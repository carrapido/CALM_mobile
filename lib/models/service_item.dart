/// A repair of the workshop's active catalog; without [priceMxn] it is quoted at the workshop.
class ServiceItem {
  const ServiceItem({required this.id, required this.title, this.priceMxn});

  final String id;
  final String title;
  final int? priceMxn;

  String get priceLabel => priceMxn == null ? 'A cotizar' : '\$$priceMxn';
}
