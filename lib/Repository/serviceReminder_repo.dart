// lib/Repository/serviceReminder_repo.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/ServiceReminder.dart';

class ServiceReminderRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static const _table = 'service_reminders';

  // Columns used across all selects (keeps things consistent)
  static const _selectCols = '''
    id,user_id,vehicle_plate,service_type_id,
    next_due_date,last_completed_at,status,notes,created_at,updated_at,
    last_notified_at,
    service_type:service_type_id (*),
    vehicle:vehicle_plate (*)
  ''';

  /// READ with embedded relations
  Future<List<ServiceReminder>> fetchForCurrentUser(String userId) async {
    final data = await _client
        .from(_table)
        .select(_selectCols)
        .eq('user_id', userId)
    // SQL IN filter syntax as string (Supabase style)
        .filter('status', 'in', '("active","done","snoozed","cancelled")')
        .order('next_due_date', ascending: true);

    if (data is! List) return [];
    return data
        .map((e) => ServiceReminder.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// CREATE (includeId=true lets you provide your own UUID from UI)
  Future<ServiceReminder> create(
      ServiceReminder r, {
        bool includeId = false,
      }) async {
    final row = await _client
        .from(_table)
        .insert(r.toInsertMap(includeId: includeId))
        .select(_selectCols)
        .single();

    return ServiceReminder.fromMap(row as Map<String, dynamic>);
  }

  /// UPDATE full row
  Future<ServiceReminder> update(ServiceReminder r) async {
    final row = await _client
        .from(_table)
        .update(r.toUpdateMap())
        .eq('id', r.id)
        .select(_selectCols)
        .single();

    return ServiceReminder.fromMap(row as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  // ---------- Convenience helpers (return updated row) ----------

  Future<ServiceReminder> markDone(String id) async {
    final now = DateTime.now();
    final row = await _client
        .from(_table)
        .update({
      'status': 'done',
      'last_completed_at': now.toIso8601String().split('T').first, // DATE
      'updated_at': now.toIso8601String(),
    })
        .eq('id', id)
        .select(_selectCols)
        .single();

    return ServiceReminder.fromMap(row as Map<String, dynamic>);
  }

  Future<ServiceReminder> snoozeTo(String id, DateTime newDate) async {
    final now = DateTime.now();
    final row = await _client
        .from(_table)
        .update({
      'status': 'snoozed',
      'next_due_date':
      DateTime(newDate.year, newDate.month, newDate.day) // DATE only
          .toIso8601String()
          .split('T')
          .first,
      'updated_at': now.toIso8601String(),
    })
        .eq('id', id)
        .select(_selectCols)
        .single();

    return ServiceReminder.fromMap(row as Map<String, dynamic>);
  }

  Future<ServiceReminder> cancel(String id) async {
    final row = await _client
        .from(_table)
        .update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', id)
        .select(_selectCols)
        .single();

    return ServiceReminder.fromMap(row as Map<String, dynamic>);
  }

  /// Mark that we just notified (use this from your Edge Function after send)
  Future<ServiceReminder> touchLastNotified(String id) async {
    final row = await _client
        .from(_table)
        .update({
      'last_notified_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', id)
        .select(_selectCols)
        .single();

    return ServiceReminder.fromMap(row as Map<String, dynamic>);
  }

  /// (Optional) Query reminders due within X days and not recently notified
  Future<List<ServiceReminder>> dueWithinDaysForUser(
      String userId, {
        required int days,
      }) async {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day)
        .add(Duration(days: days))
        .toIso8601String()
        .split('T')
        .first;

    final data = await _client
        .from(_table)
        .select(_selectCols)
        .eq('user_id', userId)
        .eq('status', 'active')
        .lte('next_due_date', end)
        .order('next_due_date', ascending: true);

    if (data is! List) return [];
    return data
        .map((e) => ServiceReminder.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
