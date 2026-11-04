import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBarWidget({
    super.key,
    this.currentIndex = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        border: Border(
          top: BorderSide(
            color: AppColors.borderStrong,
            width: 2.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.style, 'Servicios'),
              _buildNavItem(1, Icons.calendar_month_outlined, 'Agendar Cita'),
              _buildNavItem(2, Icons.receipt_long_outlined, 'Mis Pedidos'),
              _buildNavItem(3, Icons.person_outline, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? AppColors.borderStrong : AppColors.outline;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppText.labelSm.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}