import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking_months.dart';
import '../models/booking.dart';
import '../models/booking_form.dart';
import '../models/catalog.dart';
import '../models/client_action.dart';
import '../models/order.dart';
import '../models/profile_form.dart';
import '../models/profile_update.dart';
import '../models/user_profile.dart';
import '../utils/app_constants.dart';
import '../utils/spanish_dates.dart';
import 'client_data.dart';

/// Reads the client's screens from the CALM Supabase project.
class SupabaseClientData implements ClientData {
  const SupabaseClientData(this._supabase);

  final SupabaseClient _supabase;

  @override
  bool get isSignedIn => _supabase.auth.currentSession != null;

  /// Row level security only lets the active services through, with or without a session.
  @override
  Future<Catalog> catalog() async {
    final rows = await _supabase
        .from('services')
        .select('id, name, category, base_price_mxn')
        .eq('is_active', true)
        // Ascending: supabase-dart's order() is descending unless told otherwise.
        .order('id', ascending: true);
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
  Future<BookingMonths> agenda() async {
    final calendar = await _supabase.rpc<Map<String, dynamic>>('booking_calendar');
    return BookingMonths.fromCalendar(calendar);
  }

  /// The `client-book` function decides the slot, the total and the ticket. Without a session it
  /// answers with a refresh token so the client is signed in as the owner of her new appointment;
  /// with one, her session already names her and she keeps it.
  @override
  Future<BookingOutcome> book(BookingRequest request) async {
    final contact = request.contact;
    try {
      final response = await _supabase.functions.invoke(
        'client-book',
        body: {
          if (contact != null) ...{
            'name': contact.name,
            'phone': contact.phoneDigits,
            'nip': contact.nip,
          },
          'service_ids': [for (final service in request.selection.services) int.parse(service.id)],
          'urgent': request.selection.isUrgent,
          'date': request.date,
          'time': request.time,
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (contact != null) await _supabase.auth.setSession(body['refresh_token'] as String);
      return BookingConfirmed(body['ticket'] as String);
    } on FunctionException catch (failure) {
      return _bookingRefusalFor(failure.status, failure.details);
    } catch (_) {
      // No network or a malformed answer: nothing is known about the booking.
      return const BookingRefused(AppConstants.signInUnavailable);
    }
  }

  @override
  Future<ClientActionOutcome> cancelAppointment(String ticket) {
    return _act('cancel_my_appointment', ticket, refusal: AppConstants.cancelRefused);
  }

  @override
  Future<ClientActionOutcome> markOnMyWay(String ticket) {
    return _act('mark_on_my_way', ticket, refusal: AppConstants.onTheWayRefused);
  }

  /// The workshop's functions raise P0001 when the rule refuses, so a refusal is never mistaken
  /// for a success and is told apart from a failure to reach it.
  Future<ClientActionOutcome> _act(String function, String ticket, {required String refusal}) async {
    try {
      await _supabase.rpc<void>(function, params: {'p_ticket': ticket});
      return const ActionDone();
    } on PostgrestException catch (failure) {
      return ActionRefused(failure.code == 'P0001' ? refusal : AppConstants.signInUnavailable);
    } catch (_) {
      return const ActionRefused(AppConstants.signInUnavailable);
    }
  }

  /// `client-update-profile` checks the current NIP; the session says who she is.
  @override
  Future<ProfileUpdateOutcome> saveProfile(ProfileChange change) async {
    try {
      final response = await _supabase.functions.invoke(
        'client-update-profile',
        body: {'phone': change.phoneDigits, 'current_nip': change.currentNip, 'new_nip': change.newNip},
      );
      final client = (response.data as Map<String, dynamic>)['client'] as Map<String, dynamic>;
      return ProfileSaved(UserProfile.fromRow(client));
    } on FunctionException catch (failure) {
      return _profileRefusalFor(failure.status, failure.details);
    } catch (_) {
      return const ProfileRefused(AppConstants.signInUnavailable);
    }
  }

  /// The refusals carry the wording of Perfil's own form; the code says which field it is about.
  static ProfileUpdateOutcome _profileRefusalFor(int status, dynamic details) {
    final body = details is Map ? details : const {};
    final message = body['error'] as String? ?? AppConstants.signInUnavailable;
    return switch ((status, body['code'])) {
      (429, _) => const ProfileRefused(AppConstants.signInThrottled),
      (_, 'phone' || 'phone_taken') => ProfileRefused(message, field: ProfileField.phone),
      (_, 'current_nip') => ProfileRefused(message, field: ProfileField.currentNip),
      (_, 'new_nip') => ProfileRefused(message, field: ProfileField.newNip),
      (_, 'signed_out') => ProfileRefused(message),
      _ => const ProfileRefused(AppConstants.signInUnavailable),
    };
  }

  /// Even when the server cannot be reached, the session on this device is gone.
  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // signOut clears the local session before it calls the server.
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
