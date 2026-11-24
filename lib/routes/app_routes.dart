import 'package:flutter/material.dart';

import '../models/order.dart';
import '../screens/inicio_sesion_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/services_screen.dart';
import '../services/client_data.dart';

class AppRoutes {
  AppRoutes._();

  static const String initial = '/';
  static const String services = '/services';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String order = '/order';

  static const _tabRoots = {orders, services, profile};

  /// Tab screens swap in place, like an iOS tab bar; the rest slide in with the platform transition.
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final page = _pageFor(settings);
    if (!_tabRoots.contains(settings.name)) {
      return MaterialPageRoute(settings: settings, builder: (_) => page);
    }
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  static Widget _pageFor(RouteSettings settings) {
    return switch ((settings.name, settings.arguments)) {
      (AppRoutes.order, final Order selected) => _SignedInOnly(OrderDetailScreen(order: selected)),
      (AppRoutes.orders, _) => const _SignedInOnly(OrdersScreen()),
      (AppRoutes.services, _) => const _SignedInOnly(ServicesScreen()),
      (AppRoutes.profile, _) => const _SignedInOnly(ProfileScreen()),
      (AppRoutes.initial, final String notice) => InicioSesionScreen(notice: notice),
      _ => const InicioSesionScreen(),
    };
  }
}

/// Servicios, Pedidos, Perfil and an order are hers alone: without a session they open Entrada,
/// where she signs in or books her first appointment (odd/tasks/flujo-primera-vez.md S5).
///
/// Decided once, when the screen opens: signing out on it already takes her to Entrada.
class _SignedInOnly extends StatefulWidget {
  const _SignedInOnly(this.page);

  final Widget page;

  @override
  State<_SignedInOnly> createState() => _SignedInOnlyState();
}

class _SignedInOnlyState extends State<_SignedInOnly> {
  late final bool _isSignedIn = ClientDataScope.maybeOf(context)?.isSignedIn ?? false;

  @override
  Widget build(BuildContext context) => _isSignedIn ? widget.page : const InicioSesionScreen();
}
