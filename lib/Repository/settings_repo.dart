import 'package:supabase_flutter/supabase_flutter.dart';

import '../Models/Settings.dart';

class SettingsRepository {
  final SupabaseClient _client = Supabase.instance.client;
  static const _table = 'settings';

  /// Create a settings row for a user
  /// (usually only called once; RLS ensures user_id = current user’s profile)
  Future<Settings> create({
    required String userId,
    int serviceReminderDays = 14, // default 14
  }) async {
    final now = DateTime.now().toIso8601String();

    final row = await _client
        .from(_table)
        .insert({
      'user_id': userId,
      'service_reminder_days': serviceReminderDays,
      'created_at': now,
      'updated_at': now,
    })
        .select()
        .single();

    return Settings.fromMap(row as Map<String, dynamic>);
  }

  /// Get the settings row for a given user_profiles.id
  Future<Settings?> getByUserId(String userId) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;
    return Settings.fromMap(row as Map<String, dynamic>);
  }

  /// Update the service_reminder_days for a given user_profiles.id
  Future<Settings> update({
    required String userId,
    required int serviceReminderDays,
  }) async {
    final row = await _client
        .from(_table)
        .update({
      'service_reminder_days': serviceReminderDays,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('user_id', userId)
        .select()
        .single();

    return Settings.fromMap(row as Map<String, dynamic>);
  }
}
