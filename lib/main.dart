import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'routes/app_routes.dart';
import 'themes/app_theme.dart';
import 'widgets/missing_config_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.isComplete) {
    runApp(const MissingConfigApp(message: SupabaseConfig.missingMessage));
    return;
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calm Mobil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.initial, // Inicia en la ruta inicial ('/')
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
