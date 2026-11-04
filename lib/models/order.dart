enum OrderStatus {
  received('Recibido'),
  inProgress('En proceso'),
  ready('¡Listo!'),
  delivered('Entregado');

  const OrderStatus(this.label);

  final String label;
}

class Order {
  final String ticket;
  final String description;
  final double price;
  final OrderStatus status;
  final String? deliveredOn;
  final String currency;

  const Order({
    required this.ticket,
    required this.description,
    required this.price,
    required this.status,
    this.deliveredOn,
    this.currency = 'MXN',
  });

  static const Order mockActive = Order(
    ticket: '7720',
    description: 'Cambio de cierre de chamarra',
    price: 150,
    status: OrderStatus.ready,
  );

  static const List<Order> mockPast = [
    Order(
      ticket: '6540',
      description: 'Dobladillo pantalón',
      price: 100,
      status: OrderStatus.delivered,
      deliveredOn: '12 Oct',
    ),
  ];

  bool get isReadyForPickup => status == OrderStatus.ready;

  String get formattedPrice => '\$${price.toStringAsFixed(0)} $currency';
}
