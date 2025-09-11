// notification_model.dart
import 'dart:convert';

class NotificationItem {
  final String id;                   // uuid
  final String userId;               // uuid
  final String? serviceReminderId;   // uuid (nullable per schema)

  final String title;                // NOT NULL
  final String body;                 // NOT NULL
  final Map<String, dynamic> data;   // jsonb default {}

  final bool userHasRead;            // NOT NULL default false
  final DateTime? readAt;            // nullable (set by trigger when read)
  final DateTime sentAt;             // NOT NULL default now()
  final DateTime createdAt;          // NOT NULL default now()

  NotificationItem({
    required this.id,
    required this.userId,
    required this.serviceReminderId,
    required this.title,
    required this.body,
    required this.data,
    required this.userHasRead,
    required this.readAt,
    required this.sentAt,
    required this.createdAt,
  });

  // --- helpers ---
  static DateTime? _toDt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toUtc();
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toUtc();
    return null;
  }

  static Map<String, dynamic> _toMap(dynamic v) {
    if (v == null) return <String, dynamic>{};
    if (v is Map<String, dynamic>) return v;
    if (v is String && v.isNotEmpty) {
      try { return json.decode(v) as Map<String, dynamic>; } catch (_) {}
    }
    return <String, dynamic>{};
  }

  factory NotificationItem.fromJson(Map<String, dynamic> j) {
    return NotificationItem(
      id:                j['id'] as String,
      userId:            j['user_id'] as String,
      serviceReminderId: j['service_reminder_id'] as String?,
      title:             (j['title'] ?? '') as String,
      body:              (j['body']  ?? '') as String,
      data:              _toMap(j['data']),
      userHasRead:       (j['user_has_read'] ?? false) as bool,
      readAt:            _toDt(j['read_at']),
      sentAt:            _toDt(j['sent_at']) ?? DateTime.now().toUtc(),
      createdAt:         _toDt(j['created_at']) ?? DateTime.now().toUtc(),
    );
  }

  /// Map for insert/upsert. Omit server-managed defaults if null.
  Map<String, dynamic> toMap({bool includeId = false}) {
    final m = <String, dynamic>{
      'user_id': userId,
      'service_reminder_id': serviceReminderId, // can be null
      'title': title,
      'body': body,
      'data': data, // Supabase handles jsonb
      'user_has_read': userHasRead,
      'read_at': readAt?.toIso8601String(),
      'sent_at': sentAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
    if (!m.containsKey('data') || (m['data'] as Map).isEmpty) {
      m['data'] = <String, dynamic>{};
    }
    if (includeId) m['id'] = id;
    return m;
  }

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? serviceReminderId,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? userHasRead,
    DateTime? readAt,
    DateTime? sentAt,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceReminderId: serviceReminderId ?? this.serviceReminderId,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      userHasRead: userHasRead ?? this.userHasRead,
      readAt: readAt ?? this.readAt,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
