import 'package:calm_mobil/models/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Catalog.fromRows', () {
    const waist = {'id': 7, 'name': 'Ajuste de cintura', 'category': 'arreglo', 'base_price_mxn': 180};
    const bridal = {
      'id': 10,
      'name': 'Arreglo de vestido de novia',
      'category': 'arreglo',
      'base_price_mxn': null,
    };
    const urgent = {'id': 13, 'name': 'Prenda urgente', 'category': 'extra', 'base_price_mxn': 80};

    test('lists the repairs in the order they arrive', () {
      final catalog = Catalog.fromRows([waist, bridal]);

      expect(catalog.services.map((service) => service.title), [
        'Ajuste de cintura',
        'Arreglo de vestido de novia',
      ]);
      expect(catalog.services.first.id, '7');
      expect(catalog.services.first.priceMxn, 180);
    });

    test('keeps an unpriced repair to be quoted at the workshop', () {
      final bridalDress = Catalog.fromRows([bridal]).services.single;

      expect(bridalDress.priceMxn, isNull);
      expect(bridalDress.priceLabel, 'A cotizar');
    });

    test('takes the urgent charge out of the repairs and uses its price as the surcharge', () {
      final catalog = Catalog.fromRows([waist, urgent]);

      expect(catalog.services.map((service) => service.title), ['Ajuste de cintura']);
      expect(catalog.urgentSurchargeMxn, 80);
    });

    test('has no surcharge when the workshop defined no urgent charge', () {
      expect(Catalog.fromRows([waist]).urgentSurchargeMxn, 0);
    });
  });
}
