
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/serviceReminder.dart'
    show ServiceReminder, ServiceReminderStatus;

class ServiceReminderRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static const _table = 'service_reminders';

  // ---------- READ ----------
  Future<List<ServiceReminder>> fetchForCurrentUser(String userId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
    // optional "safety" filter: only allowed statuses
        .inFilter('status', ['active', 'done', 'snoozed', 'cancelled'])
        .order('next_due_date', ascending: true);

    if (data is! List) return [];
    return data
        .map((e) => ServiceReminder.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ---------- CREATE (model-based) ----------
  Future<ServiceReminder> create(
      ServiceReminder r, {
        bool includeId = true,
      }) async {
    final payload = r.toInsertMap(includeId: includeId);
    final row = await _client.from(_table).insert(payload).select().single();
    return ServiceReminder.fromMap(row as Map<String, dynamic>);
  }

  // ---------- UPDATE ----------
  Future<ServiceReminder> update(ServiceReminder r) async {
    final row = await _client
        .from(_table)
        .update(r.toUpdateMap())
        .eq('id', r.id)
        .select()
        .single();
    return ServiceReminder.fromMap(row as Map<String, dynamic>);
  }

  // ---------- DELETE ----------
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  // ---------- Convenience helpers ----------
  Future<ServiceReminder> markDone(String id) async {
    final now = DateTime.now();
    final row = await _client
        .from(_table)
        .update({
      'status': 'done',
      'last_completed_at':
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'updated_at': now.toIso8601String(),
    })
        .eq('id', id)
        .select()
        .single();
    return ServiceReminder.fromMap(row as Map<String, dynamic>);
  }

  Future<ServiceReminder> snoozeTo(String id, DateTime newDate) async {
    final row = await _client
        .from(_table)
        .update({
      'status': 'snoozed',
      'next_due_date':
      '${newDate.year.toString().padLeft(4, '0')}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}',
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', id)
        .select()
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
        .select()
        .single();
    return ServiceReminder.fromMap(row as Map<String, dynamic>);
  }
}
