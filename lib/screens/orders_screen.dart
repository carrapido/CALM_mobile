import 'package:flutter/material.dart';

import '../models/order.dart';
import '../routes/app_routes.dart';
import '../services/client_data.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/group_footnote.dart';
import '../widgets/inset_group.dart';
import '../widgets/loaded.dart';
import '../widgets/page_heading.dart';
import '../widgets/section_header.dart';
import '../widgets/tab_page.dart';

/// Pedidos: every order of the client, active ones first.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const _heading = PageHeading('Pedidos');

  @override
  Widget build(BuildContext context) {
    return Loaded<List<Order>>(
      load: ClientDataScope.of(context).orders,
      pending: (status) => TabPage(tab: AppTab.orders, children: [_heading, status]),
      builder: (_, orders) => _OrdersView(orders),
    );
  }
}

/// A section with nothing in it is not shown; with nothing at all, Pedidos says so.
class _OrdersView extends StatelessWidget {
  const _OrdersView(this.orders);

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final activeOrders = orders.where((order) => !order.isDelivered).toList();
    final deliveredOrders = orders.where((order) => order.isDelivered).toList();
    return TabPage(
      tab: AppTab.orders,
      children: [
        OrdersScreen._heading,
        if (orders.isEmpty) const GroupFootnote('Todavía no tienes pedidos.'),
        if (activeOrders.isNotEmpty) ...[
          const SectionHeader('Activos', topSpacing: 0),
          // The separator starts where the text does, past the status dot.
          InsetGroup(
            separatorIndent: 36,
            children: [
              for (final order in activeOrders)
                _ActiveOrderRow(order, onTap: () => _openOrder(context, order)),
            ],
          ),
        ],
        if (deliveredOrders.isNotEmpty) ...[
          const SectionHeader('Entregados'),
          InsetGroup(
            separatorIndent: 0,
            children: [for (final order in deliveredOrders) _DeliveredOrderRow(order)],
          ),
        ],
        const SizedBox(height: 24),
        ActionButton.tinted(
          label: 'Agendar una cita',
          icon: Icons.add_rounded,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.services),
        ),
      ],
    );
  }

  void _openOrder(BuildContext context, Order order) {
    Navigator.of(context).pushNamed(AppRoutes.order, arguments: order);
  }
}

/// An order that needs the client stands out with a filled dot and a bold status.
class _ActiveOrderRow extends StatelessWidget {
  const _ActiveOrderRow(this.order, {required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: AppColors.pressedCell,
      splashFactory: NoSplash.splashFactory,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            children: [
              _StatusDot(isFilled: order.needsClient),
              const SizedBox(width: 12),
              Expanded(child: _texts()),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.tertiaryLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _texts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(order.work, style: AppText.body),
        const SizedBox(height: 2),
        Text(
          order.statusLine,
          style: order.needsClient
              ? AppText.callout.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)
              : AppText.callout,
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isFilled});

  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? AppColors.ink : null,
        border: isFilled ? null : Border.all(color: AppColors.tertiaryLabel, width: 2),
      ),
    );
  }
}

class _DeliveredOrderRow extends StatelessWidget {
  const _DeliveredOrderRow(this.order);

  final Order order;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(order.work, style: AppText.body.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(order.statusLine, style: AppText.callout.copyWith(fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
