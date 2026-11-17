import 'package:calm_mobil/routes/app_routes.dart';
import 'package:calm_mobil/themes/app_colors.dart';
import 'package:calm_mobil/widgets/app_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the three tabs with the current one in bold ink', (tester) async {
    await pumpTabBar(tester, current: AppTab.orders);

    final current = tester.widget<Text>(find.text('Pedidos')).style!;
    final other = tester.widget<Text>(find.text('Perfil')).style!;
    expect(find.text('Servicios'), findsOneWidget);
    expect(current.fontWeight, FontWeight.w800);
    expect(current.color, AppColors.ink);
    expect(other.fontWeight, FontWeight.w600);
    expect(other.color, AppColors.onSurfaceVariant);
  });

  testWidgets('opens another tab as a fresh start, with nothing to go back to', (tester) async {
    await pumpTabBar(tester, current: AppTab.orders);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('perfil destino'), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });

  testWidgets('stays put when the current tab is tapped', (tester) async {
    await pumpTabBar(tester, current: AppTab.services);

    await tester.tap(find.text('Servicios'));
    await tester.pumpAndSettle();

    expect(find.byType(AppTabBar), findsOneWidget);
  });
}

Future<void> pumpTabBar(WidgetTester tester, {required AppTab current}) async {
  await tester.pumpWidget(
    MaterialApp(
      routes: {
        AppRoutes.initial: (_) => Scaffold(bottomNavigationBar: AppTabBar(current: current)),
        AppRoutes.orders: (_) => const Text('pedidos destino'),
        AppRoutes.services: (_) => const Text('servicios destino'),
        AppRoutes.profile: (_) => const Text('perfil destino'),
      },
    ),
  );
}
