import 'appointment_agenda.dart';

/// The months "Agendar cita" offers: the current one and the next, so late in a month the client
/// still has days to choose from.
class BookingMonths {
  const BookingMonths(this.months);

  /// What `booking_calendar` answers, split into this month and the next.
  factory BookingMonths.fromCalendar(Map<String, dynamic> calendar) {
    return BookingMonths([
      AppointmentAgenda.fromCalendar(calendar),
      AppointmentAgenda.fromCalendar(calendar, monthsAhead: 1),
    ]);
  }

  /// What `GET /api/client/booking-calendar` answers, in camelCase. Dates are read as their first
  /// ten characters and times as "HH:MM", whether the server writes "10:00" or "10:00:00".
  factory BookingMonths.fromApi(Map<String, dynamic> calendar) {
    String? time(Object? value) => value == null ? null : (value as String).substring(0, 5);
    String date(Object? value) => (value as String).substring(0, 10);
    return BookingMonths.fromCalendar({
      'today': date(calendar['today']),
      'now': time(calendar['now']),
      'weekly': [
        for (final hours in (calendar['weekly'] as List).cast<Map<String, dynamic>>())
          {
            'weekday': hours['weekday'],
            'opens_at': time(hours['opensAt']),
            'closes_at': time(hours['closesAt']),
          },
      ],
      'blocked': [for (final day in calendar['blocked'] as List) date(day)],
      'booked': [
        for (final slot in (calendar['booked'] as List).cast<Map<String, dynamic>>())
          {'date': date(slot['date']), 'time': time(slot['time'])},
      ],
    });
  }

  /// In order, the current month first.
  final List<AppointmentAgenda> months;

  /// Where the sheet opens: the first free day after today, in this month or the next; today only
  /// when no later day is free. Null when no month offered has a free slot.
  ({int month, int day})? get opening {
    final current = months.first;
    final inCurrent = current.firstBookableDay;
    if (inCurrent != null && inCurrent != current.today) return (month: 0, day: inCurrent);
    for (var index = 1; index < months.length; index++) {
      if (months[index].firstBookableDay case final day?) return (month: index, day: day);
    }
    return inCurrent == null ? null : (month: 0, day: inCurrent);
  }
}
