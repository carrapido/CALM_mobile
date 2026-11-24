import 'package:flutter/material.dart';

import '../models/order.dart';
import '../screens/inicio_sesion_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/services_screen.dart';

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
      (AppRoutes.order, final Order selected) => OrderDetailScreen(order: selected),
      (AppRoutes.orders, _) => const OrdersScreen(),
      (AppRoutes.services, _) => const ServicesScreen(),
      (AppRoutes.profile, _) => const ProfileScreen(),
      (AppRoutes.initial, final String notice) => InicioSesionScreen(notice: notice),
      _ => const InicioSesionScreen(),
    };
  }
}
