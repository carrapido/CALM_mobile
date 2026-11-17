import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

/// Gray note under an [InsetGroup], aligned with the text inside the group.
class GroupFootnote extends StatelessWidget {
  const GroupFootnote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(text, style: AppText.footnote),
    );
  }
}
