import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/api_config.dart';
import 'config/supabase_config.dart';
import 'routes/app_routes.dart';
import 'services/api_client.dart';
import 'services/api_client_data.dart';
import 'services/client_data.dart';
import 'themes/app_theme.dart';
import 'widgets/missing_config_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.isComplete || !ApiConfig.isComplete) {
    runApp(const MissingConfigApp(message: SupabaseConfig.missingMessage));
    return;
  }
  // Supabase only keeps the client's session (sign-in, refresh, sign-out); her data goes through
  // the CALM API.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(
    ClientDataScope(
      data: ApiClientData(ApiClient.forSupabase(Supabase.instance.client), Supabase.instance.client),
      child: const MyApp(),
    ),
  );
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
