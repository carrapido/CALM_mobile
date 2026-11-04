import 'package:flutter/material.dart';
import '../screens/inicio_sesion_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/services_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String services = '/services';
  static const String orders = '/orders';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
        initial: (context) => const InicioSesionScreen(),
        services: (context) => const ServicesScreen(),
        orders: (context) => const OrdersScreen(),
        profile: (context) => const ProfileScreen(),
      };
}