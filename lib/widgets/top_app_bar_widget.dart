import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';

class TopAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final bool showBrand;
  final VoidCallback? onHelpPressed;

  const TopAppBarWidget({
    super.key,
    this.showBrand = true,
    this.onHelpPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showBrand)
              Row(
                children: [
                  const Icon(
                    Icons.content_cut,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.appTitle,
                    style: AppText.labelSm.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
            InkWell(
              onTap: onHelpPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}