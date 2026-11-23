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
