import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/client_action.dart';
import '../models/order.dart';
import '../routes/app_routes.dart';
import '../services/client_data.dart';
import '../services/external_links.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/action_button.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/destructive_row.dart';
import '../widgets/form_alert.dart';
import '../widgets/icon_row.dart';
import '../widgets/inset_group.dart';
import '../widgets/page_heading.dart';
import '../widgets/section_header.dart';
import '../widgets/session_end.dart';
import '../widgets/status_note.dart';
import '../widgets/tab_page.dart';

/// Pedido: where one order or appointment stands and what the client can do about it.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late bool _isOnTheWay = widget.order.status == OrderStatus.onTheWay;
  bool _directionsOpened = false;
  bool _directionsFailed = false;
  bool _whatsAppFailed = false;
  bool _isActing = false;

  // What the workshop refused, shown where the client asked.
  String? _onTheWayRefusal;
  String? _cancelRefusal;

  Order get _order => widget.order;

  @override
  Widget build(BuildContext context) {
    return TabPage(
      tab: AppTab.orders,
      backLabel: 'Pedidos',
      children: [
        PageHeading('Pedido', subtitle: 'Ticket ${_order.ticket}'),
        _StatusCard(
          work: _order.work,
          headline: _headline(),
          progress: _order.isAppointment ? null : _order.status,
          actions: _actions(),
        ),
        ..._schedule(),
        SectionHeader(_order.isAppointment ? 'Cotización' : 'Pago'),
        InsetGroup(
          children: [
            _DetailRow(
              label: _order.isAppointment ? 'Cotización preliminar' : 'Total, se paga en el taller',
              value: _order.formattedAmount,
            ),
          ],
        ),
        ..._cancellation(),
        const SectionHeader('Más'),
        InsetGroup(
          children: [
            IconRow(
              icon: Icons.calendar_today_outlined,
              title: 'Agendar otra cita',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.services),
            ),
          ],
        ),
      ],
    );
  }

  // When she is expected: the appointment's day and time, or the order's delivery day.
  List<Widget> _schedule() {
    final day = _order.scheduledDay;
    if (day == null) return const [];
    return [
      SectionHeader(_order.isAppointment ? 'Tu cita' : 'Entrega'),
      InsetGroup(
        children: [
          _DetailRow(label: 'Fecha', value: day),
          if (_order.scheduledTime case final time?) _DetailRow(label: 'Hora', value: time),
        ],
      ),
    ];
  }

  String _headline() {
    return _order.needsClient && _isOnTheWay ? 'Vas en camino' : _order.status.headline;
  }

  // Ready orders and appointments need the client at the workshop; anything else is a question for it.
  List<Widget> _actions() {
    final showsDirections = _order.needsClient || _order.isAppointment;
    return [
      if (_order.needsClient) _onTheWayAction(),
      if (showsDirections)
        _directionsAction()
      else
        _writeAction(),
    ];
  }

  // WhatsApp takes over when it opens; when nothing takes the link, the number is there instead.
  Widget _writeAction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_whatsAppFailed) const FormAlert(AppConstants.whatsAppFailed),
        ActionButton.tinted(label: AppConstants.writeToWorkshop, onPressed: _writeToWorkshop),
      ],
    );
  }

  Future<void> _writeToWorkshop() async {
    final opened = await openWorkshopWhatsApp(context);
    if (!mounted) return;
    setState(() => _whatsAppFailed = !opened);
  }

  Widget _onTheWayAction() {
    if (_isOnTheWay) return const StatusNote('El taller ya sabe que vas en camino');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_onTheWayRefusal case final refusal?) FormAlert(refusal),
        ActionButton.primary(
          label: 'Voy en camino',
          icon: Icons.navigation_outlined,
          onPressed: _tellOnTheWay,
        ),
      ],
    );
  }

  Future<void> _tellOnTheWay() async {
    if (_isActing) return;
    setState(() => _isActing = true);
    final outcome = await ClientDataScope.of(context).markOnMyWay(_order.ticket);
    if (!mounted) return;
    if (outcome is ActionSignedOut) return endSession(context);
    setState(() {
      _isActing = false;
      switch (outcome) {
        case ActionDone():
          _isOnTheWay = true;
          _onTheWayRefusal = null;
        case ActionRefused(:final message):
          _onTheWayRefusal = message;
        case ActionSignedOut():
          break;
      }
    });
  }

  Widget _directionsAction() {
    if (_directionsOpened) return const StatusNote(AppConstants.directionsOpened);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_directionsFailed) const FormAlert(AppConstants.directionsFailed),
        ActionButton.tinted(
          label: AppConstants.helpDirections,
          icon: Icons.location_on_outlined,
          onPressed: _openDirections,
        ),
      ],
    );
  }

  // When nothing takes the link, the button stays and the address is there to search by hand.
  Future<void> _openDirections() async {
    final opened = await openWorkshopMap(context);
    if (!mounted) return;
    setState(() {
      _directionsOpened = opened;
      _directionsFailed = !opened;
    });
  }

  List<Widget> _cancellation() {
    if (!_order.isAppointment) return const [];
    if (!_order.isCancellable) return const [_LateCancellationNote()];
    return [
      const SizedBox(height: 24),
      DestructiveRow(label: 'Cancelar cita', onTap: _askToCancel),
      if (_cancelRefusal case final refusal?) FormAlert(refusal),
    ];
  }

  void _askToCancel() {
    showCupertinoModalPopup<void>(
      context: context,
      barrierColor: AppColors.sheetScrim,
      builder: (popupContext) => _CancelAppointmentSheet(
        freedSlotMessage: _freedSlotMessage(),
        onCancel: () {
          Navigator.of(popupContext).pop();
          _cancelAppointment();
        },
        onKeep: () => Navigator.of(popupContext).pop(),
      ),
    );
  }

  String _freedSlotMessage() {
    final slot = _order.appointmentOn;
    if (slot == null) return 'Tu horario queda libre para alguien más.';
    return 'Tu horario del $slot queda libre para alguien más.';
  }

  /// The workshop cancels it only more than 24 hours ahead and before it became an order; a
  /// refusal keeps the client on her appointment and says why.
  Future<void> _cancelAppointment() async {
    if (_isActing) return;
    setState(() => _isActing = true);
    final outcome = await ClientDataScope.of(context).cancelAppointment(_order.ticket);
    if (!mounted) return;
    switch (outcome) {
      case ActionDone():
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.initial, (_) => false);
      case ActionSignedOut():
        await endSession(context);
      case ActionRefused(:final message):
        setState(() {
          _isActing = false;
          _cancelRefusal = message;
        });
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.work,
    required this.headline,
    required this.progress,
    required this.actions,
  });

  final String work;
  final String headline;
  final OrderStatus? progress;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(work, style: AppText.subhead.copyWith(color: AppColors.onSurfaceVariant)),
              Text(headline, style: AppText.statusHeadline),
            ],
          ),
          if (progress case final current?) _ProgressSteps(current),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: actions),
        ],
      ),
    );
  }
}

