import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// White rounded block of rows with hairline separators, like an iOS inset grouped list.
/// Its [Material] lets rows paint their pressed highlight inside the rounded corners.
class InsetGroup extends StatelessWidget {
  const InsetGroup({super.key, required this.children, this.separatorIndent = 16});

  final List<Widget> children;
  final double separatorIndent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCanvas,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withSeparators(),
      ),
    );
  }

  List<Widget> _withSeparators() {
    return [
      for (final (index, child) in children.indexed) ...[
        if (index > 0)
          Divider(height: 1, thickness: 1, indent: separatorIndent, color: AppColors.separator),
        child,
      ],
    ];
  }
}
