import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/appointment_agenda.dart';
import '../models/booking.dart';
import '../models/booking_form.dart';
import '../models/field_problem.dart';
import '../models/login_form.dart';
import '../models/order.dart';
import '../models/service_selection.dart';
import '../routes/app_routes.dart';
import '../services/client_data.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/telefono_formatter.dart';
import 'action_button.dart';
import 'form_alert.dart';
import 'group_footnote.dart';
import 'inset_group.dart';
import 'labeled_field_row.dart';
import 'loaded.dart';
import 'section_header.dart';
import 'sheet_parts.dart';

/// Opens "Agendar cita" for the marked repairs: day, time and the client's data, then the ticket.
Future<void> showScheduleSheet(BuildContext context, ServiceSelection selection) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.groupedBackground,
    barrierColor: AppColors.sheetScrim,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    sheetAnimationStyle: sheetMotion(context),
    builder: (sheetContext) => Loaded<AppointmentAgenda>(
      load: ClientDataScope.of(sheetContext).agenda,
      pending: (status) => Padding(padding: const EdgeInsets.all(16), child: status),
      builder: (_, agenda) => agenda.firstBookableDay == null
          ? const _NoFreeSlots()
          : ScheduleSheet(selection: selection, agenda: agenda),
    ),
  );
}