/// The bar fills up to the current step; the current label is the bold one.
class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps(this.current);

  final OrderStatus current;

  static const _steps = [
    (status: OrderStatus.received, label: 'Recibido'),
    (status: OrderStatus.inProgress, label: 'En proceso'),
    (status: OrderStatus.ready, label: 'Listo'),
    (status: OrderStatus.delivered, label: 'Entregado'),
  ];

  @override
  Widget build(BuildContext context) {
    // On her way, the order is still at the workshop's "Listo" step.
    final reached = current == OrderStatus.onTheWay ? OrderStatus.ready : current;
    final currentIndex = _steps.indexWhere((candidate) => candidate.status == reached);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        for (final (index, step) in _steps.indexed)
          Expanded(
            child: _Step(
              label: step.label,
              isReached: index <= currentIndex,
              isCurrent: index == currentIndex,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.isReached, required this.isCurrent});

  final String label;
  final bool isReached;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: isReached ? AppColors.ink : AppColors.pendingStep,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Text(
          label,
          style: AppText.caption.copyWith(
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
            color: isCurrent ? AppColors.ink : AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w500)),
            ),
            // A long day wraps instead of pushing the row off a narrow phone.
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppText.body.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LateCancellationNote extends StatelessWidget {
  const _LateCancellationNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Text(
        'Faltan menos de 24 horas para tu cita: para cancelarla, escríbele al taller.',
        style: AppText.footnote,
      ),
    );
  }
}

class _CancelAppointmentSheet extends StatelessWidget {
  const _CancelAppointmentSheet({
    required this.freedSlotMessage,
    required this.onCancel,
    required this.onKeep,
  });

  final String freedSlotMessage;
  final VoidCallback onCancel;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text('¿Cancelar tu cita?', style: AppText.subhead.copyWith(fontWeight: FontWeight.w700)),
      message: Text(freedSlotMessage, style: AppText.footnote),
      actions: [
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: onCancel,
          child: Text(
            'Sí, cancelar la cita',
            style: AppText.actionSheetButton.copyWith(color: AppColors.errorRed),
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: onKeep,
        child: Text(
          'No, conservarla',
          style: AppText.actionSheetButton.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
