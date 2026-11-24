import 'package:calm_mobil/models/appointment_agenda.dart';
import 'package:calm_mobil/models/booking.dart';
import 'package:calm_mobil/models/booking_form.dart';
import 'package:calm_mobil/models/booking_months.dart';
import 'package:calm_mobil/models/order.dart';
import 'package:calm_mobil/models/service_item.dart';
import 'package:calm_mobil/models/service_selection.dart';
import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/themes/app_colors.dart';
import 'package:calm_mobil/widgets/schedule_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_client_data.dart';

const waistSelection = ServiceSelection(
  services: [ServiceItem(id: 'waist', title: 'Ajuste de cintura', priceMxn: 180)],
);

void main() {
  testWidgets('starts on the first free day with the chosen repairs', (tester) async {
    await openSheet(tester);

    for (final text in [
      'Cancelar',
      'Agendar cita',
      'Ajuste de cintura',
      r'Cotización preliminar: $180 MXN',
      'Día',
      'Noviembre 2026',
      'Hora',
      'Gira para elegir. Las horas en gris no están disponibles.',
      'Tus datos',
      'Confirmar · Jue 5, 11:00',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('ignores days without free slots', (tester) async {
    final semantics = tester.ensureSemantics();
    await openSheet(tester);

    await tester.tap(find.bySemanticsLabel('viernes 6 de noviembre, no disponible'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar · Jue 5, 11:00'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('keeps the time when the new day has it free', (tester) async {
    final semantics = tester.ensureSemantics();
    await openSheet(tester);

    await tester.tap(find.bySemanticsLabel('viernes 13 de noviembre'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar · Vie 13, 11:00'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('moves to the nearest free time when the new day lacks it', (tester) async {
    final semantics = tester.ensureSemantics();
    await openSheet(tester);

    await tester.tap(find.bySemanticsLabel('Hoy, miércoles 4 de noviembre'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar · Hoy, 15:30'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('asks for the missing data before confirming', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Confirmar · Jue 5, 11:00'));
    await tester.pump();

    expect(find.text('Escribe tu nombre.'), findsOneWidget);
  });

  testWidgets('confirms the appointment and shows its ticket', (tester) async {
    await openSheet(tester);

    await confirmWithData(tester);

    for (final text in [
      'Listo',
      'Cita agendada',
      'Jue 5, 11:00 · Ajuste de cintura',
      'Tu ticket',
      '0937',
      'Tu cita ya aparece en Pedidos. Muestra este ticket en el taller.',
      'Ver mi cita',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('opens the new appointment from "Ver mi cita"', (tester) async {
    await openSheet(tester);
    await confirmWithData(tester);

    await tester.tap(find.text('Ver mi cita'));
    await tester.pumpAndSettle();

    expect(find.text('detalle 0937 Cita agendada jueves 5 de noviembre 11:00'), findsOneWidget);
  });

  testWidgets('closes with Cancelar', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Agendar cita'), findsNothing);
  });

  testWidgets('says when the month has no free slot left', (tester) async {
    const full = AppointmentAgenda(
      year: 2026,
      month: 11,
      monthName: 'Noviembre 2026',
      monthLongName: 'noviembre',
      daysInMonth: 30,
      firstWeekday: 7,
      today: 30,
      nowTime: '18:00',
      slotsByWeekday: {1: ['10:00', '17:30']},
      blockedDays: {},
      bookedSlots: {},
    );
    await openSheet(tester, data: FakeClientData(agendaResult: const BookingMonths([full])));

    expect(find.text('Ya no quedan horarios libres este mes. Escríbele al taller.'), findsOneWidget);
    expect(find.textContaining('Confirmar'), findsNothing);
  });

  testWidgets('books on the server what the client chose', (tester) async {
    final data = FakeClientData();
    await openSheet(tester, data: data);

    await confirmWithData(tester);

    final booking = data.bookings.single;
    expect(booking.contact?.name, 'Ana López');
    expect(booking.contact?.phoneDigits, '9981234567');
    expect(booking.contact?.nip, '1357');
    expect(booking.date, '2026-11-05');
    expect(booking.time, '11:00');
    expect(booking.selection.services.map((service) => service.id), ['waist']);
    expect(booking.selection.isUrgent, isFalse);
  });

  testWidgets('does not book while the data is incomplete', (tester) async {
    final data = FakeClientData();
    await openSheet(tester, data: data);

    await tester.tap(find.text('Confirmar · Jue 5, 11:00'));
    await tester.pump();

    expect(data.bookings, isEmpty);
  });

  testWidgets('shows the ticket the workshop assigned', (tester) async {
    await openSheet(tester, data: FakeClientData(bookingResult: const BookingConfirmed('4821')));

    await confirmWithData(tester);

    expect(find.text('4821'), findsOneWidget);
    expect(find.text('Cita agendada'), findsOneWidget);
  });

  testWidgets('says why the workshop refused the booking and marks the field', (tester) async {
    const refusal = BookingRefused(
      'Tu celular o tu NIP no coinciden. Revísalos o escríbele al taller.',
      field: BookingField.nip,
    );
    await openSheet(tester, data: FakeClientData(bookingResult: refusal));

    await confirmWithData(tester);

    expect(find.text(refusal.message), findsOneWidget);
    expect(find.text('Cita agendada'), findsNothing);
    expect(tester.widget<Text>(find.text('NIP')).style?.color, AppColors.errorText);
  });

  testWidgets('moves off a slot that was taken meanwhile', (tester) async {
    await openSheet(tester, data: FakeClientData(bookingResult: const BookingSlotTaken()));

    await confirmWithData(tester);

    expect(find.text('Ese horario se acaba de ocupar. Elige otro.'), findsOneWidget);
    expect(find.text('Confirmar · Jue 5, 10:30'), findsOneWidget);
  });

  testWidgets('moves to the next month and back', (tester) async {
    await openSheet(tester, data: FakeClientData(agendaResult: const BookingMonths([demoAgenda, demoNextAgenda])));

    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Diciembre 2026'), findsOneWidget);
    expect(find.text('Confirmar · Mar 1, 11:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();

    expect(find.text('Noviembre 2026'), findsOneWidget);
    expect(find.text('Confirmar · Jue 5, 11:00'), findsOneWidget);
  });

  testWidgets('goes no further than the months the workshop offers', (tester) async {
    await openSheet(tester);

    expect(arrow(tester, 'Mes anterior').onPressed, isNull);
    expect(arrow(tester, 'Mes siguiente').onPressed, isNull);
  });

  testWidgets('books a day of the next month with its own date', (tester) async {
    final data = FakeClientData(agendaResult: const BookingMonths([demoAgenda, demoNextAgenda]));
    await openSheet(tester, data: data);
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ana López');
    await tester.enterText(fields.at(1), '9981234567');
    await tester.enterText(fields.at(2), '1357');
    await tester.tap(find.text('Confirmar · Mar 1, 11:00'));
    await tester.pumpAndSettle();

    expect(data.bookings.single.date, '2026-12-01');
    expect(data.bookings.single.time, '11:00');
  });

  testWidgets('opens on the next month when this one has no later free day', (tester) async {
    const lastDay = AppointmentAgenda(
      year: 2026,
      month: 11,
      monthName: 'Noviembre 2026',
      monthLongName: 'noviembre',
      daysInMonth: 30,
      firstWeekday: 7,
      today: 30,
      nowTime: '09:00',
      slotsByWeekday: {1: ['10:00', '10:30']},
      blockedDays: {},
      bookedSlots: {},
    );
    await openSheet(tester, data: FakeClientData(agendaResult: const BookingMonths([lastDay, demoNextAgenda])));

    expect(find.text('Diciembre 2026'), findsOneWidget);
    expect(find.text('Confirmar · Mar 1, 11:00'), findsOneWidget);
  });

  testWidgets('does not ask a signed-in client for her name, phone and NIP', (tester) async {
    await openSheet(tester, data: FakeClientData(signedIn: true));

    expect(find.text('Tus datos'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Con este celular y tu NIP'), findsNothing);
    expect(find.text('Confirmar · Jue 5, 11:00'), findsOneWidget);
  });

  testWidgets('books for a signed-in client without contact data', (tester) async {
    final data = FakeClientData(signedIn: true);
    await openSheet(tester, data: data);

    await tester.tap(find.text('Confirmar · Jue 5, 11:00'));
    await tester.pumpAndSettle();

    final booking = data.bookings.single;
    expect(booking.contact, isNull);
    expect(booking.date, '2026-11-05');
    expect(booking.time, '11:00');
    expect(find.text('Cita agendada'), findsOneWidget);
    expect(find.text('0937'), findsOneWidget);
  });

  testWidgets('asks a client whose session ended to sign in again', (tester) async {
    await openSheet(tester, data: FakeClientData(signedIn: true, bookingResult: const BookingSignedOut()));

    await tester.tap(find.text('Confirmar · Jue 5, 11:00'));
    await tester.pumpAndSettle();

    expect(find.text('Tu sesión terminó. Vuelve a entrar.'), findsOneWidget);
    expect(find.text('Volver a entrar'), findsOneWidget);
    expect(find.text('Cita agendada'), findsNothing);
  });

  testWidgets('signs out and closes the sheet from "Volver a entrar"', (tester) async {
    final data = FakeClientData(signedIn: true, bookingResult: const BookingSignedOut());
    await openSheet(tester, data: data);
    await tester.tap(find.text('Confirmar · Jue 5, 11:00'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volver a entrar'));
    await tester.pumpAndSettle();

    expect(data.signOuts, 1);
    expect(find.text('Agendar cita'), findsNothing);
    expect(find.text('abrir hoja'), findsOneWidget);
    expect(find.text('aviso: Tu sesión terminó. Vuelve a entrar.'), findsOneWidget);
  });

  testWidgets('takes her to Entrada, signed out, when her session ended loading the agenda', (tester) async {
    final data = FakeClientData(signedIn: true)..sessionEnded = true;
    await openSheet(tester, data: data);

    expect(data.signOuts, 1);
    expect(find.text('Agendar cita'), findsNothing);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('aviso: Tu sesión terminó. Vuelve a entrar.'), findsOneWidget);
  });

  testWidgets('keeps Reintentar when the agenda cannot load for the network', (tester) async {
    final data = FakeClientData(signedIn: true)..fails = true;
    await openSheet(tester, data: data);

    expect(find.text('Reintentar'), findsOneWidget);
    expect(data.signOuts, 0);
  });

  testWidgets('says when the agenda cannot load', (tester) async {
    await openSheet(tester, data: FakeClientData()..fails = true);

    expect(
      find.text('No pudimos cargar tus datos. Revisa tu internet e inténtalo de nuevo.'),
      findsOneWidget,
    );
  });
}

Future<void> openSheet(WidgetTester tester, {FakeClientData? data}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(withClientData(data: data,
    MaterialApp(
      routes: {
        AppRoutes.initial: (context) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => showScheduleSheet(context, waistSelection),
                    child: const Text('abrir hoja'),
                  ),
                  if (ModalRoute.of(context)!.settings.arguments case final notice?) Text('aviso: $notice'),
                ],
              ),
            ),
        AppRoutes.order: (context) {
          final order = ModalRoute.of(context)!.settings.arguments! as Order;
          return Text('detalle ${order.ticket} ${order.status.headline} ${order.scheduledDay} ${order.scheduledTime}');
        },
      },
    ),
  ));
  await tester.tap(find.text('abrir hoja'));
  await tester.pumpAndSettle();
}

IconButton arrow(WidgetTester tester, String tooltip) {
  return tester.widget<IconButton>(find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)).first);
}

Future<void> confirmWithData(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Ana López');
  await tester.enterText(fields.at(1), '9981234567');
  await tester.enterText(fields.at(2), '1357');
  await tester.tap(find.text('Confirmar · Jue 5, 11:00'));
  await tester.pumpAndSettle();
}
