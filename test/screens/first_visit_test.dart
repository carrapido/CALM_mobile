import 'package:calm_mobil/models/booking.dart';
import 'package:calm_mobil/models/booking_form.dart';
import 'package:calm_mobil/models/order.dart';
import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/themes/app_colors.dart';
import 'package:calm_mobil/utils/app_constants.dart';
import 'package:calm_mobil/widgets/app_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_client_data.dart';

// odd/tasks/flujo-primera-vez.md: a first-time client books from Entrada in a sheet and only then
// enters the app; without a session no tab route opens.

const loadFailure = 'No pudimos cargar tus datos. Revisa tu internet e inténtalo de nuevo.';

const newAppointment = Order(
  ticket: '4821',
  work: 'Ajuste de cintura, Parche',
  status: OrderStatus.appointment,
  amountMxn: 220,
  appointmentOn: 'jueves 5 a las 11:00',
);

void main() {
  testWidgets('opens a booking sheet with the active services from Entrada, without the tabs', (tester) async {
    await pumpApp(tester, FakeClientData());

    await openFirstVisit(tester);

    for (final text in [
      'Cancelar',
      'Agendar cita',
      'Marca lo que necesitas y elige tu horario.',
      'Ajuste de cintura',
      r'$180',
      'Vestido Personalizado',
      'A cotizar',
      'El precio final se confirma al revisar tu prenda.',
      'Prenda urgente',
      'Cargo extra',
      'Elegir horario',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(chooseScheduleButton(tester).onPressed, isNull);
    expect(find.byType(AppTabBar), findsNothing);
    expect(find.text('Servicios'), findsNothing);
    expect(find.text('Perfil'), findsNothing);
  });

  testWidgets('moves on to day, time and her data with the services she marked', (tester) async {
    await pumpApp(tester, FakeClientData());
    await openFirstVisit(tester);

    await chooseServices(tester, ['Ajuste de cintura', 'Parche']);

    for (final text in [
      'Agendar cita',
      'Ajuste de cintura, Parche',
      r'Cotización preliminar: $220 MXN',
      'Día',
      'Hora',
      'Tus datos',
      'Nombre',
      'Celular',
      'NIP',
      'Confirmar · Jue 5, 11:00',
    ]) {
      expect(inSheet(find.text(text)), findsOneWidget, reason: text);
    }
  });

  testWidgets('books the urgent garment when she marks it', (tester) async {
    final data = FakeClientData();
    await pumpApp(tester, data);
    await openFirstVisit(tester);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.tap(find.text('Prenda urgente'));
    await tester.pump();
    expect(find.text('1 arreglo · urgente'), findsOneWidget);
    await tester.tap(find.text('Elegir horario'));
    await tester.pumpAndSettle();

    expect(find.text('Ajuste de cintura · Urgente'), findsOneWidget);
    await confirmWithData(tester);
    expect(data.bookings.single.selection.isUrgent, isTrue);
  });

  testWidgets('books with her data, signs her in and enters the app on Pedidos', (tester) async {
    final data = FakeClientData(
      bookingResult: const BookingConfirmed('4821'),
      ordersResult: const [newAppointment],
    );
    await pumpApp(tester, data);
    await openFirstVisit(tester);
    await chooseServices(tester, ['Ajuste de cintura', 'Parche']);

    await confirmWithData(tester);

    final booking = data.bookings.single;
    expect(booking.contact?.name, 'Ana López');
    expect(booking.contact?.phoneDigits, '9981234567');
    expect(booking.contact?.nip, '1357');
    expect(booking.selection.services.map((service) => service.id), ['waist', 'patch']);
    expect(booking.date, '2026-11-05');
    expect(booking.time, '11:00');
    expect(data.isSignedIn, isTrue);
    for (final text in ['Cita agendada', 'Tu ticket', '4821', 'Ver mi cita', 'Listo']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    await tester.tap(find.text('Ver mi cita'));
    await tester.pumpAndSettle();

    expectPedidosWithAppointment(tester);
  });

  testWidgets('"Listo" also enters the app on Pedidos', (tester) async {
    final data = FakeClientData(
      bookingResult: const BookingConfirmed('4821'),
      ordersResult: const [newAppointment],
    );
    await pumpApp(tester, data);
    await openFirstVisit(tester);
    await chooseServices(tester, ['Ajuste de cintura', 'Parche']);
    await confirmWithData(tester);

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expectPedidosWithAppointment(tester);
  });

  testWidgets('back from Pedidos does not return to Entrada', (tester) async {
    final data = FakeClientData(
      bookingResult: const BookingConfirmed('4821'),
      ordersResult: const [newAppointment],
    );
    await pumpApp(tester, data);
    await openFirstVisit(tester);
    await chooseServices(tester, ['Ajuste de cintura', 'Parche']);
    await confirmWithData(tester);
    await tester.tap(find.text('Ver mi cita'));
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigator.canPop(), isFalse);
    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Ver mis pedidos'), findsNothing);
    expectPedidosWithAppointment(tester);
  });

  testWidgets('asks for each missing piece of her data before booking', (tester) async {
    final data = FakeClientData();
    await pumpApp(tester, data);
    await openFirstVisit(tester);
    await chooseServices(tester, ['Ajuste de cintura']);
    final fields = inSheet(find.byType(TextField));

    await tapConfirm(tester);
    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    expect(labelColor(tester, 'Nombre'), AppColors.errorText);

    await tester.enterText(fields.at(0), 'Ana López');
    await tester.pump();
    expect(find.text('Escribe tu nombre.'), findsNothing);
    await tapConfirm(tester);
    expect(find.text('Escribe los 10 dígitos de tu celular.'), findsOneWidget);
    expect(labelColor(tester, 'Celular'), AppColors.errorText);

    await tester.enterText(fields.at(1), '9981234567');
    await tapConfirm(tester);
    expect(find.text('Elige un NIP de 4 dígitos.'), findsOneWidget);
    expect(labelColor(tester, 'NIP'), AppColors.errorText);

    expect(data.bookings, isEmpty);
    expect(data.isSignedIn, isFalse);
  });

  testWidgets('moves off a slot that was taken meanwhile and stays in the sheet', (tester) async {
    final data = FakeClientData(bookingResult: const BookingSlotTaken());
    await pumpApp(tester, data);
    await openFirstVisit(tester);
    await chooseServices(tester, ['Ajuste de cintura']);

    await confirmWithData(tester);

    expect(find.text('Ese horario se acaba de ocupar. Elige otro.'), findsOneWidget);
    expect(find.text('Confirmar · Jue 5, 10:30'), findsOneWidget);
    expectStillOutside(tester, data);
  });

  for (final (name, refusal, field) in [
    ('a phone registered without a NIP', AppConstants.bookingPhoneWithoutNip, BookingField.phone),
    ('a NIP that does not match her phone', AppConstants.bookingWrongPair, BookingField.nip),
    ('too many attempts', AppConstants.signInThrottled, null),
    ('a workshop it cannot reach', AppConstants.signInUnavailable, null),
    ('a service no longer available', AppConstants.bookingServiceUnavailable, null),
  ]) {
    testWidgets('says why it could not book: $name', (tester) async {
      final data = FakeClientData(bookingResult: BookingRefused(refusal, field: field));
      await pumpApp(tester, data);
      await openFirstVisit(tester);
      await chooseServices(tester, ['Ajuste de cintura']);

      await confirmWithData(tester);

      expect(find.text(refusal), findsOneWidget);
      if (field == BookingField.phone) expect(labelColor(tester, 'Celular'), AppColors.errorText);
      if (field == BookingField.nip) expect(labelColor(tester, 'NIP'), AppColors.errorText);
      expectStillOutside(tester, data);
    });
  }

  testWidgets('says when the services cannot load, and loads them again on Reintentar', (tester) async {
    final data = FakeClientData()..fails = true;
    await pumpApp(tester, data);

    await openFirstVisit(tester);

    expect(find.text(loadFailure), findsOneWidget);
    expect(find.text('Agendar cita'), findsOneWidget);
    expect(find.byType(AppTabBar), findsNothing);
    expect(data.signOuts, 0);

    data.fails = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text(loadFailure), findsNothing);
    expect(find.text('Ajuste de cintura'), findsOneWidget);
  });

  testWidgets('closes with Cancelar back to Entrada', (tester) async {
    await pumpApp(tester, FakeClientData());
    await openFirstVisit(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Agendar cita'), findsNothing);
    expect(find.text('Ver mis pedidos'), findsOneWidget);
  });

  for (final route in [AppRoutes.services, AppRoutes.orders, AppRoutes.profile]) {
    testWidgets('opens Entrada instead of $route without a session', (tester) async {
      final data = FakeClientData();
      await pumpApp(tester, data);

      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(route);
      await tester.pumpAndSettle();

      expect(find.text('Ver mis pedidos'), findsOneWidget);
      expect(find.byType(AppTabBar), findsNothing);
      expect(data.loads, 0);
    });
  }

  testWidgets('opens Entrada instead of an order without a session', (tester) async {
    final data = FakeClientData();
    await pumpApp(tester, data);

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(AppRoutes.order, arguments: newAppointment);
    await tester.pumpAndSettle();

    expect(find.text('Ver mis pedidos'), findsOneWidget);
    expect(find.text('Ticket 4821'), findsNothing);
    expect(find.byType(AppTabBar), findsNothing);
  });

  testWidgets('opens Pedidos with the tabs when she is signed in', (tester) async {
    await pumpApp(tester, FakeClientData(signedIn: true));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(AppRoutes.orders);
    await tester.pumpAndSettle();

    expect(find.text('Ver mis pedidos'), findsNothing);
    expect(find.byType(AppTabBar), findsOneWidget);
  });
}

Future<void> pumpApp(WidgetTester tester, FakeClientData data) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    withClientData(data: data, const MaterialApp(onGenerateRoute: AppRoutes.onGenerateRoute)),
  );
}

