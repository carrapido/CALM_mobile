import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';

class TopAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onHelpPressed;

  const TopAppBarWidget({super.key, this.onHelpPressed});

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderStrong,
            width: 2.0,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.precision_manufacturing_outlined,
                    color: AppColors.borderStrong,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.appTitle,
                    style: AppText.headlineSm.copyWith(
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onHelpPressed ?? () {},
                icon: const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.borderStrong,
                  size: 24,
                ),
                splashRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}