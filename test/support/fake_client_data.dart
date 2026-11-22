import 'package:calm_mobil/models/appointment_agenda.dart';
import 'package:calm_mobil/models/catalog.dart';
import 'package:calm_mobil/models/order.dart';
import 'package:calm_mobil/models/service_item.dart';
import 'package:calm_mobil/models/user_profile.dart';
import 'package:calm_mobil/services/client_data.dart';
import 'package:flutter/widgets.dart';

/// The panel's demo catalog, the data the Servicios design was drawn with.
const demoCatalog = Catalog(
  services: [
    ServiceItem(id: 'waist', title: 'Ajuste de cintura', priceMxn: 180),
    ServiceItem(id: 'party-dress', title: 'Ajuste de vestido de fiesta', priceMxn: 300),
    ServiceItem(id: 'custom-dress', title: 'Vestido Personalizado'),
    ServiceItem(id: 'zipper', title: 'Cambio de cierre', priceMxn: 130),
    ServiceItem(id: 'hem', title: 'Dobladillo de pantalón', priceMxn: 100),
    ServiceItem(id: 'patch', title: 'Parche', priceMxn: 40),
  ],
);

/// The panel's demo client orders, the one that needs the client first.
const demoOrders = [
  Order(ticket: '7720', work: 'Cambio de cierre de chamarra', status: OrderStatus.ready, amountMxn: 150),
  Order(
    ticket: '0937',
    work: 'Ajuste de cintura',
    status: OrderStatus.appointment,
    amountMxn: 180,
    appointmentOn: 'jueves 5 a las 11:00',
  ),
  Order(ticket: '5512', work: 'Ajuste de vestido de novia', status: OrderStatus.inProgress, amountMxn: 900),
  Order(
    ticket: '6540',
    work: 'Dobladillo de pantalón',
    status: OrderStatus.delivered,
    amountMxn: 100,
    deliveredOn: '12 de octubre',
  ),
];

/// The panel's demo agenda: the 1st is a Sunday, today is Wednesday the 4th at 15:00,
/// Sundays are closed and Friday the 6th was blocked.
const demoAgenda = AppointmentAgenda(
  monthName: 'Noviembre 2026',
  monthLongName: 'noviembre',
  daysInMonth: 30,
  firstWeekday: 7,
  today: 4,
  nowTime: '15:00',
  slotsByWeekday: {
    1: _businessSlots,
    2: _businessSlots,
    3: _businessSlots,
    4: _businessSlots,
    5: _businessSlots,
    6: _businessSlots,
    7: [],
  },
  blockedDays: {6},
  bookedSlots: {
    5: ['12:00', '12:30', '14:30'],
  },
);

const _businessSlots = [
  '10:00', '10:30', '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
  '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
];

/// The panel's sample client, owner of ticket 7720.
const demoProfile = UserProfile(fullName: 'Carlos Ruiz', phone: '998 123 4567');

/// Stands in for the database in screen tests. Set [fails] to make every load throw.
class FakeClientData implements ClientData {
  FakeClientData({
    this.catalogResult = demoCatalog,
    this.ordersResult = demoOrders,
    this.profileResult = demoProfile,
    this.agendaResult = demoAgenda,
  });

  Catalog catalogResult;
  List<Order> ordersResult;
  UserProfile profileResult;
  AppointmentAgenda agendaResult;
  bool fails = false;
  int loads = 0;

  @override
  Future<Catalog> catalog() => _answer(catalogResult);

  @override
  Future<List<Order>> orders() => _answer(ordersResult);

  @override
  Future<UserProfile> profile() => _answer(profileResult);

  @override
  Future<AppointmentAgenda> agenda() => _answer(agendaResult);

  Future<T> _answer<T>(T result) async {
    loads++;
    if (fails) throw StateError('the fake database is down');
    return result;
  }
}

/// [app] with [data] above it, as `main` provides the real one.
Widget withClientData(Widget app, {ClientData? data}) {
  return ClientDataScope(data: data ?? FakeClientData(), child: app);
}
