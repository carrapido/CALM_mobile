import 'package:calm_mobil/models/order.dart';
import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/screens/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const readyOrder = Order(
  ticket: '7720',
  work: 'Cambio de cierre de chamarra',
  status: OrderStatus.ready,
  amountMxn: 150,
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
    await tester.pump();

    expect(find.text('Vas en camino'), findsOneWidget);
    expect(find.text('El taller ya sabe que vas en camino'), findsOneWidget);
    expect(find.text('Voy en camino'), findsNothing);
  });

  testWidgets('confirms that directions opened', (tester) async {
    await pumpDetail(tester, readyOrder);

    await tester.tap(find.text('Cómo llegar'));
    await tester.pump();

    expect(find.text('Abrimos Mapas con la dirección'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsNothing);
  });

  testWidgets('offers to write to the workshop while the order is in progress', (tester) async {
    await pumpDetail(tester, inProgressOrder);

    expect(find.text('Voy en camino'), findsNothing);
    expect(find.text('Cómo llegar'), findsNothing);

    await tester.tap(find.text('Escribir al taller'));
    await tester.pumpAndSettle();

    expect(find.text('¿Te ayudamos?'), findsOneWidget);
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

Future<void> pumpDetail(WidgetTester tester, Order order) async {
  await tester.pumpWidget(
    MaterialApp(
      initialRoute: '${AppRoutes.orders}/detalle',
      routes: {
        AppRoutes.initial: (_) => const Text('entrada destino'),
        AppRoutes.orders: (_) => const Text('pedidos destino'),
        '${AppRoutes.orders}/detalle': (_) => OrderDetailScreen(order: order),
        AppRoutes.services: (_) => const Text('servicios destino'),
      },
    ),
  );
}
