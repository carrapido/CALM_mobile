import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

/// Small gray title above an [InsetGroup], aligned with the text inside the group.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.topSpacing = 24});

  final String text;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topSpacing, 16, 8),
      child: Text(text, style: AppText.footnoteStrong),
    );
  }
}
