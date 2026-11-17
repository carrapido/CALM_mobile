import 'dart:ui';

import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

enum AppTab {
  orders('Pedidos', Icons.receipt_long_outlined, AppRoutes.orders),
  services('Servicios', Icons.sell_outlined, AppRoutes.services),
  profile('Perfil', Icons.person_outline_rounded, AppRoutes.profile);

  const AppTab(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

/// Translucent bar to move between Pedidos, Servicios and Perfil.
/// Opening a tab starts it afresh, so the back gesture never returns to another tab.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.current});

  final AppTab current;

  @override
  Widget build(BuildContext context) {
    // ClipRect keeps the blur to the bar instead of the whole screen.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.barMaterial,
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: SafeArea(
            top: false,
            // A minimum, not a fixed height, so large accessibility text grows the bar instead of clipping it.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 49),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (final tab in AppTab.values)
                      Expanded(child: _tabItem(context, tab)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabItem(BuildContext context, AppTab tab) {
    final isCurrent = tab == current;
    return _TabItem(
      tab: tab,
      isCurrent: isCurrent,
      onTap: isCurrent ? null : () => _open(context, tab),
    );
  }

  void _open(BuildContext context, AppTab tab) {
    Navigator.of(context).pushNamedAndRemoveUntil(tab.route, (_) => false);
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.isCurrent, required this.onTap});

  final AppTab tab;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? AppColors.ink : AppColors.onSurfaceVariant;
    return Semantics(
      selected: isCurrent,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Align(
          heightFactor: 1,
          child: Container(
            constraints: const BoxConstraints(minWidth: 96),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.currentTabFill : null,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    color: color,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
