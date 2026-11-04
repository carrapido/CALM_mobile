import 'package:flutter/material.dart';
import '../models/service_item.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

class ServiceCardWidget extends StatelessWidget {
  final ServiceItem service;
  final VoidCallback? onTap;

  const ServiceCardWidget({
    super.key,
    required this.service,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderStrong,
            width: 2.0,
          ),
        ),
        child: Row(
          children: [
            // Categoría y Título
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.category.toUpperCase(),
                    style: AppText.labelSm.copyWith(
                      color: AppColors.outline,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.title,
                    style: AppText.labelLg.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.borderStrong,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Precio
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${service.price.toStringAsFixed(0)}',
                  style: AppText.headlineXlMobile.copyWith(
                    fontSize: 24,
                    color: AppColors.borderStrong,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  service.currency,
                  style: AppText.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}