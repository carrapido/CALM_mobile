import 'package:flutter/material.dart';
import '../models/service_item.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

class ServiceCardWidget extends StatelessWidget {
  final ServiceItem service;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceCardWidget({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                service.title,
                style: AppText.bodyLg.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            Text(
              service.priceDisplay,
              style: AppText.bodyLg.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryDark : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.borderUnselected,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}