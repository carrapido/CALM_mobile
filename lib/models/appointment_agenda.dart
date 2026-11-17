/// A month of the workshop's agenda as the API would send it: business hours minus past days,
/// the closed weekday, blocked days and bookings. Weekdays run from 1 (Monday) to 7 (Sunday).
class AppointmentAgenda {
  const AppointmentAgenda({
    required this.monthName,
    required this.monthLongName,
    required this.daysInMonth,
    required this.firstWeekday,
    required this.today,
    required this.closedWeekday,
    required this.blockedDays,
    required this.businessSlots,
    required this.todaySlots,
    required this.bookedSlots,
  });

  /// The panel's demo agenda: the 1st is a Sunday, today is Wednesday the 4th,
  /// Sundays are closed and Friday the 6th was blocked.
  static const november2026 = AppointmentAgenda(
    monthName: 'Noviembre 2026',
    monthLongName: 'noviembre',
    daysInMonth: 30,
    firstWeekday: 7,
    today: 4,
    closedWeekday: 7,
    blockedDays: {6},
    businessSlots: [
      '10:00', '10:30', '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
      '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    ],
    todaySlots: ['15:30', '16:00', '16:30', '17:00', '17:30'],
    bookedSlots: {
      5: ['12:00', '12:30', '14:30'],
    },
  );

  static const weekdayInitials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const wheelMinutes = ['00', '30'];
  static const _weekdayShortNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _weekdayLongNames = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];

  final String monthName;
  final String monthLongName;
  final int daysInMonth;
  final int firstWeekday;
  final int today;
  final int closedWeekday;
  final Set<int> blockedDays;
  final List<String> businessSlots;
  final List<String> todaySlots;
  final Map<int, List<String>> bookedSlots;

  List<String> freeSlotsFor(int day) {
    if (!_isOpen(day)) return const [];
    if (day == today) return todaySlots;
    final booked = bookedSlots[day] ?? const [];
    return [
      for (final slot in businessSlots)
        if (!booked.contains(slot)) slot,
    ];
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

  bool _isOpen(int day) {
    return day >= today && weekdayOf(day) != closedWeekday && !blockedDays.contains(day);
  }

  static int _hourOf(String time) => int.parse(time.split(':').first);

  static int _minutesOf(String time) {
    final [hours, minutes] = time.split(':').map(int.parse).toList();
    return hours * 60 + minutes;
  }
}
