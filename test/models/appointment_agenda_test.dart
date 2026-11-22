import 'package:calm_mobil/models/appointment_agenda.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_client_data.dart';

/// What `booking_calendar` answered on Sunday, November 22 2026 at 17:40.
Map<String, dynamic> calendar({
  String today = '2026-11-22',
  String now = '17:40',
  List<String> blocked = const ['2026-11-25'],
  List<Map<String, String>> booked = const [{'date': '2026-11-24', 'time': '12:00'}],
}) {
  return {
    'today': today,
    'now': now,
    'weekly': [
      for (final weekday in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'])
        {'weekday': weekday, 'opens_at': '10:00', 'closes_at': '18:00'},
      {'weekday': 'saturday', 'opens_at': '10:00', 'closes_at': '14:00'},
      {'weekday': 'sunday', 'opens_at': null, 'closes_at': null},
    ],
    'blocked': blocked,
    'booked': booked,
  };
}

void main() {
  const agenda = demoAgenda;

  group('AppointmentAgenda.fromCalendar', () {
    test('lays out the month of today', () {
      final agenda = AppointmentAgenda.fromCalendar(calendar());

      expect(agenda.monthName, 'Noviembre 2026');
      expect(agenda.monthLongName, 'noviembre');
      expect(agenda.daysInMonth, 30);
      expect(agenda.weekdayOf(1), 7);
      expect(agenda.today, 22);
    });

    test('offers slots from opening up to, but not including, closing', () {
      final agenda = AppointmentAgenda.fromCalendar(calendar());

      expect(agenda.freeSlotsFor(23).first, '10:00');
      expect(agenda.freeSlotsFor(23).last, '17:30');
      expect(agenda.freeSlotsFor(23), hasLength(16));
      expect(agenda.freeSlotsFor(28), ['10:00', '10:30', '11:00', '11:30', '12:00', '12:30', '13:00', '13:30']);
    });

    test('has no free slots on a closed weekday or a blocked day', () {
      final agenda = AppointmentAgenda.fromCalendar(calendar());

      expect(agenda.freeSlotsFor(29), isEmpty);
      expect(agenda.freeSlotsFor(25), isEmpty);
    });

    test('leaves booked slots out', () {
      final agenda = AppointmentAgenda.fromCalendar(calendar());

      expect(agenda.isFree(24, '12:00'), isFalse);
      expect(agenda.isFree(24, '12:30'), isTrue);
    });

    test('offers today only the slots that have not started', () {
      final agenda = AppointmentAgenda.fromCalendar(calendar(today: '2026-11-23', now: '16:30'));

      expect(agenda.freeSlotsFor(23), ['17:00', '17:30']);
    });
  });

  group('firstBookableDay', () {
    test('is the first free day after today', () {
      expect(AppointmentAgenda.fromCalendar(calendar()).firstBookableDay, 23);
      expect(agenda.firstBookableDay, 5);
    });

    test('is today when no later day of the month is free', () {
      final lastDay = AppointmentAgenda.fromCalendar(calendar(today: '2026-11-30', now: '09:00'));

      expect(lastDay.firstBookableDay, 30);
    });

    test('is null when the month has no free slot left', () {
      final closingTime = AppointmentAgenda.fromCalendar(calendar(today: '2026-11-30', now: '18:00'));

      expect(closingTime.firstBookableDay, isNull);
    });
  });

  test('knows the weekday of each day, Monday first', () {
    expect(agenda.weekdayOf(1), 7);
    expect(agenda.weekdayOf(2), 1);
    expect(agenda.weekdayOf(5), 4);
  });

  test('has no free slots on past, closed or blocked days', () {
    expect(agenda.freeSlotsFor(3), isEmpty);
    expect(agenda.freeSlotsFor(8), isEmpty);
    expect(agenda.freeSlotsFor(6), isEmpty);
  });

  test('offers only the rest of the afternoon today', () {
    expect(agenda.freeSlotsFor(4), ['15:30', '16:00', '16:30', '17:00', '17:30']);
  });

  test('leaves booked slots out of business hours', () {
    final slots = agenda.freeSlotsFor(5);
    expect(slots, hasLength(13));
    expect(slots, isNot(contains('12:00')));
    expect(slots.first, '10:00');
    expect(slots.last, '17:30');
  });

  test('words days short and long', () {
    expect(agenda.shortDayLabel(4), 'Hoy');
    expect(agenda.shortDayLabel(5), 'Jue 5');
    expect(agenda.longDayLabel(5), 'jueves 5 de noviembre');
    expect(agenda.longDayLabel(4), 'Hoy, miércoles 4 de noviembre');
  });

  test('runs the hour wheel from the first to the last free hour', () {
    expect(agenda.wheelHoursFor(4), ['15', '16', '17']);
    expect(agenda.wheelHoursFor(5), ['10', '11', '12', '13', '14', '15', '16', '17']);
  });

  test('rolls an unavailable time to the nearest free slot', () {
    expect(agenda.nearestSlot(5, '12:00'), '11:30');
    expect(agenda.nearestSlot(4, '11:00'), '15:30');
    expect(agenda.nearestSlot(5, '11:00'), '11:00');
  });
}
