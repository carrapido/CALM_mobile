import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../models/booking_form.dart';
import '../models/booking_months.dart';
import '../models/catalog.dart';
import '../models/client_action.dart';
import '../models/order.dart';
import '../models/profile_form.dart';
import '../models/profile_update.dart';
import '../models/user_profile.dart';
import '../utils/app_constants.dart';
import '../utils/spanish_dates.dart';
import 'api_client.dart';
import 'client_data.dart';

/// Reads and changes the client's screens through the CALM API (`/api/client/*`).
///
/// The API decides what she reaches from her access token; Supabase Auth only keeps her session
/// on this device: whether one is open, installing a new one after booking, and signing out.
class ApiClientData implements ClientData {
  ApiClientData(ApiClient api, SupabaseClient supabase)
      : this.using(
          api: api,
          isSignedIn: () => supabase.auth.currentSession != null,
          installSession: (refreshToken) => supabase.auth.setSession(refreshToken),
          signOut: () => supabase.auth.signOut(),
        );

  /// The same rules over any API and session store; tests use it with stand-ins.
  const ApiClientData.using({
    required this.api,
    required this._isSignedIn,
    required this.installSession,
    required this._signOut,
    this._now = cancunNow,
  });

  final ApiClient api;
  final SessionInstaller installSession;
  final bool Function() _isSignedIn;
  final Future<void> Function() _signOut;

  /// Cancún's wall clock, which decides what is past and what is less than 24 hours ahead.
  final DateTime Function() _now;

  @override
  bool get isSignedIn => _isSignedIn();

  /// Only the active services, by id, with or without a session.
  @override
  Future<Catalog> catalog() async {
    return Catalog.fromApi(await _read('/client/services') as List<Object?>);
  }

  /// Only her own orders and appointments: the API reads who she is from her token.
  @override
  Future<List<Order>> orders() async {
    final body = await _read('/client/orders') as Map<String, dynamic>;
    return Order.listFromApi(body, now: _now());
  }

  @override
  Future<UserProfile> profile() async {
    return UserProfile.fromRow(await _read('/client/profile') as Map<String, dynamic>);
  }

  /// Cancún's "today" and "now", and booked slots that carry no client.
  @override
  Future<BookingMonths> agenda() async {
    return BookingMonths.fromApi(await _read('/client/booking-calendar') as Map<String, dynamic>);
  }

  /// A 401 `signed_out` (her token was refused, or her session could not be refreshed) is her
  /// session ending, never a failure to load; any other failure stays as it is.
  Future<Object?> _read(String path) async {
    try {
      return await api.get(path);
    } on ApiException catch (failure) {
      if (_endsSession(failure)) throw const SessionEnded();
      rethrow;
    }
  }

  static bool _endsSession(ApiException failure) => failure.status == 401 && failure.code == 'signed_out';

  /// The API decides the slot, the total and the ticket. Without a session it answers with a
  /// refresh token so the client is signed in as the owner of her new appointment; with one, her
  /// session already names her and she keeps it.
  @override
  Future<BookingOutcome> book(BookingRequest request) async {
    final contact = request.contact;
    try {
      final answer = await api.post('/client/appointments', {
        'serviceIds': [for (final service in request.selection.services) int.parse(service.id)],
        'urgent': request.selection.isUrgent,
        'date': request.date,
        'time': request.time,
        if (contact != null)
          'contact': {'name': contact.name, 'phone': contact.phoneDigits, 'nip': contact.nip},
      });
      final body = answer as Map<String, dynamic>;
      final ticket = body['ticket'] as String;
      final refreshToken = body['refreshToken'];
      if (refreshToken is String && refreshToken.isNotEmpty) await installSession(refreshToken);
      return BookingConfirmed(ticket);
    } on ApiException catch (failure) {
      return _bookingRefusalFor(failure);
    } catch (_) {
      // No network, no answer in time, a malformed answer or a session that could not be
      // installed: nothing is known about the booking.
      return const BookingRefused(AppConstants.signInUnavailable);
    }
  }

