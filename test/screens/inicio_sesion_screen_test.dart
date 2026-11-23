import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/screens/inicio_sesion_screen.dart';
import 'package:calm_mobil/services/client_access.dart';
import 'package:calm_mobil/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_client_access.dart';

const ordersDestination = 'Pedidos destino';
const servicesDestination = 'Servicios destino';
const phoneMissingMessage = 'Escribe tu celular a 10 dígitos.';
const mismatchMessage = 'Tu celular o tu NIP no coinciden. Revísalos o escríbele al taller.';
const throttledMessage = 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
const unavailableMessage = 'No pudimos conectarnos. Revisa tu internet e inténtalo de nuevo.';
const helpTitle = '¿Te ayudamos?';

final phoneField = find.byType(TextField).first;
final nipField = find.byType(TextField).last;
final submitButton = find.text('Ver mis pedidos');

void main() {
  testWidgets('shows the sign-in form of the design', (tester) async {
    await pumpEntrada(tester);

    for (final text in [
      'COSTURANDO A LA MEDIDA',
      'Tus pedidos',
      'Entra con tu celular y tu NIP. El NIP es tu contraseña',
      'Celular',
      'NIP',
      'Ver mis pedidos',
      'Olvidé mi NIP',
      '¿Primera vez?',
      'Agenda una cita',
      'Eliges tus arreglos y creas tu NIP.',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('keeps quiet until the client tries to sign in', (tester) async {
    await pumpEntrada(tester);
    expect(find.text(phoneMissingMessage), findsNothing);

    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text(phoneMissingMessage), findsOneWidget);
  });

  testWidgets('turns the phone label red when the phone needs attention', (tester) async {
    await pumpEntrada(tester);

    await tester.tap(submitButton);
    await tester.pump();

    expect(labelColor(tester, 'Celular'), AppColors.errorText);
    expect(labelColor(tester, 'NIP'), AppColors.ink);
  });

  testWidgets('hides the message as soon as a field changes', (tester) async {
    await pumpEntrada(tester);
    await tester.tap(submitButton);
    await tester.pump();

    await tester.enterText(phoneField, '9');
    await tester.pump();

    expect(find.text(phoneMissingMessage), findsNothing);
  });

  testWidgets('groups the phone digits while typing', (tester) async {
    await pumpEntrada(tester);

    await tester.enterText(phoneField, '9981234567');

    expect(textOf(tester, phoneField), '998 123 4567');
  });

  testWidgets('keeps only four digits in the NIP', (tester) async {
    await pumpEntrada(tester);

    await tester.enterText(nipField, '12a345');

    expect(textOf(tester, nipField), '1234');
  });

  testWidgets('moves to the NIP once the phone is complete', (tester) async {
    await pumpEntrada(tester);
    await tester.tap(phoneField);

    await tester.enterText(phoneField, '9981234567');
    await tester.pump();

    expect(hasFocus(tester, nipField), isTrue);
  });

  testWidgets('opens Pedidos when the backend grants access', (tester) async {
    await pumpEntrada(tester);

    await signIn(tester, phone: '9981234567', nip: '2580');

    expect(find.text(ordersDestination), findsOneWidget);
  });

  testWidgets('sends the phone digits and the NIP to the backend', (tester) async {
    final access = FakeClientAccess();
    await pumpEntrada(tester, access: access);

    await signIn(tester, phone: '9981234567', nip: '2580');

    expect(access.calls, [(phoneDigits: '9981234567', nip: '2580')]);
  });

  testWidgets('does not ask the backend while the form is incomplete', (tester) async {
    final access = FakeClientAccess();
    await pumpEntrada(tester, access: access);

    await signIn(tester, phone: '998 123 4', nip: '25');

    expect(access.calls, isEmpty);
  });

  testWidgets('tells the client when the phone and NIP do not match', (tester) async {
    await pumpEntrada(tester, access: FakeClientAccess(outcome: const SignInRejected()));

    await signIn(tester, phone: '9981234567', nip: '1111');

    expect(find.text(mismatchMessage), findsOneWidget);
    expect(labelColor(tester, 'NIP'), AppColors.errorText);
    expect(find.text(ordersDestination), findsNothing);
  });

  testWidgets('tells the client when there were too many attempts', (tester) async {
    await pumpEntrada(tester, access: FakeClientAccess(outcome: const SignInThrottled()));

    await signIn(tester, phone: '9981234567', nip: '2580');

    expect(find.text(throttledMessage), findsOneWidget);
    expect(find.text(ordersDestination), findsNothing);
  });

  testWidgets('tells the client when the backend cannot be reached', (tester) async {
    await pumpEntrada(tester, access: FakeClientAccess(outcome: const SignInUnavailable()));

    await signIn(tester, phone: '9981234567', nip: '2580');

    expect(find.text(unavailableMessage), findsOneWidget);
    expect(find.text(ordersDestination), findsNothing);
  });

  testWidgets('waits on one sign-in at a time, with the button disabled', (tester) async {
    final access = FakeClientAccess(holdsAnswer: true);
    await pumpEntrada(tester, access: access);

    await tester.enterText(phoneField, '9981234567');
    await tester.enterText(nipField, '2580');
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('Entrando…'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(access.calls, hasLength(1));

    access.answer(const SignInGranted());
    await tester.pumpAndSettle();
    expect(find.text(ordersDestination), findsOneWidget);
  });

  testWidgets('drops a refusal for a pair the client changed meanwhile', (tester) async {
    final access = FakeClientAccess(holdsAnswer: true);
    await pumpEntrada(tester, access: access);
    await tester.enterText(phoneField, '9981234567');
    await tester.enterText(nipField, '1111');
    await tester.tap(submitButton);
    await tester.pump();

    await tester.enterText(nipField, '2580');
    access.answer(const SignInRejected());
    await tester.pumpAndSettle();

    expect(find.text(mismatchMessage), findsNothing);
    expect(labelColor(tester, 'NIP'), AppColors.ink);
    expect(find.text('Ver mis pedidos'), findsOneWidget);
  });

  testWidgets('hides a backend message as soon as a field changes', (tester) async {
    await pumpEntrada(tester, access: FakeClientAccess(outcome: const SignInUnavailable()));
    await signIn(tester, phone: '9981234567', nip: '2580');

    await tester.enterText(nipField, '258');
    await tester.pump();

    expect(find.text(unavailableMessage), findsNothing);
  });

  testWidgets('opens the help sheet from "Olvidé mi NIP" and closes it with Listo', (tester) async {
    await pumpEntrada(tester);

    await tester.tap(find.text('Olvidé mi NIP'));
    await tester.pumpAndSettle();

    for (final text in [helpTitle, 'Escribir por WhatsApp', 'Llamar al taller', 'Cómo llegar']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.text(helpTitle), findsNothing);
  });

  testWidgets('opens the help sheet from the help button', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpEntrada(tester);

    await tester.tap(find.bySemanticsLabel('Ayuda'));
    await tester.pumpAndSettle();

    expect(find.text(helpTitle), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('takes a first-time client to Servicios', (tester) async {
    await pumpEntrada(tester);

    await tester.tap(find.text('Agenda una cita'));
    await tester.pumpAndSettle();

    expect(find.text(servicesDestination), findsOneWidget);
  });
}

Future<void> pumpEntrada(WidgetTester tester, {FakeClientAccess? access}) async {
  final clientAccess = access ?? FakeClientAccess();
  await tester.pumpWidget(
    MaterialApp(
      routes: {
        AppRoutes.initial: (_) => InicioSesionScreen(access: clientAccess),
        AppRoutes.orders: (_) => const Text(ordersDestination),
        AppRoutes.services: (_) => const Text(servicesDestination),
      },
    ),
  );
}

Future<void> signIn(WidgetTester tester, {required String phone, required String nip}) async {
  await tester.enterText(phoneField, phone);
  await tester.enterText(nipField, nip);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

String textOf(WidgetTester tester, Finder field) {
  return tester.widget<TextField>(field).controller!.text;
}

bool hasFocus(WidgetTester tester, Finder field) {
  final editable = find.descendant(of: field, matching: find.byType(EditableText));
  return tester.widget<EditableText>(editable).focusNode.hasFocus;
}

Color? labelColor(WidgetTester tester, String label) {
  return tester.widget<Text>(find.text(label)).style?.color;
}
