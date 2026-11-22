import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/screens/profile_screen.dart';
import 'package:calm_mobil/themes/app_colors.dart';
import 'package:flutter/material.dart';
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
    await tester.pump();

    expect(find.text('Guardamos tus cambios'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsNothing);
    expect(find.text('998 765 4321'), findsNWidgets(2));
    expect(find.text('998 123 4567'), findsNothing);
  });

  testWidgets('brings the button back on the next edit', (tester) async {
    await pumpProfile(tester);
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    await tester.enterText(phoneField, '998123456');
    await tester.pump();

    expect(find.text('Guardamos tus cambios'), findsNothing);
    expect(find.text('Guardar cambios'), findsOneWidget);
  });

  testWidgets('marks the field that needs attention', (tester) async {
    await pumpProfile(tester);

    await tester.enterText(phoneField, '99812');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    expect(find.text('Escribe tu celular a 10 dígitos.'), findsOneWidget);
    expect(labelColor(tester, 'Número'), AppColors.errorText);
    expect(labelColor(tester, 'Actual'), AppColors.ink);
  });

  testWidgets('clears the message when the client edits', (tester) async {
    await pumpProfile(tester);
    await tester.enterText(phoneField, '99812');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    await tester.enterText(phoneField, '998123');
    await tester.pump();

    expect(find.text('Escribe tu celular a 10 dígitos.'), findsNothing);
    expect(labelColor(tester, 'Número'), AppColors.ink);
  });

  testWidgets('rejects a current NIP that does not match', (tester) async {
    await pumpProfile(tester);

    await tester.enterText(currentNipField, '1111');
    await tester.enterText(newNipField, '1357');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    expect(find.text('Tu NIP actual no coincide.'), findsOneWidget);
    expect(labelColor(tester, 'Actual'), AppColors.errorText);
  });

  testWidgets('changes the NIP and empties both NIP fields', (tester) async {
    await pumpProfile(tester);

    await tester.enterText(currentNipField, '2580');
    await tester.enterText(newNipField, '1357');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    expect(find.text('Guardamos tus cambios'), findsOneWidget);
    expect(find.text('2580'), findsNothing);
    expect(find.text('1357'), findsNothing);
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
        AppRoutes.initial: (_) => const Text('entrada destino'),
        AppRoutes.profile: (_) => const ProfileScreen(),
      },
    ),
  ));
  await tester.pump();
}
