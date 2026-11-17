import 'package:calm_mobil/models/appointment_agenda.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const agenda = AppointmentAgenda.november2026;

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
