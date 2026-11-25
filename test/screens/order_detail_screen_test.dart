import 'package:calm_mobil/models/client_action.dart';
import 'package:calm_mobil/models/order.dart';
import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/screens/order_detail_screen.dart';
import 'package:calm_mobil/services/external_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_client_data.dart';

const readyOrder = Order(
  ticket: '7720',
  work: 'Cambio de cierre de chamarra',
  status: OrderStatus.ready,
  amountMxn: 150,
  scheduledDay: 'martes 17 de noviembre',
);
const inProgressOrder = Order(
  ticket: '5512',
  work: 'Ajuste de vestido de novia',
  status: OrderStatus.inProgress,
  amountMxn: 900,
);
const appointment = Order(
  ticket: '0937',
  work: 'Ajuste de cintura',
  status: OrderStatus.appointment,
  amountMxn: 180,
  appointmentOn: 'jueves 5 a las 11:00',
  scheduledDay: 'jueves 5 de noviembre',
  scheduledTime: '11:00',
);
const lateNoticeText = 'Faltan menos de 24 horas para tu cita: para cancelarla, escríbele al taller.';

void main() {
  testWidgets('shows a ready order with its progress and payment', (tester) async {
    await pumpDetail(tester, readyOrder);

    for (final text in [
      'Pedido',
      'Ticket 7720',
      'Cambio de cierre de chamarra',
      'Listo para recoger',
      'Recibido',
      'En proceso',
      'Listo',
      'Entregado',
      'Voy en camino',
      'Cómo llegar',
      'Pago',
      'Total, se paga en el taller',
      r'$150 MXN',
      'Más',
      'Agendar otra cita',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Cancelar cita'), findsNothing);
    expect(find.text('Escribir al taller'), findsNothing);
  });

  testWidgets('marks the current step in bold', (tester) async {
    await pumpDetail(tester, readyOrder);

    expect(tester.widget<Text>(find.text('Listo')).style!.fontWeight, FontWeight.w800);
    expect(tester.widget<Text>(find.text('Recibido')).style!.fontWeight, FontWeight.w500);
  });

  testWidgets('tells the workshop the client is on the way', (tester) async {
    await pumpDetail(tester, readyOrder);

    await tester.tap(find.text('Voy en camino'));
    await tester.pumpAndSettle();

    expect(find.text('Vas en camino'), findsOneWidget);
    expect(find.text('El taller ya sabe que vas en camino'), findsOneWidget);
    expect(find.text('Voy en camino'), findsNothing);
  });

  testWidgets('sends "Voy en camino" to the workshop for this order', (tester) async {
    final data = FakeClientData();
    await pumpDetail(tester, readyOrder, data: data);

    await tester.tap(find.text('Voy en camino'));
    await tester.pumpAndSettle();

    expect(data.onTheWayTickets, ['7720']);
  });

  testWidgets('says when the workshop does not take "Voy en camino"', (tester) async {
    const refusal = 'Tu pedido ya no está listo para recoger. Escríbele al taller.';
    await pumpDetail(tester, readyOrder, data: FakeClientData(actionResult: const ActionRefused(refusal)));

    await tester.tap(find.text('Voy en camino'));
    await tester.pumpAndSettle();

    expect(find.text(refusal), findsOneWidget);
    expect(find.text('Vas en camino'), findsNothing);
    expect(find.text('Voy en camino'), findsOneWidget);
  });

  testWidgets('takes her to Entrada, signed out, when her session ended on "Voy en camino"', (tester) async {
    final data = FakeClientData(signedIn: true, actionResult: const ActionSignedOut());
    await pumpDetail(tester, readyOrder, data: data);

    await tester.tap(find.text('Voy en camino'));
    await tester.pumpAndSettle();

    expect(data.onTheWayTickets, ['7720']);
    expect(data.signOuts, 1);
    expect(find.text(sessionEndedAtEntrada), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });

  testWidgets('shows an order the client is already on her way to', (tester) async {
    const onTheWay = Order(
      ticket: '7720',
      work: 'Cambio de cierre de chamarra',
      status: OrderStatus.onTheWay,
      amountMxn: 150,
    );
    await pumpDetail(tester, onTheWay);

    expect(find.text('Vas en camino'), findsOneWidget);
    expect(find.text('El taller ya sabe que vas en camino'), findsOneWidget);
    expect(find.text('Voy en camino'), findsNothing);
    expect(find.text('Listo'), findsOneWidget);
  });

  testWidgets('opens the workshop on Maps and confirms it', (tester) async {
    final opened = <Uri>[];
    await pumpDetail(tester, readyOrder, openLink: (link) async {
      opened.add(link);
      return true;
    });

    await tester.tap(find.text('Cómo llegar'));
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse('https://maps.app.goo.gl/nGsvenuYn4VE4rBfA?g_st=aw')]);
    expect(find.text('Abrimos Mapas con la dirección'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsNothing);
  });

  testWidgets('opens Maps from an appointment too', (tester) async {
    final opened = <Uri>[];
    await pumpDetail(tester, appointment, openLink: (link) async {
      opened.add(link);
      return true;
    });

    await tester.tap(find.text('Cómo llegar'));
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse('https://maps.app.goo.gl/nGsvenuYn4VE4rBfA?g_st=aw')]);
  });

  testWidgets('says so, with the address, when Maps cannot open', (tester) async {
    await pumpDetail(tester, readyOrder, openLink: (_) async => false);

    await tester.tap(find.text('Cómo llegar'));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos abrir Mapas. Estamos en Benito Juárez 223, casa 22, Los Héroes, Mz 10, 77517 Cancún, Q.R.'),
      findsOneWidget,
    );
    expect(find.text('Abrimos Mapas con la dirección'), findsNothing);
    expect(find.text('Cómo llegar'), findsOneWidget);
  });

  testWidgets('writes to the workshop on WhatsApp while the order is in progress', (tester) async {
    final opened = <Uri>[];
    await pumpDetail(tester, inProgressOrder, openLink: (link) async {
      opened.add(link);
      return true;
    });

    expect(find.text('Voy en camino'), findsNothing);
    expect(find.text('Cómo llegar'), findsNothing);

    await tester.tap(find.text('Escribir al taller'));
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse('https://wa.me/529983259560')]);
    expect(find.text('¿Te ayudamos?'), findsNothing);
    expect(find.textContaining('No pudimos abrir'), findsNothing);
  });

  testWidgets('says so, with the number, when WhatsApp cannot open', (tester) async {
    await pumpDetail(tester, inProgressOrder, openLink: (_) async => false);

    await tester.tap(find.text('Escribir al taller'));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos abrir WhatsApp. Escríbenos al 998 325 9560'), findsOneWidget);
    expect(find.text('Escribir al taller'), findsOneWidget);
  });

  testWidgets('shows an appointment with its quote and no progress bar', (tester) async {
    await pumpDetail(tester, appointment);

    for (final text in [
      'Ticket 0937',
      'Cita agendada',
      'Cómo llegar',
      'Cotización',
      'Cotización preliminar',
      r'$180 MXN',
      'Cancelar cita',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Entregado'), findsNothing);
  });

  testWidgets('shows the day and time of an appointment', (tester) async {
    await pumpDetail(tester, appointment);

    for (final text in ['Tu cita', 'Fecha', 'jueves 5 de noviembre', 'Hora', '11:00']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Entrega'), findsNothing);
  });

  testWidgets('shows the delivery day of an order, with no time', (tester) async {
    await pumpDetail(tester, readyOrder);

    for (final text in ['Entrega', 'Fecha', 'martes 17 de noviembre']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Hora'), findsNothing);
  });

  testWidgets('leaves out the dates section when the order has no date', (tester) async {
    await pumpDetail(tester, inProgressOrder);

    expect(find.text('Fecha'), findsNothing);
    expect(find.text('Hora'), findsNothing);
  });

  testWidgets('keeps the appointment when the client changes their mind', (tester) async {
    await pumpDetail(tester, appointment);

    await tester.tap(find.text('Cancelar cita'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cancelar tu cita?'), findsOneWidget);
    expect(
      find.text('Tu horario del jueves 5 a las 11:00 queda libre para alguien más.'),
      findsOneWidget,
    );

    await tester.tap(find.text('No, conservarla'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cancelar tu cita?'), findsNothing);
    expect(find.text('Ticket 0937'), findsOneWidget);
  });

  testWidgets('cancels the appointment and goes back to Entrada', (tester) async {
    await pumpDetail(tester, appointment);

    await tester.tap(find.text('Cancelar cita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, cancelar la cita'));
    await tester.pumpAndSettle();

    expect(find.text('entrada destino'), findsOneWidget);
  });

  testWidgets('takes her to Entrada, signed out, when her session ended on "Cancelar cita"', (tester) async {
    final data = FakeClientData(signedIn: true, actionResult: const ActionSignedOut());
    await pumpDetail(tester, appointment, data: data);

    await tester.tap(find.text('Cancelar cita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, cancelar la cita'));
    await tester.pumpAndSettle();

    expect(data.cancelledTickets, ['0937']);
    expect(data.signOuts, 1);
    expect(find.text(sessionEndedAtEntrada), findsOneWidget);
  });

  testWidgets('cancels this appointment on the server', (tester) async {
    final data = FakeClientData();
    await pumpDetail(tester, appointment, data: data);

    await tester.tap(find.text('Cancelar cita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, cancelar la cita'));
    await tester.pumpAndSettle();

    expect(data.cancelledTickets, ['0937']);
  });

  testWidgets('stays on the appointment when the workshop refuses to cancel it', (tester) async {
    const refusal = 'Ya no se puede cancelar desde la app: escríbele al taller.';
    await pumpDetail(tester, appointment, data: FakeClientData(actionResult: const ActionRefused(refusal)));

    await tester.tap(find.text('Cancelar cita'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, cancelar la cita'));
    await tester.pumpAndSettle();

    expect(find.text(refusal), findsOneWidget);
    expect(find.text('entrada destino'), findsNothing);
  });

  testWidgets('sends late cancellations to the workshop', (tester) async {
    const lateAppointment = Order(
      ticket: '0937',
      work: 'Ajuste de cintura',
      status: OrderStatus.appointment,
      amountMxn: 180,
      isCancellable: false,
    );
    await pumpDetail(tester, lateAppointment);

    expect(find.text('Cancelar cita'), findsNothing);
    expect(find.text(lateNoticeText), findsOneWidget);
  });

  testWidgets('goes back to Pedidos', (tester) async {
    await pumpDetail(tester, readyOrder);

    await tester.tap(find.widgetWithText(TextButton, 'Pedidos'));
    await tester.pumpAndSettle();

    expect(find.text('pedidos destino'), findsOneWidget);
  });

  testWidgets('takes the client to Servicios to book another appointment', (tester) async {
    await pumpDetail(tester, readyOrder);

    // The default 800×600 test view leaves the row under the translucent tab bar.
    await tester.ensureVisible(find.text('Agendar otra cita'));
    await tester.pump();
    await tester.tap(find.text('Agendar otra cita'));
    await tester.pumpAndSettle();

    expect(find.text('servicios destino'), findsOneWidget);
  });
}

Future<void> pumpDetail(WidgetTester tester, Order order, {FakeClientData? data, LinkOpener? openLink}) async {
  // Tall enough for every section without scrolling.
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(withClientData(data: data, openLink: openLink,
    MaterialApp(
      initialRoute: '${AppRoutes.orders}/detalle',
      routes: {
        AppRoutes.initial: entradaDestination,
        AppRoutes.orders: (_) => const Text('pedidos destino'),
        '${AppRoutes.orders}/detalle': (_) => OrderDetailScreen(order: order),
        AppRoutes.services: (_) => const Text('servicios destino'),
      },
    ),
  ));
}
