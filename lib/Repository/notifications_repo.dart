// notification_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/Notifications.dart';


class NotificationRepository {
  static const String table = 'notifications';
  final SupabaseClient _client = Supabase.instance.client;

  /// Latest notifications for the current user (RLS should restrict to auth.uid()).
  Future<List<NotificationItem>> fetchLatest({int limit = 20}) async {
    final rows = await _client
        .from(table)
        .select()
        .order('sent_at', ascending: false)
        .limit(limit);

    if (rows is List) {
      return rows
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Unread count (simple; for very large sets, consider an RPC).
  Future<int> fetchUnreadCount(String userId) async {
    final res = await _client
        .from(table)
        .select('id')
        .eq('user_has_read', false)
      .eq('user_id', userId);

    if (res is List) return res.length;
    return 0;
  }

  Future<List<NotificationItem>>getchUnreadNotifications(String userId) async {
    final rows = await _client
        .from(table)
        .select()
        .eq('user_has_read', false)
        .eq('user_id', userId)
        .order('sent_at', ascending: false);

    if (rows is List) {
      return rows
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
  /// Mark one notification as read (trigger fills read_at).
  Future<void> markAsRead(String notificationId) async {
    await _client.from(table).update({'user_has_read': true}).eq('id', notificationId);
  }

  /// Mark all as read for current user.
  Future<void> markAllAsRead() async {
    await _client.from(table).update({'user_has_read': true}).eq('user_has_read', false);
  }

  /// Insert (DB generates id/created_at by default; we still set sent_at for clarity).
  Future<NotificationItem> insert({
    required String userId,
    String? serviceReminderId,                // nullable
    required String title,
    required String body,
    Map<String, dynamic> data = const {},     // defaults to {}
    DateTime? sentAt,                         // default now()
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'service_reminder_id': serviceReminderId, // can be null
      'title': title,
      'body': body,
      'data': data.isEmpty ? <String, dynamic>{} : data,
      'user_has_read': false,
      'sent_at': (sentAt ?? DateTime.now().toUtc()).toIso8601String(),
      // created_at -> DB default
    };

    final row = await _client.from(table).insert(payload).select().single();
    return NotificationItem.fromJson(row as Map<String, dynamic>);
  }

  /// Upsert by primary key (set includeId=true if you supply id).
  Future<NotificationItem> upsert(NotificationItem item, {bool provideId = true}) async {
    final payload = item.toMap(includeId: provideId);
    final row = await _client.from(table).upsert(payload).select().single();
    return NotificationItem.fromJson(row as Map<String, dynamic>);
  }

  /// Patch certain fields (title/body/data/user_has_read).
  Future<NotificationItem> updateFields(
      String id, {
        String? title,
        String? body,
        Map<String, dynamic>? data,
        bool? userHasRead,
      }) async {
    final patch = <String, dynamic>{
      if (title != null) 'title': title,
      if (body  != null) 'body' : body,
      if (data  != null) 'data' : (data.isEmpty ? <String, dynamic>{} : data),
      if (userHasRead != null) 'user_has_read': userHasRead,
    };
    final row = await _client.from(table).update(patch).eq('id', id).select().single();
    return NotificationItem.fromJson(row as Map<String, dynamic>);
  }

  /// Delete by id.
  Future<void> deleteById(String notificationId) async {
    await _client.from(table).delete().eq('id', notificationId);
  }

  /// Delete ALL mine (RLS confines to current user).
  Future<void> deleteAllMine() async {
    await _client.from(table).delete().neq('id', '');
  }

  /// Optional helper: fetch by a specific service reminder.
  Future<List<NotificationItem>> fetchByServiceReminder(String reminderId) async {
    final rows = await _client
        .from(table)
        .select()
        .eq('service_reminder_id', reminderId)
        .order('sent_at', ascending: false);

    if (rows is List) {
      return rows
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
