/// Dates worded as the client reads them: "jueves 26", "13 de noviembre".
const _weekdayNames = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _monthNames = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String weekdayName(DateTime date) => _weekdayNames[date.weekday - 1];

String monthName(int month) => _monthNames[month - 1];

/// "13 de noviembre".
String dayAndMonth(DateTime date) => '${date.day} de ${monthName(date.month)}';

/// "11:00".
String clockTime(DateTime moment) {
  return '${moment.hour.toString().padLeft(2, '0')}:${moment.minute.toString().padLeft(2, '0')}';
}

/// The workshop's wall clock, wherever the phone is. Cancún keeps UTC−5 all year: Quintana Roo
/// dropped daylight saving in 2015.
DateTime cancunNow() {
  final cancun = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  return DateTime(cancun.year, cancun.month, cancun.day, cancun.hour, cancun.minute);
}