Future<void> openFirstVisit(WidgetTester tester) async {
  await tester.tap(find.text('Agenda una cita'));
  await tester.pumpAndSettle();
}

Future<void> chooseServices(WidgetTester tester, List<String> names) async {
  for (final name in names) {
    await tester.tap(find.text(name));
  }
  await tester.pump();
  await tester.tap(find.text('Elegir horario'));
  await tester.pumpAndSettle();
}

Future<void> tapConfirm(WidgetTester tester) async {
  await tester.tap(find.textContaining('Confirmar · '));
  await tester.pump();
}

Future<void> confirmWithData(WidgetTester tester) async {
  final fields = inSheet(find.byType(TextField));
  await tester.enterText(fields.at(0), 'Ana López');
  await tester.enterText(fields.at(1), '9981234567');
  await tester.enterText(fields.at(2), '1357');
  await tester.tap(find.textContaining('Confirmar · '));
  await tester.pumpAndSettle();
}

FilledButton chooseScheduleButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.ancestor(of: find.text('Elegir horario'), matching: find.byType(FilledButton)),
  );
}

Color? labelColor(WidgetTester tester, String label) {
  return tester.widget<Text>(inSheet(find.text(label))).style?.color;
}

/// Entrada stays behind the sheet with its own Celular and NIP.
Finder inSheet(Finder finder) => find.descendant(of: find.byType(BottomSheet), matching: finder);

void expectPedidosWithAppointment(WidgetTester tester) {
  expect(find.text('Agendar cita'), findsNothing);
  expect(find.text('Pedidos'), findsNWidgets(2));
  expect(find.byType(AppTabBar), findsOneWidget);
  expect(find.text('Ajuste de cintura, Parche'), findsOneWidget);
}

void expectStillOutside(WidgetTester tester, FakeClientData data) {
  expect(find.text('Cita agendada'), findsNothing);
  expect(find.text('Agendar cita'), findsOneWidget);
  expect(find.byType(AppTabBar), findsNothing);
  expect(data.isSignedIn, isFalse);
}
