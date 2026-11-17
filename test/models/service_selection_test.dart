import 'package:calm_mobil/models/service_item.dart';
import 'package:calm_mobil/models/service_selection.dart';
import 'package:flutter_test/flutter_test.dart';

const waist = ServiceItem(id: 'waist', title: 'Ajuste de cintura', priceMxn: 180);
const zipper = ServiceItem(id: 'zipper', title: 'Cambio de cierre', priceMxn: 130);
const customDress = ServiceItem(id: 'custom-dress', title: 'Vestido Personalizado');

void main() {
  group('summary', () {
    test('counts one repair in singular', () {
      expect(const ServiceSelection(services: [waist]).summary, '1 arreglo');
    });

    test('counts several repairs in plural and flags urgency', () {
      const selection = ServiceSelection(services: [waist, zipper], isUrgent: true);
      expect(selection.summary, '2 arreglos · urgente');
    });
  });

  group('quote', () {
    test('adds up the priced services', () {
      expect(const ServiceSelection(services: [waist, zipper]).quote, r'$310 MXN');
    });

    test('leaves unpriced services to be quoted', () {
      expect(const ServiceSelection(services: [waist, customDress]).quote, r'$180 MXN + a cotizar');
    });

    test('says everything is quoted at the workshop when nothing has a price', () {
      expect(const ServiceSelection(services: [customDress]).quote, 'A cotizar en el taller');
    });

    test('mentions the urgency charge while its amount is not set', () {
      const selection = ServiceSelection(services: [waist], isUrgent: true);
      expect(selection.quote, r'$180 MXN + cargo por urgencia');
    });

    test('adds the urgency charge once its amount is set', () {
      const selection = ServiceSelection(services: [waist], isUrgent: true, urgentSurchargeMxn: 50);
      expect(selection.quote, r'$230 MXN');
    });
  });

  group('names', () {
    test('lists the services and flags urgency', () {
      const selection = ServiceSelection(services: [waist, zipper], isUrgent: true);
      expect(selection.names, 'Ajuste de cintura, Cambio de cierre · Urgente');
    });
  });

  group('ServiceItem.priceLabel', () {
    test('shows the price or that it is quoted', () {
      expect(waist.priceLabel, r'$180');
      expect(customDress.priceLabel, 'A cotizar');
    });
  });
}
