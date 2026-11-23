import '../utils/spanish_dates.dart' as dates;

/// A month of the workshop's agenda: business hours per weekday minus past days, blocked days,
/// bookings and, today, the slots that have already started. Weekdays run from 1 (Monday) to
/// 7 (Sunday); times are Cancún wall-clock "HH:MM".
class AppointmentAgenda {
  const AppointmentAgenda({
    required this.year,
    required this.month,
    required this.monthName,
    required this.monthLongName,
    required this.daysInMonth,
    required this.firstWeekday,
    required this.today,
    required this.nowTime,
    required this.slotsByWeekday,
    required this.blockedDays,
    required this.bookedSlots,
  });

  /// What `booking_calendar` answers: today and now, the weekly hours, and the blocked days and
  /// booked slots from today to the end of next month. [monthsAhead] picks the month: 0 is the
  /// current one, 1 the next, where no day is past and none is today. Slots follow the panel's
  /// rule, every 30 minutes from opening up to, but not including, closing; a weekday with no
  /// hours is closed.
  factory AppointmentAgenda.fromCalendar(Map<String, dynamic> calendar, {int monthsAhead = 0}) {
    final today = DateTime.parse(calendar['today'] as String);
    final first = DateTime(today.year, today.month + monthsAhead);
    bool inMonth(DateTime date) => date.year == first.year && date.month == first.month;
    final month = dates.monthName(first.month);
    return AppointmentAgenda(
      year: first.year,
      month: first.month,
      monthName: '${month[0].toUpperCase()}${month.substring(1)} ${first.year}',
      monthLongName: month,
      daysInMonth: DateTime(first.year, first.month + 1, 0).day,
      firstWeekday: first.weekday,
      today: monthsAhead == 0 ? today.day : 0,
      nowTime: calendar['now'] as String,
      slotsByWeekday: {
        for (final hours in (calendar['weekly'] as List).cast<Map<String, dynamic>>())
          _weekdayNumbers[hours['weekday']]!: _slotsBetween(hours['opens_at'], hours['closes_at']),
      },
      blockedDays: {
        for (final date in (calendar['blocked'] as List).cast<String>().map(DateTime.parse))
          if (inMonth(date)) date.day,
      },
      bookedSlots: _bookedByDay([
        for (final slot in (calendar['booked'] as List).cast<Map<String, dynamic>>())
          if (inMonth(DateTime.parse(slot['date'] as String))) slot,
      ]),
    );
  }

  static const _weekdayNumbers = {
    'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
    'friday': 5, 'saturday': 6, 'sunday': 7,
  };

  static const weekdayInitials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const wheelMinutes = ['00', '30'];
  static const _weekdayShortNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _weekdayLongNames = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];

  final int year;
  final int month;
  final String monthName;
  final String monthLongName;
  final int daysInMonth;
  final int firstWeekday;
  /// Today's day of this month; 0 in a month that has not started, where no day is past.
  final int today;

  /// Today's slots start after this time; one that has started is not free.
  final String nowTime;
  final Map<int, List<String>> slotsByWeekday;
  final Set<int> blockedDays;
  final Map<int, List<String>> bookedSlots;

  List<String> freeSlotsFor(int day) {
    if (day < 1 || day > daysInMonth || day < today || blockedDays.contains(day)) return const [];
    final booked = bookedSlots[day] ?? const [];
    return [
      for (final slot in slotsByWeekday[weekdayOf(day)] ?? const <String>[])
        if (!booked.contains(slot) && (day != today || slot.compareTo(nowTime) > 0)) slot,
    ];
  }

  /// [day] of this month as the server writes a date: "2026-11-05".
  String isoDate(int day) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '$year-${twoDigits(month)}-${twoDigits(day)}';
  }

  /// This agenda with [time] of [day] booked, as when someone took it meanwhile.
  AppointmentAgenda withBooked(int day, String time) {
    return AppointmentAgenda(
      year: year,
      month: month,
      monthName: monthName,
      monthLongName: monthLongName,
      daysInMonth: daysInMonth,
      firstWeekday: firstWeekday,
      today: today,
      nowTime: nowTime,
      slotsByWeekday: slotsByWeekday,
      blockedDays: blockedDays,
      bookedSlots: {
        ...bookedSlots,
        day: [...?bookedSlots[day], time],
      },
    );
  }

  /// Where "Agendar cita" opens: the first free day after today, or today when it is the only
  /// one left in the month; null when the month has no free slot at all.
  int? get firstBookableDay {
    for (var day = today + 1; day <= daysInMonth; day++) {
      if (isAvailable(day)) return day;
    }
    return isAvailable(today) ? today : null;
  }

  bool isAvailable(int day) => freeSlotsFor(day).isNotEmpty;

  bool isFree(int day, String time) => freeSlotsFor(day).contains(time);

  int weekdayOf(int day) => (firstWeekday - 1 + day - 1) % 7 + 1;

  String shortDayLabel(int day) {
    return day == today ? 'Hoy' : '${_weekdayShortNames[weekdayOf(day) - 1]} $day';
  }

  String longDayLabel(int day) {
    final label = '${weekdayAndDay(day)} de $monthLongName';
    return day == today ? 'Hoy, $label' : label;
  }

  /// "jueves 5", as an appointment is worded.
  String weekdayAndDay(int day) => '${_weekdayLongNames[weekdayOf(day) - 1]} $day';

  /// From the first to the last free hour of the day; gaps in between stay, shown in gray.
  List<String> wheelHoursFor(int day) {
    final slots = freeSlotsFor(day);
    if (slots.isEmpty) return const [];
    return [
      for (var hour = _hourOf(slots.first); hour <= _hourOf(slots.last); hour++)
        hour.toString().padLeft(2, '0'),
    ];
  }

  /// The free slot of [day] closest to [time]; [time] itself when it is free.
  String nearestSlot(int day, String time) {
    final target = _minutesOf(time);
    int distance(String slot) => (_minutesOf(slot) - target).abs();
    return freeSlotsFor(day).reduce((best, slot) => distance(slot) < distance(best) ? slot : best);
  }

  static int _hourOf(String time) => int.parse(time.split(':').first);

  static int _minutesOf(String time) {
    final [hours, minutes] = time.split(':').map(int.parse).toList();
    return hours * 60 + minutes;
  }

  static List<String> _slotsBetween(Object? opensAt, Object? closesAt) {
    if (opensAt == null || closesAt == null) return const [];
    final closing = _minutesOf(closesAt as String);
    return [
      for (var minutes = _minutesOf(opensAt as String); minutes < closing; minutes += 30)
        '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}',
    ];
  }

  static Map<int, List<String>> _bookedByDay(List<Map<String, dynamic>> booked) {
    final byDay = <int, List<String>>{};
    for (final slot in booked) {
      final day = DateTime.parse(slot['date'] as String).day;
      byDay.putIfAbsent(day, () => []).add(slot['time'] as String);
    }
    return byDay;
  }
}