/// The month the agenda covers has no free slot left.
class _NoFreeSlots extends StatelessWidget {
  const _NoFreeSlots();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Text(
        'Ya no quedan horarios libres este mes. Escríbele al taller.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ScheduleSheet extends StatefulWidget {
  const ScheduleSheet({super.key, required this.selection, required this.agenda});

  final ServiceSelection selection;

  /// Has at least one free slot: [showScheduleSheet] says so instead of opening an empty agenda.
  final AppointmentAgenda agenda;

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  // A slot someone takes meanwhile is marked booked here, so the client moves off it.
  late AppointmentAgenda _agenda = widget.agenda;
  String? _ticket;
  bool _isBooking = false;

  // The workshop's refusal, shown until the client edits something.
  String? _refusal;
  BookingField? _refusedField;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nipController = TextEditingController();
  late final FixedExtentScrollController _hourWheel;
  late final FixedExtentScrollController _minuteWheel;
  bool _isConfirmed = false;
  bool _showsProblem = false;
  // Opens on the first free day after today, at the free time closest to 11:00.
  late int _day = _agenda.firstBookableDay!;
  late String _time = _agenda.nearestSlot(_day, '11:00');

  @override
  void initState() {
    super.initState();
    _hourWheel = FixedExtentScrollController(initialItem: _hourIndexOf(_time));
    _minuteWheel = FixedExtentScrollController(initialItem: _minuteIndexOf(_time));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nipController.dispose();
    _hourWheel.dispose();
    _minuteWheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The sheet stops 6 % short of the top and shrinks above the keyboard.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.94,
        child: Column(
          children: [
            _SheetHeader(isConfirmed: _isConfirmed, onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: _isConfirmed ? _confirmation() : _choices(),
              ),
            ),
            _SheetFooter(children: _isConfirmed ? _confirmedActions() : _choosingActions()),
          ],
        ),
      ),
    );
  }

  String get _summary => '${_agenda.shortDayLabel(_day)}, $_time';

  List<Widget> _choices() {
    final problem = _refusedField ?? (_showsProblem ? _currentProblem()?.field : null);
    return [
      _SelectionCard(selection: widget.selection),
      const SectionHeader('Día', topSpacing: 20),
      _MonthCalendar(agenda: _agenda, selectedDay: _day, onPick: _pickDay),
      const SectionHeader('Hora', topSpacing: 20),
      _TimeWheels(
        hours: _agenda.wheelHoursFor(_day),
        time: _time,
        isFree: (time) => _agenda.isFree(_day, time),
        hourWheel: _hourWheel,
        minuteWheel: _minuteWheel,
        onHourChanged: (hour) => _setTime('$hour:${_minuteOf(_time)}'),
        onMinuteChanged: (minute) => _setTime('${_hourOf(_time)}:$minute'),
        onSettled: _settleOnFreeSlot,
      ),
      const GroupFootnote('Gira para elegir. Las horas en gris no están disponibles.'),
      const SectionHeader('Tus datos', topSpacing: 20),
      _contactGroup(problem),
      const GroupFootnote(
        'Con este celular y tu NIP ves tus pedidos. El NIP no es para pagar. '
        'Te confirmamos por WhatsApp.',
      ),
    ];
  }

  FieldProblem<BookingField>? _currentProblem() {
    return BookingForm(
      name: _nameController.text,
      phone: _phoneController.text,
      nip: _nipController.text,
    ).firstProblem();
  }

  // The hour wheel changes length with the day, so it scrolls once the new hours are laid out.
  void _pickDay(int day) {
    setState(() {
      _day = day;
      _time = _agenda.nearestSlot(day, _time);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollWheelsTo(_time));
  }

  void _setTime(String time) {
    if (time != _time) setState(() => _time = time);
  }

  // Like an iOS picker with a minimum date: an unavailable time rolls to the nearest free one.
  void _settleOnFreeSlot() {
    if (_agenda.isFree(_day, _time)) return;
    final nearest = _agenda.nearestSlot(_day, _time);
    setState(() => _time = nearest);
    _scrollWheelsTo(nearest);
  }

  void _scrollWheelsTo(String time) {
    _scrollWheel(_hourWheel, _hourIndexOf(time));
    _scrollWheel(_minuteWheel, _minuteIndexOf(time));
  }

  void _scrollWheel(FixedExtentScrollController wheel, int index) {
    if (!wheel.hasClients || index < 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      wheel.jumpToItem(index);
      return;
    }
    wheel.animateToItem(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  int _hourIndexOf(String time) => _agenda.wheelHoursFor(_day).indexOf(_hourOf(time));

  int _minuteIndexOf(String time) => AppointmentAgenda.wheelMinutes.indexOf(_minuteOf(time));

  Widget _contactGroup(BookingField? invalidField) {
    return InsetGroup(
      children: [
        LabeledFieldRow(
          label: 'Nombre',
          hint: 'Tu nombre',
          controller: _nameController,
          isInvalid: invalidField == BookingField.name,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _hideProblem(),
        ),
        LabeledFieldRow(
          label: 'Celular',
          hint: '998 123 4567',
          controller: _phoneController,
          isInvalid: invalidField == BookingField.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [TelefonoFormatter()],
          textInputAction: TextInputAction.next,
          onChanged: (_) => _hideProblem(),
        ),
        LabeledFieldRow(
          label: 'NIP',
          hint: '4 dígitos',
          controller: _nipController,
          isInvalid: invalidField == BookingField.nip,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(LoginForm.nipLength),
          ],
          obscureText: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) => _hideProblem(),
        ),
      ],
    );
  }

  void _hideProblem() {
    if (!_showsProblem && _refusal == null) return;
    setState(() {
      _showsProblem = false;
      _refusal = null;
      _refusedField = null;
    });
  }

  List<Widget> _choosingActions() {
    final message = _refusal ?? (_showsProblem ? _currentProblem()?.message : null);
    return [
      if (message != null) FormAlert(message),
      ActionButton.primary(label: 'Confirmar · $_summary', onPressed: _confirm),
    ];
  }

  /// The form's own rules first; only complete data is worth a trip to the workshop.
  Future<void> _confirm() async {
    if (_isBooking) return;
    if (_currentProblem() != null) {
      setState(() => _showsProblem = true);
      return;
    }

    setState(() => _isBooking = true);
    final outcome = await ClientDataScope.of(context).book(_bookingRequest());
    if (!mounted) return;
    setState(() {
      _isBooking = false;
      _answer(outcome);
    });
  }

  BookingRequest _bookingRequest() {
    return BookingRequest(
      name: _nameController.text.trim(),
      phoneDigits: digitsOf(_phoneController.text),
      nip: _nipController.text,
      selection: widget.selection,
      date: _agenda.isoDate(_day),
      time: _time,
    );
  }

  void _answer(BookingOutcome outcome) {
    switch (outcome) {
      case BookingConfirmed(:final ticket):
        _ticket = ticket;
        _isConfirmed = true;
      case BookingSlotTaken():
        _agenda = _agenda.withBooked(_day, _time);
        _moveOffTakenSlot();
        _refusal = AppConstants.bookingSlotTaken;
      case BookingRefused(:final message, :final field):
        _refusal = message;
        _refusedField = field;
    }
  }

  /// To the free time closest to the taken one, on another day when that one is now full.
  void _moveOffTakenSlot() {
    if (!_agenda.isAvailable(_day)) {
      final day = _agenda.firstBookableDay;
      if (day == null) return;
      _day = day;
    }
    _time = _agenda.nearestSlot(_day, _time);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollWheelsTo(_time));
  }

  List<Widget> _confirmation() {
    return [
      _ConfirmationHeading(details: '$_summary · ${widget.selection.names}'),
      const SizedBox(height: 16),
      _TicketCard(ticket: _ticket!),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Text(
          'Tu cita ya aparece en Pedidos. Muestra este ticket en el taller.',
          textAlign: TextAlign.center,
          style: AppText.footnote,
        ),
      ),
    ];
  }

  List<Widget> _confirmedActions() {
    return [ActionButton.primary(label: 'Ver mi cita', onPressed: _openAppointment)];
  }

  void _openAppointment() {
    final appointment = Order(
      ticket: _ticket!,
      work: widget.selection.names,
      status: OrderStatus.appointment,
      amountMxn: widget.selection.totalMxn,
      appointmentOn: '${_agenda.weekdayAndDay(_day)} a las $_time',
    );
    Navigator.of(context)
      ..pop()
      ..pushNamed(AppRoutes.order, arguments: appointment);
  }

  static String _hourOf(String time) => time.split(':').first;

  static String _minuteOf(String time) => time.split(':').last;
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.isConfirmed, required this.onClose});

  final bool isConfirmed;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          const SheetGrabber(),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: isConfirmed ? null : _headerButton('Cancelar', FontWeight.w500),
                ),
                Expanded(
                  child: Text(
                    'Agendar cita',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: isConfirmed ? _headerButton('Listo', FontWeight.w800) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton(String label, FontWeight weight) {
    return TextButton(
      onPressed: onClose,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: AppText.body.copyWith(fontWeight: weight),
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label),
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.groupedBackground,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.selection});

  final ServiceSelection selection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(selection.names, style: AppText.button),
          Text('Cotización preliminar: ${selection.quote}', style: AppText.footnote),
        ],
      ),
    );
  }
}

