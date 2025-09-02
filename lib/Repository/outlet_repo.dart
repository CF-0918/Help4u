// outlet_repo.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/Outlet.dart';

class OutletRepo {
  final SupabaseClient _client = Supabase.instance.client;
  static const _table = 'outlets';

  Future<List<Outlet>> fetchOutlets({
    required String status, // always pass something, e.g. 'active'
    int limit = 50,
    int offset = 0,
  }) async {
    // Postgres lowercases unquoted identifiers; your column is `outletstatus`.
    var q = _client
        .from(_table)
    // ilike is case-insensitive; also trim your input to be safe
        .select()
        .ilike('outletstatus', status.trim())
        .order('created_at', ascending: false);

    if (offset > 0 || limit > 0) {
      q = q.range(offset, offset + limit - 1);
    }

    final data = await q as List<dynamic>;
    // Optional debug: print count so you can see if it fetched anything.
    // debugPrint('fetchOutlets($status) -> ${data.length} rows');
    return data.map((e) => Outlet.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Outlet?> fetchById(String outletID) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('outletid', outletID)
        .maybeSingle();
    return row == null ? null : Outlet.fromMap(row);
  }
}
