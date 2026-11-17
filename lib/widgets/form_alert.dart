import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

/// Centered red message above a form's main button; screen readers announce it when it appears.
class FormAlert extends StatelessWidget {
  const FormAlert(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(message, textAlign: TextAlign.center, style: AppText.footnoteError),
    );
  }
}
