import 'package:flutter/foundation.dart';

@immutable
class Settings {
  final String id;
  final String userId;
  final int serviceReminderDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Settings({
    required this.id,
    required this.userId,
    required this.serviceReminderDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Settings.fromMap(Map<String, dynamic> m) {
    return Settings(
      id: (m['id'] ?? '').toString(),
      userId: (m['user_id'] ?? '').toString(),
      serviceReminderDays: m['service_reminder_days'] as int? ?? 14,
      createdAt: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(m['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'service_reminder_days': serviceReminderDays,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toUpdateMap() => {
    'service_reminder_days': serviceReminderDays,
    'updated_at': DateTime.now().toIso8601String(),
  };

  Settings copyWith({
    String? id,
    String? userId,
    int? serviceReminderDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Settings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceReminderDays: serviceReminderDays ?? this.serviceReminderDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
