import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment_agenda.dart';
import '../models/booking.dart';
import '../models/booking_form.dart';
import '../models/catalog.dart';
import '../models/order.dart';
import '../models/user_profile.dart';
import '../utils/app_constants.dart';
import '../utils/spanish_dates.dart';
import 'client_data.dart';

/// Reads the client's screens from the CALM Supabase project.
class SupabaseClientData implements ClientData {
  const SupabaseClientData(this._supabase);

  final SupabaseClient _supabase;

  /// Row level security only lets the active services through, with or without a session.
  @override
  Future<Catalog> catalog() async {
    final rows = await _supabase
        .from('services')
        .select('id, name, category, base_price_mxn')
        .eq('is_active', true)
        .order('id');
    return Catalog.fromRows(rows);
  }

  /// No filter by client here: row level security returns only the signed-in client's rows.
  @override
  Future<List<Order>> orders() async {
    final [orderRows, appointmentRows] = await Future.wait([
      _supabase.from('orders').select('ticket, work, status, final_price_mxn, delivery_date'),
      _supabase.from('appointments').select(
        'ticket, scheduled_date, scheduled_time, preliminary_total_mxn, '
        'appointment_services(services(name)), orders(id)',
      ),
    ]);
    return Order.listFrom(orderRows: orderRows, appointmentRows: appointmentRows, now: cancunNow());
  }

  /// Row level security lets a client read only her own row of `clients`.
  @override
  Future<UserProfile> profile() async {
    final row = await _supabase.from('clients').select('name, phone').single();
    return UserProfile.fromRow(row);
  }

  /// A function rather than the tables: it answers with Cancún's "today" and "now", and with
  /// booked slots that carry no client.
  @override
  Future<AppointmentAgenda> agenda() async {
    final calendar = await _supabase.rpc<Map<String, dynamic>>('booking_calendar');
    return AppointmentAgenda.fromCalendar(calendar);
  }

  /// The `client-book` function decides the slot, the total and the ticket, and answers with a
  /// refresh token so the client is signed in as the owner of her new appointment.
  @override
  Future<BookingOutcome> book(BookingRequest request) async {
    try {
      final response = await _supabase.functions.invoke(
        'client-book',
        body: {
          'name': request.name,
          'phone': request.phoneDigits,
          'nip': request.nip,
          'service_ids': [for (final service in request.selection.services) int.parse(service.id)],
          'urgent': request.selection.isUrgent,
          'date': request.date,
          'time': request.time,
        },
      );
      final body = response.data as Map<String, dynamic>;
      await _supabase.auth.setSession(body['refresh_token'] as String);
      return BookingConfirmed(body['ticket'] as String);
    } on FunctionException catch (failure) {
      return _bookingRefusalFor(failure.status, failure.details);
    } catch (_) {
      // No network or a malformed answer: nothing is known about the booking.
      return const BookingRefused(AppConstants.signInUnavailable);
    }
  }

  static BookingOutcome _bookingRefusalFor(int status, dynamic details) {
    final code = details is Map ? details['code'] : null;
    return switch ((status, code)) {
      (401, _) => const BookingRefused(AppConstants.bookingWrongPair, field: BookingField.nip),
      (429, _) => const BookingRefused(AppConstants.signInThrottled),
      (409, 'slot_taken') => const BookingSlotTaken(),
      (409, 'phone_without_nip') =>
        const BookingRefused(AppConstants.bookingPhoneWithoutNip, field: BookingField.phone),
      (409, 'service_unavailable') => const BookingRefused(AppConstants.bookingServiceUnavailable),
      _ => const BookingRefused(AppConstants.signInUnavailable),
    };
  }
}
