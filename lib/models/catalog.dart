import 'service_item.dart';

/// The workshop's active repairs, and the price of making a garment urgent.
class Catalog {
  const Catalog({required this.services, this.urgentSurchargeMxn = 0});

  /// Rows of `services`, in the order they arrive. A row of category `extra` is the
  /// urgent-garment charge ("Prenda urgente"), not a repair: its price becomes the surcharge.
  factory Catalog.fromRows(List<Map<String, dynamic>> rows) {
    final repairs = rows.where((row) => row['category'] != _urgentCategory);
    final urgentCharge = rows.where((row) => row['category'] == _urgentCategory).firstOrNull;
    return Catalog(
      services: [for (final row in repairs) _serviceFrom(row)],
      urgentSurchargeMxn: (urgentCharge?['base_price_mxn'] as int?) ?? 0,
    );
  }

  /// What `GET /api/client/services` answers: `[{id, name, category, basePriceMxn}]`.
  factory Catalog.fromApi(List<Object?> services) {
    return Catalog.fromRows([
      for (final service in services.cast<Map<String, dynamic>>())
        {
          'id': service['id'],
          'name': service['name'],
          'category': service['category'],
          'base_price_mxn': service['basePriceMxn'],
        },
    ]);
  }

  static const _urgentCategory = 'extra';

  final List<ServiceItem> services;

  /// 0 while the workshop has not priced urgency; the quote then names it without adding it.
  final int urgentSurchargeMxn;

  static ServiceItem _serviceFrom(Map<String, dynamic> row) {
    return ServiceItem(
      id: row['id'].toString(),
      title: row['name'] as String,
      priceMxn: row['base_price_mxn'] as int?,
    );
  }
}
