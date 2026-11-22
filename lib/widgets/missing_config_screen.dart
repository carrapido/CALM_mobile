import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// Shown instead of the app when it was launched without its Supabase credentials, so whoever
/// runs it reads what to do rather than a stack trace. It is a developer-facing screen.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.groupedBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.errorText, fontSize: 15, height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
