import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/screens/profile_screen.dart';
import 'package:calm_mobil/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:calm_mobil/models/profile_form.dart';
import 'package:calm_mobil/models/profile_update.dart';
import 'package:calm_mobil/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_client_data.dart';

void main() {
  testWidgets('shows the signed-in client', (tester) async {
    final data = FakeClientData(
      profileResult: const UserProfile(fullName: 'María López', phone: '998 123 4567'),
    );
    await pumpProfile(tester, data: data);

    expect(find.text('María López'), findsOneWidget);
    expect(find.text('ML'), findsOneWidget);
    expect(find.text('Carlos Ruiz'), findsNothing);
  });

  testWidgets('says when the profile cannot load', (tester) async {
    await pumpProfile(tester, data: FakeClientData()..fails = true);

    expect(
      find.text('No pudimos cargar tus datos. Revisa tu internet e inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('shows the client and the editable data', (tester) async {
    await pumpProfile(tester);

    for (final text in [
      'CR',
      'Carlos Ruiz',
      'Celular',
      'Número',
      'Con este número entras y te avisamos por WhatsApp.',
      'NIP',
      'Actual',
      'Nuevo',
      'No es para pagar. Déjalo vacío si no lo cambias.',
      'Guardar cambios',
      'Cerrar sesión',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    // On the card and in the "Número" field.
    expect(find.text('998 123 4567'), findsNWidgets(2));
  });

  testWidgets('saves a new phone and shows it on the card', (tester) async {
    await pumpProfile(tester);

    await tester.enterText(phoneField, '9987654321');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Guardamos tus cambios'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsNothing);
    expect(find.text('998 765 4321'), findsNWidgets(2));
    expect(find.text('998 123 4567'), findsNothing);
  });

  testWidgets('brings the button back on the next edit', (tester) async {
    await pumpProfile(tester);
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    await tester.enterText(phoneField, '998123456');
    await tester.pump();

    expect(find.text('Guardamos tus cambios'), findsNothing);
    expect(find.text('Guardar cambios'), findsOneWidget);
  });

  testWidgets('marks the field that needs attention', (tester) async {
    await pumpProfile(tester);

    await tester.enterText(phoneField, '99812');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu celular a 10 dígitos.'), findsOneWidget);
    expect(labelColor(tester, 'Número'), AppColors.errorText);
    expect(labelColor(tester, 'Actual'), AppColors.ink);
  });

  testWidgets('clears the message when the client edits', (tester) async {
    await pumpProfile(tester);
    await tester.enterText(phoneField, '99812');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    await tester.enterText(phoneField, '998123');
    await tester.pump();

    expect(find.text('Escribe tu celular a 10 dígitos.'), findsNothing);
    expect(labelColor(tester, 'Número'), AppColors.ink);
  });

  testWidgets('rejects a current NIP the workshop does not match', (tester) async {
    final data = FakeClientData(
      profileSaveResult: const ProfileRefused('Tu NIP actual no coincide.', field: ProfileField.currentNip),
    );
    await pumpProfile(tester, data: data);

    await tester.enterText(currentNipField, '1111');
    await tester.enterText(newNipField, '1357');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Tu NIP actual no coincide.'), findsOneWidget);
    expect(labelColor(tester, 'Actual'), AppColors.errorText);
  });

  testWidgets('changes the NIP and empties both NIP fields', (tester) async {
    await pumpProfile(tester);

    await tester.enterText(currentNipField, '2580');
    await tester.enterText(newNipField, '1357');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Guardamos tus cambios'), findsOneWidget);
    expect(find.text('2580'), findsNothing);
    expect(find.text('1357'), findsNothing);
  });

  testWidgets('sends the phone and both NIPs to the workshop', (tester) async {
    final data = FakeClientData();
    await pumpProfile(tester, data: data);

    await tester.enterText(phoneField, '9987654321');
    await tester.enterText(currentNipField, '2580');
    await tester.enterText(newNipField, '1357');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final change = data.profileChanges.single;
    expect(change.phoneDigits, '9987654321');
    expect(change.currentNip, '2580');
    expect(change.newNip, '1357');
  });

  testWidgets('sends nothing while the form has a problem', (tester) async {
    final data = FakeClientData();
    await pumpProfile(tester, data: data);

    await tester.enterText(phoneField, '99812');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(data.profileChanges, isEmpty);
  });

  testWidgets('says when the workshop refuses the new phone', (tester) async {
    final data = FakeClientData(
      profileSaveResult: const ProfileRefused('Ese celular ya lo usa otra cuenta.', field: ProfileField.phone),
    );
    await pumpProfile(tester, data: data);

    await tester.enterText(phoneField, '9981234567');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Ese celular ya lo usa otra cuenta.'), findsOneWidget);
    expect(labelColor(tester, 'Número'), AppColors.errorText);
    expect(find.text('Guardamos tus cambios'), findsNothing);
  });

  testWidgets('takes her to Entrada, signed out, when her session ended on load', (tester) async {
    final data = FakeClientData(signedIn: true)..sessionEnded = true;
    await pumpProfile(tester, data: data);
    await tester.pumpAndSettle();

    expect(data.signOuts, 1);
    expect(find.text(sessionEndedAtEntrada), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('takes her to Entrada, signed out, when her session ended on save', (tester) async {
    final data = FakeClientData(signedIn: true, profileSaveResult: const ProfileSignedOut());
    await pumpProfile(tester, data: data);

    await tester.enterText(phoneField, '9981234567');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(data.profileChanges, hasLength(1));
    expect(data.signOuts, 1);
    expect(find.text(sessionEndedAtEntrada), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });

  testWidgets('ends the session when signing out', (tester) async {
    final data = FakeClientData();
    await pumpProfile(tester, data: data);

    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(data.signOuts, 1);
  });

  testWidgets('signs out to Entrada, leaving nothing to go back to', (tester) async {
    await pumpProfile(tester);

    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('entrada destino'), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });
}

final phoneField = find.byType(TextField).at(0);
final currentNipField = find.byType(TextField).at(1);
final newNipField = find.byType(TextField).at(2);

Color? labelColor(WidgetTester tester, String label) => tester.widget<Text>(find.text(label)).style?.color;

Future<void> pumpProfile(WidgetTester tester, {FakeClientData? data}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(withClientData(data: data,
    MaterialApp(
      initialRoute: AppRoutes.profile,
      routes: {
        AppRoutes.initial: entradaDestination,
        AppRoutes.profile: (_) => const ProfileScreen(),
      },
    ),
  ));
  await tester.pump();
}
