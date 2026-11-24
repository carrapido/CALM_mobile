import 'package:calm_mobil/models/order.dart';
import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/screens/orders_screen.dart';
import 'package:calm_mobil/themes/app_colors.dart';
import 'package:calm_mobil/widgets/app_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_client_data.dart';

void main() {
  testWidgets('says when the client has no orders yet', (tester) async {
    await pumpOrders(tester, data: FakeClientData(ordersResult: const []));

    expect(find.text('Todavía no tienes pedidos.'), findsOneWidget);
    expect(find.text('Activos'), findsNothing);
    expect(find.text('Entregados'), findsNothing);
    expect(find.text('Agendar una cita'), findsOneWidget);
  });

  testWidgets('hides a section with nothing in it', (tester) async {
    final activeOnly = demoOrders.where((order) => !order.isDelivered).toList();
    await pumpOrders(tester, data: FakeClientData(ordersResult: activeOnly));

    expect(find.text('Activos'), findsOneWidget);
    expect(find.text('Entregados'), findsNothing);
  });

  testWidgets('says when the orders cannot load', (tester) async {
    await pumpOrders(tester, data: FakeClientData(signedIn: true)..fails = true);

    expect(
      find.text('No pudimos cargar tus datos. Revisa tu internet e inténtalo de nuevo.'),
      findsOneWidget,
    );
    // With her session open, the heading and the tab bar stay while she is offline.
    expect(find.text('Pedidos'), findsNWidgets(2));
    expect(find.byType(AppTabBar), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('shows no tab bar with the load failure when there is no session', (tester) async {
    await pumpOrders(tester, data: FakeClientData()..fails = true);

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(AppTabBar), findsNothing);
    expect(find.text('Perfil'), findsNothing);
  });

  testWidgets('takes her to Entrada, signed out, when her session ended', (tester) async {
    final data = FakeClientData(signedIn: true)..sessionEnded = true;
    await tester.pumpWidget(withClientData(data: data,
      MaterialApp(
        initialRoute: AppRoutes.orders,
        routes: {
          AppRoutes.initial: entradaDestination,
          AppRoutes.orders: (_) => const OrdersScreen(),
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(data.signOuts, 1);
    expect(find.text(sessionEndedAtEntrada), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.byType(AppTabBar), findsNothing);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });

  testWidgets('lists active and delivered orders as in the design', (tester) async {
    await pumpOrders(tester);

    for (final text in [
      'Activos',
      'Cambio de cierre de chamarra',
      'Listo para recoger',
      'Ajuste de cintura',
      'Cita agendada',
      'Ajuste de vestido de novia',
      'En proceso',
      'Entregados',
      'Dobladillo de pantalón',
      'Entregado el 12 de octubre',
      'Agendar una cita',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('makes the order that needs the client stand out', (tester) async {
    await pumpOrders(tester);

    final ready = tester.widget<Text>(find.text('Listo para recoger')).style!;
    final inProgress = tester.widget<Text>(find.text('En proceso')).style!;
    expect(ready.fontWeight, FontWeight.w700);
    expect(ready.color, AppColors.ink);
    expect(inProgress.fontWeight, FontWeight.w500);
    expect(inProgress.color, AppColors.onSurfaceVariant);
  });

  testWidgets('opens the detail of an active order', (tester) async {
    await pumpOrders(tester);

    await tester.tap(find.text('Ajuste de cintura'));
    await tester.pumpAndSettle();

    expect(find.text('detalle 0937'), findsOneWidget);
  });

  testWidgets('takes the client to Servicios to book another appointment', (tester) async {
    await pumpOrders(tester);

    await tester.tap(find.text('Agendar una cita'));
    await tester.pumpAndSettle();

    expect(find.text('servicios destino'), findsOneWidget);
  });

  testWidgets('opens the help sheet from the help button', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpOrders(tester);

    await tester.tap(find.bySemanticsLabel('Ayuda'));
    await tester.pumpAndSettle();

    expect(find.text('¿Te ayudamos?'), findsOneWidget);
    semantics.dispose();
  });
}

Future<void> pumpOrders(WidgetTester tester, {FakeClientData? data}) async {
  await tester.pumpWidget(withClientData(data: data,
    MaterialApp(
      routes: {
        AppRoutes.initial: (_) => const OrdersScreen(),
        AppRoutes.services: (_) => const Text('servicios destino'),
        AppRoutes.order: (context) {
          final order = ModalRoute.of(context)!.settings.arguments! as Order;
          return Text('detalle ${order.ticket}');
        },
      },
    ),
  ));
  await tester.pump();
}
