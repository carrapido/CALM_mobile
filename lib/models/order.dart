/// Where an order stands; [headline] is how the client reads it.
enum OrderStatus {
  appointment('Cita agendada'),
  received('Recibido'),
  inProgress('En proceso'),
  ready('Listo para recoger'),
  delivered('Entregado');

  const OrderStatus(this.headline);

  final String headline;
}

class Order {
  const Order({
    required this.ticket,
    required this.work,
    required this.status,
    required this.amountMxn,
    this.appointmentOn,
    this.deliveredOn,
    this.isCancellable = true,
  });

  final String ticket;
  final String work;
  final OrderStatus status;
  final int amountMxn;

  /// Day and time of the appointment, worded as "jueves 5 a las 11:00".
  final String? appointmentOn;
  final String? deliveredOn;

  /// An appointment can be cancelled until 24 hours before it.
  final bool isCancellable;

  bool get needsClient => status == OrderStatus.ready;

  bool get isAppointment => status == OrderStatus.appointment;

  bool get isDelivered => status == OrderStatus.delivered;

  String get statusLine => isDelivered ? 'Entregado el $deliveredOn' : status.headline;

  String get formattedAmount => '\$$amountMxn MXN';

  /// The panel's demo client orders, the one that needs the client first.
  static const demoOrders = [
    Order(
      ticket: '7720',
      work: 'Cambio de cierre de chamarra',
      status: OrderStatus.ready,
      amountMxn: 150,
    ),
    Order(
      ticket: '0937',
      work: 'Ajuste de cintura',
      status: OrderStatus.appointment,
      amountMxn: 180,
      appointmentOn: 'jueves 5 a las 11:00',
    ),
    Order(
      ticket: '5512',
      work: 'Ajuste de vestido de novia',
      status: OrderStatus.inProgress,
      amountMxn: 900,
    ),
    Order(
      ticket: '6540',
      work: 'Dobladillo de pantalón',
      status: OrderStatus.delivered,
      amountMxn: 100,
      deliveredOn: '12 de octubre',
    ),
  ];
}
