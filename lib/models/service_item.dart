class ServiceItem {
  final String id;
  final String title;
  final double? price;
  final String? customPrice;
  final String currency;

  const ServiceItem({
    required this.id,
    required this.title,
    this.price,
    this.customPrice,
    this.currency = 'MXN',
  });

  String get priceDisplay {
    if (customPrice != null) return customPrice!;
    if (price != null) return '\$${price!.toStringAsFixed(0)}';
    return '';
  }

  static List<ServiceItem> get mockServices => const [
        ServiceItem(
          id: '1',
          title: 'Ajuste de cintura',
          price: 180,
        ),
        ServiceItem(
          id: '2',
          title: 'Ajuste de vestido de fiesta',
          price: 300,
        ),
        ServiceItem(
          id: '3',
          title: 'Vestido Personalizado',
          customPrice: 'A cotizar',
        ),
        ServiceItem(
          id: '4',
          title: 'Cambio de cierre',
          price: 130,
        ),
        ServiceItem(
          id: '5',
          title: 'Dobladillo de pantalón',
          price: 100,
        ),
        ServiceItem(
          id: '6',
          title: 'Parche',
          price: 40,
        ),
      ];
}