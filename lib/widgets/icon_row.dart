import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

/// Row of an [InsetGroup] with an ink icon tile, a title, an optional subtitle and a chevron.
class IconRow extends StatelessWidget {
  const IconRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.minHeight = 52,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: AppColors.pressedCell,
      splashFactory: NoSplash.splashFactory,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            children: [
              _IconTile(icon),
              const SizedBox(width: 12),
              Expanded(child: _texts()),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.tertiaryLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _texts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.body),
        if (subtitle != null)
          Text(subtitle!, style: AppText.footnote),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 17, color: Colors.white),
    );
  }
}
