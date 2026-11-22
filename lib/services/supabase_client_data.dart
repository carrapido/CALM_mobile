import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog.dart';
import '../models/order.dart';
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
}
