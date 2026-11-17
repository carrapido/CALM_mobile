import 'package:calm_mobil/models/order.dart';
import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/screens/orders_screen.dart';
import 'package:calm_mobil/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

Future<void> pumpOrders(WidgetTester tester) async {
  await tester.pumpWidget(
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
  );
}
