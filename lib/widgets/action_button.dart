import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import 'press_scale.dart';

/// Full-width 52 pt button that shrinks while pressed instead of showing a ripple.
/// Primary is ink with white text; tinted is 6 % ink with ink text, for secondary actions.
class ActionButton extends StatelessWidget {
  const ActionButton.primary({super.key, required this.label, required this.onPressed, this.icon})
      : _background = AppColors.ink,
        _foreground = Colors.white;

  const ActionButton.tinted({super.key, required this.label, required this.onPressed, this.icon})
      : _background = AppColors.tintedFill,
        _foreground = AppColors.ink;

  final String label;

  /// Null disables the button, as while what it started is still under way.
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color _background;
  final Color _foreground;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _background,
          foregroundColor: _foreground,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppText.button,
          splashFactory: NoSplash.splashFactory,
        ),
        child: _content(),
      ),
    );
  }

  Widget _content() {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
    );
  }
}
