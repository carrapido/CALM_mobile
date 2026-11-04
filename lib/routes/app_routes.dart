import 'package:flutter/material.dart';
import '../screens/inicio_sesion_screen.dart';
import '../screens/services_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String services = '/services';

  static Map<String, WidgetBuilder> get routes => {
        initial: (context) => const InicioSesionScreen(),
        services: (context) => const ServicesScreen(),
      };
}