/// Month grid, weeks starting on Monday. Days without a free slot keep their place in gray.
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.agenda, required this.selectedDay, required this.onPick});

  final AppointmentAgenda agenda;
  final int selectedDay;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Text(agenda.monthName, style: AppText.body.copyWith(fontWeight: FontWeight.w800)),
          ),
          _weekdayInitials(),
          const SizedBox(height: 4),
          for (final week in _weeks())
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(children: [for (final day in week) Expanded(child: _cell(day))]),
            ),
        ],
      ),
    );
  }

  Widget _weekdayInitials() {
    return Row(
      children: [
        for (final initial in AppointmentAgenda.weekdayInitials)
          Expanded(
            child: Text(
              initial,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  /// Rows of seven cells; null cells are the blanks before the 1st and after the last day.
  List<List<int?>> _weeks() {
    final cells = <int?>[
      for (var blank = 1; blank < agenda.firstWeekday; blank++) null,
      for (var day = 1; day <= agenda.daysInMonth; day++) day,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return [for (var start = 0; start < cells.length; start += 7) cells.sublist(start, start + 7)];
  }

  Widget _cell(int? day) {
    if (day == null) return const SizedBox(height: 40);
    final isAvailable = agenda.isAvailable(day);
    return _DayButton(
      day: day,
      label: agenda.longDayLabel(day),
      isSelected: day == selectedDay,
      isToday: day == agenda.today,
      isAvailable: isAvailable,
      onTap: isAvailable ? () => onPick(day) : null,
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.label,
    required this.isSelected,
    required this.isToday,
    required this.isAvailable,
    required this.onTap,
  });

  final int day;
  final String label;
  final bool isSelected;
  final bool isToday;
  final bool isAvailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isAvailable ? label : '$label, no disponible',
      button: true,
      selected: isSelected,
      enabled: isAvailable,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.ink : null,
              border: isToday && !isSelected ? Border.all(color: AppColors.ink, width: 1.5) : null,
            ),
            child: Text(
              '$day',
              style: AppText.body.copyWith(
                color: _textColor(),
                fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _textColor() {
    if (isSelected) return Colors.white;
    return isAvailable ? AppColors.ink : AppColors.disabledLabel;
  }
}

/// Alarm-style hour and minute wheels over one highlight band; unavailable values stay, in gray.
class _TimeWheels extends StatelessWidget {
  const _TimeWheels({
    required this.hours,
    required this.time,
    required this.isFree,
    required this.hourWheel,
    required this.minuteWheel,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onSettled,
  });

  static const _rowHeight = 40.0;

  final List<String> hours;
  final String time;
  final bool Function(String time) isFree;
  final FixedExtentScrollController hourWheel;
  final FixedExtentScrollController minuteWheel;
  final ValueChanged<String> onHourChanged;
  final ValueChanged<String> onMinuteChanged;
  final VoidCallback onSettled;

  @override
  Widget build(BuildContext context) {
    final [hour, minute] = time.split(':');
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            right: 12,
            height: _rowHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.tintedFill,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              _wheel(
                controller: hourWheel,
                values: hours,
                selected: hour,
                isValueFree: (value) => AppointmentAgenda.wheelMinutes.any((m) => isFree('$value:$m')),
                onChanged: onHourChanged,
              ),
              Text(':', style: _valueStyle(AppColors.ink, FontWeight.w800)),
              _wheel(
                controller: minuteWheel,
                values: AppointmentAgenda.wheelMinutes,
                selected: minute,
                isValueFree: (value) => isFree('$hour:$value'),
                onChanged: onMinuteChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required List<String> values,
    required String selected,
    required bool Function(String value) isValueFree,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 88,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (_) {
          onSettled();
          return false;
        },
        child: CupertinoPicker(
          scrollController: controller,
          itemExtent: _rowHeight,
          selectionOverlay: null,
          onSelectedItemChanged: (index) => onChanged(values[index]),
          children: [
            for (final value in values)
              Center(child: Text(value, style: _itemStyle(value == selected, isValueFree(value)))),
          ],
        ),
      ),
    );
  }

  TextStyle _itemStyle(bool isSelected, bool isFree) {
    if (isSelected) return _valueStyle(AppColors.ink, FontWeight.w800);
    return _valueStyle(isFree ? AppColors.onSurfaceVariant : AppColors.disabledLabel, FontWeight.w600);
  }

  TextStyle _valueStyle(Color color, FontWeight weight) {
    return AppText.statusHeadline.copyWith(
      fontSize: 24,
      height: 40 / 24,
      letterSpacing: 0,
      color: color,
      fontWeight: weight,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

class _ConfirmationHeading extends StatelessWidget {
  const _ConfirmationHeading({required this.details});

  final String details;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
        child: Column(
          spacing: 6,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 30, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text('Cita agendada', style: AppText.statusHeadline),
            Text(details, textAlign: TextAlign.center, style: AppText.lead.copyWith(height: 22 / 17)),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final String ticket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        spacing: 2,
        children: [
          Text('Tu ticket', style: AppText.footnote.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
          Text(
            ticket,
            style: AppText.statusHeadline.copyWith(fontSize: 48, height: 56 / 48, letterSpacing: 2.88),
          ),
        ],
      ),
    );
  }
}
