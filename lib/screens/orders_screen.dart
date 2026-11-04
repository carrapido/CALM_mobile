import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/order.dart';
import '../routes/app_routes.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../widgets/boton_taller.dart';
import '../widgets/bottom_nav_bar_widget.dart';
import '../widgets/top_app_bar_widget.dart';

const _subtleDivider = Divider(
  height: 1,
  thickness: 1,
  color: AppColors.borderSubtle,
);

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({
    super.key,
    this.activeOrder = Order.mockActive,
    this.pastOrders = Order.mockPast,
  });

  static const int _servicesTab = 0;
  static const int _scheduleTab = 1;
  static const int _ordersTab = 2;
  static const int _profileTab = 3;
  static const String _sectionComingSoon =
      'Esta sección estará disponible próximamente.';
  static const String _featureComingSoon =
      'Esta función estará disponible próximamente.';

  final Order activeOrder;
  final List<Order> pastOrders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: TopAppBarWidget(
        onHelpPressed: () => _showMessage(context, 'Ayuda del Taller'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              const _OrdersHeader(),
              const SizedBox(height: 24),
              _ActiveOrderSection(
                order: activeOrder,
                onNotifyPickup: () => _showMessage(context, _featureComingSoon),
              ),
              const SizedBox(height: 24),
              _PastOrdersSection(orders: pastOrders),
              const SizedBox(height: 24),
              _ScheduleRepairButton(
                onPressed: () => _showMessage(context, _sectionComingSoon),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _ordersTab,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case _servicesTab:
        Navigator.of(context).pushReplacementNamed(AppRoutes.services);
      case _scheduleTab:
        _showMessage(context, _sectionComingSoon);
      case _profileTab:
        Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
    }
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis Pedidos', style: AppText.headlineXlMobile),
        const SizedBox(height: 4),
        Text(
          'Seguimiento de tus prendas en taller',
          style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ActiveOrderSection extends StatelessWidget {
  const _ActiveOrderSection({
    required this.order,
    required this.onNotifyPickup,
  });

  final Order order;
  final VoidCallback onNotifyPickup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Pedido en curso',
          trailing: order.isReadyForPickup ? const _ReadyBadge() : null,
        ),
        const SizedBox(height: 12),
        _ActiveOrderCard(order: order, onNotifyPickup: onNotifyPickup),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppText.labelLg)),
        ?trailing,
      ],
    );
  }
}

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ticketYellow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '¡Listo para recoger!',
        style: _withWeight(AppText.labelSm, FontWeight.w700),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order, required this.onNotifyPickup});

  final Order order;
  final VoidCallback onNotifyPickup;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderStrong, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TicketSummary(order: order),
          const SizedBox(height: 12),
          _subtleDivider,
          const SizedBox(height: 14),
          _GarmentDetail(description: order.description),
          const SizedBox(height: 16),
          _OrderProgress(currentStatus: order.status),
          if (order.isReadyForPickup) ...[
            const SizedBox(height: 16),
            _PickupDetails(onNotifyPickup: onNotifyPickup),
          ],
        ],
      ),
    );
  }
}

class _TicketSummary extends StatelessWidget {
  const _TicketSummary({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SummaryField(
          label: 'Ticket',
          value: '#${order.ticket}',
          alignment: CrossAxisAlignment.start,
        ),
        _SummaryField(
          label: 'Por liquidar',
          value: order.formattedPrice,
          alignment: CrossAxisAlignment.end,
        ),
      ],
    );
  }
}

class _SummaryField extends StatelessWidget {
  const _SummaryField({
    required this.label,
    required this.value,
    required this.alignment,
  });

  final String label;
  final String value;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        Text(value, style: AppText.headlineLg),
      ],
    );
  }
}

class _GarmentDetail extends StatelessWidget {
  const _GarmentDetail({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.checkroom_outlined,
          color: AppColors.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(description, style: AppText.labelLg)),
      ],
    );
  }
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.currentStatus});

  final OrderStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final status in OrderStatus.values)
          Expanded(
            child: _ProgressStep(
              label: status.label,
              stage: _ProgressStage.of(status, currentStatus),
            ),
          ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.label, required this.stage});

  final String label;
  final _ProgressStage stage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: _withWeight(
            AppText.labelSm.copyWith(color: stage.labelColor),
            stage.labelWeight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: stage.barColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: stage.barBorderColor),
          ),
        ),
      ],
    );
  }
}

enum _ProgressStage {
  completed(
    barColor: AppColors.borderStrong,
    barBorderColor: AppColors.borderStrong,
    labelColor: AppColors.onSurfaceVariant,
    labelWeight: FontWeight.w500,
  ),
  current(
    barColor: AppColors.ticketYellow,
    barBorderColor: AppColors.borderStrong,
    labelColor: AppColors.borderStrong,
    labelWeight: FontWeight.w700,
  ),
  upcoming(
    barColor: AppColors.surfaceSubtle,
    barBorderColor: AppColors.borderSubtle,
    labelColor: AppColors.outline,
    labelWeight: FontWeight.w400,
  );

  const _ProgressStage({
    required this.barColor,
    required this.barBorderColor,
    required this.labelColor,
    required this.labelWeight,
  });

  final Color barColor;
  final Color barBorderColor;
  final Color labelColor;
  final FontWeight labelWeight;

  static _ProgressStage of(OrderStatus status, OrderStatus currentStatus) {
    if (status.index < currentStatus.index) return completed;
    return status == currentStatus ? current : upcoming;
  }
}

class _PickupDetails extends StatelessWidget {
  const _PickupDetails({required this.onNotifyPickup});

  final VoidCallback onNotifyPickup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _subtleDivider,
        const SizedBox(height: 8),
        Text(
          '10:00 - 18:00',
          textAlign: TextAlign.end,
          style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        BotonTaller(
          texto: 'Avisar que voy en camino',
          icono: Icons.chat_outlined,
          onPressed: onNotifyPickup,
        ),
      ],
    );
  }
}

class _PastOrdersSection extends StatelessWidget {
  const _PastOrdersSection({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Pedidos anteriores',
          trailing: Text(
            _deliveredCount,
            style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 10),
        _subtleDivider,
        for (final order in orders) ...[
          _PastOrderRow(order: order),
          _subtleDivider,
        ],
      ],
    );
  }

  String get _deliveredCount {
    final count = orders.length;
    return count == 1 ? '1 entregado' : '$count entregados';
  }
}

class _PastOrderRow extends StatelessWidget {
  const _PastOrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Ticket #${order.ticket}',
                      style: _withWeight(AppText.labelMd, FontWeight.w700),
                    ),
                    Text(
                      order.status.label,
                      style: AppText.labelSm.copyWith(
                        color: AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [order.description, ?order.deliveredOn].join(' · '),
                  style: AppText.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            order.formattedPrice,
            style: _withWeight(AppText.headlineSm, FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRepairButton extends StatelessWidget {
  const _ScheduleRepairButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Agendar nuevo arreglo'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.borderStrong,
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: AppColors.borderStrong, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppText.labelLg,
      ),
    );
  }
}

// google_fonts encodes the weight in the font family name, so
// `copyWith(fontWeight:)` keeps rendering the face that was already resolved.
TextStyle _withWeight(TextStyle style, FontWeight weight) {
  return GoogleFonts.plusJakartaSans(textStyle: style, fontWeight: weight);
}
