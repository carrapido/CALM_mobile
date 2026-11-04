class ServiceItem {
  final String id;
  final String category;
  final String title;
  final double price;
  final String currency;

  const ServiceItem({
    required this.id,
    required this.category,
    required this.title,
    required this.price,
    this.currency = 'MXN',
  });

  static List<ServiceItem> get mockServices => const [
        ServiceItem(
          id: '1',
          category: 'Básicos',
          title: 'Dobladillo de pantalón',
          price: 100,
        ),
        ServiceItem(
          id: '2',
          category: 'Ajustes',
          title: 'Ajuste de cintura',
          price: 180,
        ),
        ServiceItem(
          id: '3',
          category: 'Reparaciones',
          title: 'Cambio de cierre',
          price: 130,
        ),
        ServiceItem(
          id: '4',
          category: 'Gala',
          title: 'Vestido de fiesta',
          price: 300,
        ),
        ServiceItem(
          id: '5',
          category: 'Express',
          title: 'Parche o zurcido',
          price: 40,
        ),
      ];
}