import 'package:calm_mobil/models/catalog.dart';
import 'package:calm_mobil/models/service_item.dart';
import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/screens/services_screen.dart';
import 'package:calm_mobil/widgets/app_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_client_data.dart';

const loadFailure = 'No pudimos cargar tus datos. Revisa tu internet e inténtalo de nuevo.';

void main() {
  testWidgets('shows the catalog and the urgent extra', (tester) async {
    await pumpServices(tester);

    for (final text in [
      'Marca lo que necesitas y elige tu horario.',
      'Ajuste de cintura',
      r'$180',
      'Ajuste de vestido de fiesta',
      r'$300',
      'Vestido Personalizado',
      'A cotizar',
      'Cambio de cierre',
      r'$130',
      'Dobladillo de pantalón',
      r'$100',
      'Parche',
      r'$40',
      'El precio final se confirma al revisar tu prenda.',
      'Extras',
      'Prenda urgente',
      'Cargo extra',
      'Te la entregamos antes. El cargo se suma a tus arreglos.',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Elegir horario'), findsNothing);
  });

  testWidgets('shows the selection bar once a service is marked', (tester) async {
    await pumpServices(tester);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.pump();

    expect(find.text('1 arreglo'), findsOneWidget);
    expect(find.text(r'$180 MXN'), findsOneWidget);
    expect(find.text('Elegir horario'), findsOneWidget);
  });

  testWidgets('adds up every marked service', (tester) async {
    await pumpServices(tester);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.tap(find.text('Parche'));
    await tester.pump();

    expect(find.text('2 arreglos'), findsOneWidget);
    expect(find.text(r'$220 MXN'), findsOneWidget);
  });

  testWidgets('hides the bar when the last service is unmarked', (tester) async {
    await pumpServices(tester);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.pump();
    await tester.tap(find.text('Ajuste de cintura'));
    await tester.pump();

    expect(find.text('Elegir horario'), findsNothing);
  });

  testWidgets('marks the order as urgent from the whole row', (tester) async {
    await pumpServices(tester);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.tap(find.text('Prenda urgente'));
    await tester.pump();

    expect(find.text('1 arreglo · urgente'), findsOneWidget);
    expect(find.text(r'$180 MXN + cargo por urgencia'), findsOneWidget);
  });

  testWidgets('shows the services the workshop has active', (tester) async {
    final data = FakeClientData(
      catalogResult: const Catalog(
        services: [ServiceItem(id: '12', title: 'Bordado a mano', priceMxn: 250)],
      ),
    );
    await pumpServices(tester, data: data);

    expect(find.text('Bordado a mano'), findsOneWidget);
    expect(find.text(r'$250'), findsOneWidget);
    expect(find.text('Ajuste de cintura'), findsNothing);
  });

  testWidgets('adds the urgent charge the workshop defined to the quote', (tester) async {
    final data = FakeClientData(
      catalogResult: Catalog(services: demoCatalog.services, urgentSurchargeMxn: 80),
    );
    await pumpServices(tester, data: data);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.tap(find.text('Prenda urgente'));
    await tester.pump();

    expect(find.text(r'$260 MXN'), findsOneWidget);
  });

  testWidgets('says when the catalog cannot load, and loads it again on Reintentar', (tester) async {
    final data = FakeClientData()..fails = true;
    await pumpServices(tester, data: data);

    expect(find.text(loadFailure), findsOneWidget);
    expect(find.text('Ajuste de cintura'), findsNothing);

    data.fails = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text(loadFailure), findsNothing);
    expect(find.text('Ajuste de cintura'), findsOneWidget);
    expect(data.loads, 2);
  });

  testWidgets('keeps the tab bar with Reintentar when she is signed in but offline', (tester) async {
    await pumpServices(tester, data: FakeClientData(signedIn: true)..fails = true);

    expect(find.text(loadFailure), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(AppTabBar), findsOneWidget);
  });

  testWidgets('shows no signed-in tab bar with the load failure when there is no session', (tester) async {
    await pumpServices(tester, data: FakeClientData()..fails = true);

    expect(find.text(loadFailure), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(AppTabBar), findsNothing);
    expect(find.text('Pedidos'), findsNothing);
  });

  testWidgets('takes her to Entrada, signed out, when her session ended', (tester) async {
    final data = FakeClientData(signedIn: true)..sessionEnded = true;
    await pumpServicesRoutes(tester, data);
    await tester.pumpAndSettle();

    expect(data.signOuts, 1);
    expect(find.text(sessionEndedAtEntrada), findsOneWidget);
    expect(find.text(loadFailure), findsNothing);
  });
}

Future<void> pumpServicesRoutes(WidgetTester tester, FakeClientData data) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(withClientData(data: data,
    MaterialApp(
      initialRoute: AppRoutes.services,
      routes: {
        AppRoutes.initial: entradaDestination,
        AppRoutes.services: (_) => const ServicesScreen(),
      },
    ),
  ));
  await tester.pump();
}

Future<void> pumpServices(WidgetTester tester, {FakeClientData? data}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(withClientData(const MaterialApp(home: ServicesScreen()), data: data));
  await tester.pump();
}
