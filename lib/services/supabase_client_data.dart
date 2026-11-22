import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment_agenda.dart';
import '../models/catalog.dart';
import '../models/order.dart';
import '../models/user_profile.dart';
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
}
