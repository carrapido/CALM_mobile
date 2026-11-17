import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// The design's sheets enter slower than they leave, and do not move when the OS asks for less motion.
AnimationStyle sheetMotion(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return AnimationStyle.noAnimation;
  return const AnimationStyle(
    duration: Duration(milliseconds: 420),
    reverseDuration: Duration(milliseconds: 240),
  );
}

/// The handle at the top of a sheet.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.grabber,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