  @override
  Future<ClientActionOutcome> cancelAppointment(String ticket) {
    return _act(
      () => api.delete('/client/appointments/${Uri.encodeComponent(ticket)}'),
      refusal: AppConstants.cancelRefused,
    );
  }

  @override
  Future<ClientActionOutcome> markOnMyWay(String ticket) {
    return _act(
      () => api.post('/client/orders/${Uri.encodeComponent(ticket)}/on-my-way'),
      refusal: AppConstants.onTheWayRefused,
    );
  }

  /// The API answers 409 when the rule refuses (`appointment_not_cancellable`, `order_not_ready`),
  /// so a refusal is never mistaken for a success and is told apart from a failure to reach it.
  /// A 401 `signed_out` means her session ended.
  Future<ClientActionOutcome> _act(Future<Object?> Function() send, {required String refusal}) async {
    try {
      await send();
      return const ActionDone();
    } on ApiException catch (failure) {
      if (_endsSession(failure)) return const ActionSignedOut();
      return ActionRefused(failure.status == 409 ? refusal : AppConstants.signInUnavailable);
    } catch (_) {
      return const ActionRefused(AppConstants.signInUnavailable);
    }
  }

  /// The API checks the current NIP; her token says who she is. The NIPs travel only when she
  /// changes hers.
  @override
  Future<ProfileUpdateOutcome> saveProfile(ProfileChange change) async {
    try {
      final answer = await api.put('/client/profile', {
        'phone': change.phoneDigits,
        if (change.currentNip.isNotEmpty) 'currentNip': change.currentNip,
        if (change.newNip.isNotEmpty) 'newNip': change.newNip,
      });
      final client = (answer as Map<String, dynamic>)['client'] as Map<String, dynamic>;
      return ProfileSaved(UserProfile.fromRow(client));
    } on ApiException catch (failure) {
      return _profileRefusalFor(failure);
    } catch (_) {
      return const ProfileRefused(AppConstants.signInUnavailable);
    }
  }

  /// Even when the server cannot be reached, the session on this device is gone.
  @override
  Future<void> signOut() async {
    try {
      await _signOut();
    } catch (_) {
      // signOut clears the local session before it calls the server.
    }
  }

  static BookingOutcome _bookingRefusalFor(ApiException failure) {
    return switch ((failure.status, failure.code)) {
      (401, 'signed_out') => const BookingSignedOut(),
      (401, _) => const BookingRefused(AppConstants.bookingWrongPair, field: BookingField.nip),
      (429, _) => const BookingRefused(AppConstants.signInThrottled),
      (409, 'slot_taken') => const BookingSlotTaken(),
      (409, 'phone_without_nip') =>
        const BookingRefused(AppConstants.bookingPhoneWithoutNip, field: BookingField.phone),
      (409, 'service_unavailable') => const BookingRefused(AppConstants.bookingServiceUnavailable),
      _ => const BookingRefused(AppConstants.signInUnavailable),
    };
  }

  /// The refusals carry the wording of Perfil's own form; the code says which field it is about.
  static ProfileUpdateOutcome _profileRefusalFor(ApiException failure) {
    // The code alone decides here, as it did before the session-ended outcome existed.
    if (failure.code == 'signed_out') return const ProfileSignedOut();
    final worded = failure.message;
    final message = worded == null || worded.isEmpty ? AppConstants.signInUnavailable : worded;
    return switch ((failure.status, failure.code)) {
      (429, _) => const ProfileRefused(AppConstants.signInThrottled),
      (_, 'phone' || 'phone_taken') => ProfileRefused(message, field: ProfileField.phone),
      (_, 'current_nip') => ProfileRefused(message, field: ProfileField.currentNip),
      (_, 'new_nip') => ProfileRefused(message, field: ProfileField.newNip),
      _ => const ProfileRefused(AppConstants.signInUnavailable),
    };
  }
}
