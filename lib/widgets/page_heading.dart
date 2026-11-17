import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

/// The screen's large title, with an optional line under it.
class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.largeTitle),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppText.lead),
          ],
        ],
      ),
    );
  }
}
