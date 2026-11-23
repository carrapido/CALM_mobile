import '../utils/spanish_dates.dart';

/// Where an order stands; [headline] is how the client reads it.
enum OrderStatus {
  appointment('Cita agendada'),
  received('Recibido'),
  inProgress('En proceso'),
  ready('Listo para recoger'),
  // She told the workshop with "Voy en camino"; the order still waits for her.
  onTheWay('Vas en camino'),
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
    this.scheduledDay,
    this.scheduledTime,
    this.isCancellable = true,
  });

  final String ticket;
  final String work;
  final OrderStatus status;
  final int amountMxn;

  /// Day and time of the appointment, worded as "jueves 5 a las 11:00".
  final String? appointmentOn;
  final String? deliveredOn;

  /// The appointment's day, or an order's delivery day, worded as "viernes 28 de noviembre".
  final String? scheduledDay;

  /// The appointment's time, "15:30"; an order is delivered on a day, with no time.
  final String? scheduledTime;

  /// An appointment can be cancelled until 24 hours before it.
  final bool isCancellable;

  bool get needsClient => status == OrderStatus.ready || status == OrderStatus.onTheWay;

  bool get isAppointment => status == OrderStatus.appointment;

  bool get isDelivered => status == OrderStatus.delivered;

  String get statusLine => isDelivered ? 'Entregado el $deliveredOn' : status.headline;

  String get formattedAmount => '\$$amountMxn MXN';

  /// The client's orders and the appointments that have no order yet, in the order Pedidos lists
  /// them: what needs her first, then appointments by date, then work in progress, then received
  /// work, then deliveries with the latest first. [now] is Cancún's wall clock.
  static List<Order> listFrom({
    required List<Map<String, dynamic>> orderRows,
    required List<Map<String, dynamic>> appointmentRows,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final listed = [
      for (final row in orderRows)
        if (_statusFrom(row['status'] as String) case final status?) _ListedOrder.fromOrder(row, status),
      for (final row in appointmentRows)
        if (!_hasOrder(row['orders']) && !_dateOf(row['scheduled_date']).isBefore(today))
          _ListedOrder.fromAppointment(row, now),
    ]..sort(_ListedOrder.compare);
    return [for (final entry in listed) entry.order];
  }

  static OrderStatus? _statusFrom(String value) {
    return switch (value) {
      'received' => OrderStatus.received,
      'inProgress' => OrderStatus.inProgress,
      'ready' => OrderStatus.ready,
      'onTheWay' => OrderStatus.onTheWay,
      'delivered' => OrderStatus.delivered,
      // A cancelled order is not listed.
      _ => null,
    };
  }

  /// PostgREST embeds a one-to-one relation as an object or null, and some versions as a list.
  static bool _hasOrder(Object? embedded) => embedded is List ? embedded.isNotEmpty : embedded != null;
}

/// An order with the moment it is sorted by: an appointment's start or an order's delivery date.
class _ListedOrder {
  const _ListedOrder(this.order, this.when);

  factory _ListedOrder.fromOrder(Map<String, dynamic> row, OrderStatus status) {
    final deliveryDate = _dateOf(row['delivery_date']);
    final order = Order(
      ticket: row['ticket'] as String,
      work: row['work'] as String,
      status: status,
      amountMxn: row['final_price_mxn'] as int,
      deliveredOn: status == OrderStatus.delivered ? dayAndMonth(deliveryDate) : null,
      scheduledDay: '${weekdayName(deliveryDate)} ${dayAndMonth(deliveryDate)}',
    );
    return _ListedOrder(order, deliveryDate);
  }

  factory _ListedOrder.fromAppointment(Map<String, dynamic> row, DateTime now) {
    final start = _dateOf(row['scheduled_date']).add(_timeOf(row['scheduled_time']));
    final order = Order(
      ticket: row['ticket'] as String,
      work: _servicesOf(row['appointment_services']).join(', '),
      status: OrderStatus.appointment,
      amountMxn: row['preliminary_total_mxn'] as int,
      appointmentOn: '${weekdayName(start)} ${start.day} a las ${clockTime(start)}',
      scheduledDay: '${weekdayName(start)} ${dayAndMonth(start)}',
      scheduledTime: clockTime(start),
      isCancellable: start.difference(now) > const Duration(hours: 24),
    );
    return _ListedOrder(order, start);
  }

  final Order order;
  final DateTime when;

  static const _rank = {
    OrderStatus.ready: 0,
    OrderStatus.onTheWay: 0,
    OrderStatus.appointment: 1,
    OrderStatus.inProgress: 2,
    OrderStatus.received: 3,
    OrderStatus.delivered: 4,
  };

  static int compare(_ListedOrder a, _ListedOrder b) {
    final byRank = _rank[a.order.status]!.compareTo(_rank[b.order.status]!);
    if (byRank != 0) return byRank;
    return a.order.isDelivered ? b.when.compareTo(a.when) : a.when.compareTo(b.when);
  }

  static Iterable<String> _servicesOf(Object? embedded) sync* {
    for (final link in embedded as List? ?? const []) {
      final name = ((link as Map)['services'] as Map?)?['name'] as String?;
      if (name != null) yield name;
    }
  }

  static Duration _timeOf(Object? value) {
    final [hours, minutes, ...] = (value as String).split(':').map(int.parse).toList();
    return Duration(hours: hours, minutes: minutes);
  }
}

/// A `date` column, "2026-11-26", as a day with no time zone.
DateTime _dateOf(Object? value) => DateTime.parse(value as String);
