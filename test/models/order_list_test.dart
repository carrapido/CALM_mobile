import 'package:calm_mobil/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

// Sunday, November 22 2026, 17:40 on Cancún's wall clock.
final now = DateTime(2026, 11, 22, 17, 40);

Map<String, dynamic> orderRow({
  String ticket = '7720',
  String work = 'Cambio de cierre de chamarra',
  String status = 'ready',
  int price = 150,
  String deliveryDate = '2026-11-17',
}) {
  return {
    'ticket': ticket,
    'work': work,
    'status': status,
    'final_price_mxn': price,
    'delivery_date': deliveryDate,
  };
}

Map<String, dynamic> appointmentRow({
  String ticket = '4821',
  String date = '2026-11-26',
  String time = '11:00:00',
  int total = 230,
  List<String> services = const ['Dobladillo de pantalón', 'Cambio de cierre'],
  Object? order,
}) {
  return {
    'ticket': ticket,
    'scheduled_date': date,
    'scheduled_time': time,
    'preliminary_total_mxn': total,
    'appointment_services': [
      for (final name in services) {'services': {'name': name}},
    ],
    'orders': order,
  };
}

List<Order> listFrom({List<Map<String, dynamic>> orders = const [], List<Map<String, dynamic>> appointments = const []}) {
  return Order.listFrom(orderRows: orders, appointmentRows: appointments, now: now);
}

void main() {
  group('Order.listFrom', () {
    test('reads an order row', () {
      final order = listFrom(orders: [orderRow()]).single;

      expect(order.ticket, '7720');
      expect(order.work, 'Cambio de cierre de chamarra');
      expect(order.status, OrderStatus.ready);
      expect(order.formattedAmount, r'$150 MXN');
    });

    test('reads every status the panel sets', () {
      final statuses = listFrom(orders: [
        orderRow(ticket: '1', status: 'received'),
        orderRow(ticket: '2', status: 'inProgress'),
        orderRow(ticket: '3', status: 'ready'),
        orderRow(ticket: '5', status: 'onTheWay'),
        orderRow(ticket: '4', status: 'delivered'),
      ]).map((order) => order.status);

      expect(statuses, containsAll(OrderStatus.values.where((s) => s != OrderStatus.appointment)));
    });

    test('reads an order the client is on her way to as such, still needing her', () {
      final order = listFrom(orders: [orderRow(status: 'onTheWay')]).single;

      expect(order.statusLine, 'Vas en camino');
      expect(order.needsClient, isTrue);
    });

    test('leaves cancelled orders out', () {
      expect(listFrom(orders: [orderRow(status: 'cancelled')]), isEmpty);
    });

    test('words an order\'s delivery day, with no time', () {
      final order = listFrom(orders: [orderRow(deliveryDate: '2026-11-17')]).single;

      expect(order.scheduledDay, 'martes 17 de noviembre');
      expect(order.scheduledTime, isNull);
    });

    test('words a delivered order with its delivery date', () {
      final order = listFrom(orders: [orderRow(status: 'delivered', deliveryDate: '2026-11-13')]).single;

      expect(order.statusLine, 'Entregado el 13 de noviembre');
    });

    test('lists an appointment without an order as a booked appointment', () {
      final appointment = listFrom(appointments: [appointmentRow()]).single;

      expect(appointment.ticket, '4821');
      expect(appointment.status, OrderStatus.appointment);
      expect(appointment.work, 'Dobladillo de pantalón, Cambio de cierre');
      expect(appointment.formattedAmount, r'$230 MXN');
      expect(appointment.appointmentOn, 'jueves 26 a las 11:00');
      expect(appointment.scheduledDay, 'jueves 26 de noviembre');
      expect(appointment.scheduledTime, '11:00');
    });

    test('leaves out an appointment that already became an order', () {
      expect(listFrom(appointments: [appointmentRow(order: {'id': 2})]), isEmpty);
      expect(listFrom(appointments: [appointmentRow(order: [{'id': 2}])]), isEmpty);
      expect(listFrom(appointments: [appointmentRow(order: const [])]), hasLength(1));
    });

    test('lists an appointment from its day on', () {
      final appointments = listFrom(appointments: [
        appointmentRow(ticket: 'past', date: '2026-11-21'),
        appointmentRow(ticket: 'today', date: '2026-11-22', time: '10:00:00'),
      ]);

      expect(appointments.map((a) => a.ticket), ['today']);
    });

    test('lets the client cancel only more than 24 hours ahead', () {
      final appointments = listFrom(appointments: [
        appointmentRow(ticket: 'far', date: '2026-11-23', time: '18:00:00'),
        appointmentRow(ticket: 'near', date: '2026-11-23', time: '17:00:00'),
      ]);

      expect({for (final a in appointments) a.ticket: a.isCancellable}, {'far': true, 'near': false});
    });

    test('puts what needs the client first and the latest delivery first', () {
      final tickets = listFrom(
        orders: [
          orderRow(ticket: 'received', status: 'received'),
          orderRow(ticket: 'old', status: 'delivered', deliveryDate: '2026-10-12'),
          orderRow(ticket: 'progress', status: 'inProgress'),
          orderRow(ticket: 'new', status: 'delivered', deliveryDate: '2026-11-13'),
          orderRow(ticket: 'ready', status: 'ready'),
        ],
        appointments: [
          appointmentRow(ticket: 'later', date: '2026-11-28'),
          appointmentRow(ticket: 'sooner', date: '2026-11-24'),
        ],
      ).map((order) => order.ticket);

      expect(tickets, ['ready', 'sooner', 'later', 'progress', 'received', 'new', 'old']);
    });
  });
}
