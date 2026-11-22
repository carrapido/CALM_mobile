import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog.dart';
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
}
