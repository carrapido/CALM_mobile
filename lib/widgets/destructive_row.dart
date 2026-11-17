import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import 'inset_group.dart';

/// A single red action in its own white group, such as "Cancelar cita" or "Cerrar sesión".
class DestructiveRow extends StatelessWidget {
  const DestructiveRow({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      children: [
        InkWell(
          onTap: onTap,
          highlightColor: AppColors.pressedCell,
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Center(
              child: Text(label, style: AppText.body.copyWith(color: AppColors.errorRed)),
            ),
          ),
        ),
      ],
    );
  }
}
