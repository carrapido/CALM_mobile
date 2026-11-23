import 'package:calm_mobil/models/booking_months.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> calendar({required String today, String now = '09:00', List<String> blocked = const []}) {
  return {
    'today': today,
    'now': now,
    'weekly': [
      for (final weekday in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'])
        {'weekday': weekday, 'opens_at': '10:00', 'closes_at': '18:00'},
      {'weekday': 'sunday', 'opens_at': null, 'closes_at': null},
    ],
    'blocked': blocked,
    'booked': const [],
  };
}

void main() {
  group('BookingMonths.fromCalendar', () {
    test('holds this month and the next', () {
      final months = BookingMonths.fromCalendar(calendar(today: '2026-11-22')).months;

      expect(months.map((month) => month.monthName), ['Noviembre 2026', 'Diciembre 2026']);
    });
  });

  group('BookingMonths.opening', () {
    test('is the first free day after today in this month', () {
      final opening = BookingMonths.fromCalendar(calendar(today: '2026-11-22')).opening;

      expect((opening!.month, opening.day), (0, 23));
    });

    test('is the first free day of the next month when none is left in this one', () {
      final opening = BookingMonths.fromCalendar(calendar(today: '2026-11-30')).opening;

      expect((opening!.month, opening.day), (1, 1));
    });

    test('is today only when no later day of either month is free', () {
      final december = [for (var day = 1; day <= 31; day++) '2026-12-${day.toString().padLeft(2, '0')}'];
      final opening = BookingMonths.fromCalendar(calendar(today: '2026-11-30', blocked: december)).opening;

      expect((opening!.month, opening.day), (0, 30));
    });

    test('is null when neither month has a free slot', () {
      final december = [for (var day = 1; day <= 31; day++) '2026-12-${day.toString().padLeft(2, '0')}'];
      final closingTime = calendar(today: '2026-11-30', now: '18:00', blocked: december);

      expect(BookingMonths.fromCalendar(closingTime).opening, isNull);
    });
  });
}
