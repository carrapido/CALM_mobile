import 'package:calm_mobil/models/appointment_agenda.dart';
import 'package:calm_mobil/models/booking.dart';
import 'package:calm_mobil/models/booking_form.dart';
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

    expect(find.text('detalle 0937 Cita agendada'), findsOneWidget);
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
    await openSheet(tester, data: FakeClientData(agendaResult: full));

    expect(find.text('Ya no quedan horarios libres este mes. Escríbele al taller.'), findsOneWidget);
    expect(find.textContaining('Confirmar'), findsNothing);
  });

  testWidgets('books on the server what the client chose', (tester) async {
    final data = FakeClientData();
    await openSheet(tester, data: data);

    await confirmWithData(tester);

    final booking = data.bookings.single;
    expect(booking.name, 'Ana López');
    expect(booking.phoneDigits, '9981234567');
    expect(booking.nip, '1357');
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
              body: TextButton(
                onPressed: () => showScheduleSheet(context, waistSelection),
                child: const Text('abrir hoja'),
              ),
            ),
        AppRoutes.order: (context) {
          final order = ModalRoute.of(context)!.settings.arguments! as Order;
          return Text('detalle ${order.ticket} ${order.status.headline}');
        },
      },
    ),
  ));
  await tester.tap(find.text('abrir hoja'));
  await tester.pumpAndSettle();
}

Future<void> confirmWithData(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Ana López');
  await tester.enterText(fields.at(1), '9981234567');
  await tester.enterText(fields.at(2), '1357');
  await tester.tap(find.text('Confirmar · Jue 5, 11:00'));
  await tester.pumpAndSettle();
}
