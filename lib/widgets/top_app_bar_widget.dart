import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';

/// 44 pt bar over the screen's background: the workshop brand or a back link on the left,
/// help on the right.
class TopAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const TopAppBarWidget({
    super.key,
    this.showBrand = true,
    this.backLabel,
    this.onHelpPressed,
  });

  final bool showBrand;
  final String? backLabel;
  final VoidCallback? onHelpPressed;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        // The help circle sits 6 pt into the right margin, as in the design.
        padding: const EdgeInsets.fromLTRB(16, 8, 10, 0),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              if (backLabel != null)
                _BackLink(backLabel!)
              else if (showBrand)
                const _Brand(),
              const Spacer(),
              _HelpButton(onPressed: onHelpPressed),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).maybePop(),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: AppText.body,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.only(right: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chevron_left_rounded, size: 26),
          Text(label),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.content_cut, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(AppConstants.appTitle, style: AppText.brand),
      ],
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppConstants.helpLabel,
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.helpCircleFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.question_mark_rounded, size: 18, color: AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}
