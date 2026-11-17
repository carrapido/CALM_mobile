import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

/// Confirmation that takes the place of the button that caused it, announced to screen readers.
class StatusNote extends StatelessWidget {
  const StatusNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.tintedFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 18, color: AppColors.ink),
            const SizedBox(width: 8),
            Flexible(
              child: Text(message, style: AppText.subhead.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
