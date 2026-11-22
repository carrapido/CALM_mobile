import 'booking_form.dart';
import 'service_selection.dart';

/// What the client confirms on "Agendar cita": her data, the repairs and the slot.
class BookingRequest {
  const BookingRequest({
    required this.name,
    required this.phoneDigits,
    required this.nip,
    required this.selection,
    required this.date,
    required this.time,
  });

  final String name;
  final String phoneDigits;
  final String nip;
  final ServiceSelection selection;

  /// "2026-11-05" and "11:00", on Cancún's wall clock.
  final String date;
  final String time;
}

/// How the workshop answered a booking. It decides everything: the slot, the total, the ticket,
/// and whether the phone and NIP open an account.
sealed class BookingOutcome {
  const BookingOutcome();
}

class BookingConfirmed extends BookingOutcome {
  const BookingConfirmed(this.ticket);

  final String ticket;
}

/// Someone took the slot between loading the agenda and confirming.
class BookingSlotTaken extends BookingOutcome {
  const BookingSlotTaken();
}

/// Refused for a reason the client can act on, worded for her; [field] turns red when it is hers.
class BookingRefused extends BookingOutcome {
  const BookingRefused(this.message, {this.field});

  final String message;
  final BookingField? field;
}
