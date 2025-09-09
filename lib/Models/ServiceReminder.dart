// lib/models/serviceReminder.dart
import 'package:flutter/foundation.dart';

enum ServiceReminderStatus { active, done, snoozed, cancelled }

ServiceReminderStatus _statusFromString(String? v) {
  switch ((v ?? '').toLowerCase()) {
    case 'done':
      return ServiceReminderStatus.done;
    case 'snoozed':
      return ServiceReminderStatus.snoozed;
    case 'cancelled':
      return ServiceReminderStatus.cancelled;
    case 'active':
    default:
      return ServiceReminderStatus.active;
  }
}

String _statusToString(ServiceReminderStatus s) {
  switch (s) {
    case ServiceReminderStatus.done:
      return 'done';
    case ServiceReminderStatus.snoozed:
      return 'snoozed';
    case ServiceReminderStatus.cancelled:
      return 'cancelled';
    case ServiceReminderStatus.active:
    default:
      return 'active';
  }
}

DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

/// DB needs ISO **date-only** strings for `date` columns.
String _dateOnlyIso(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

@immutable
class ServiceReminder {
  final String id;                 // uuid (pk)
  final String userId;             // fk -> user_profiles.id
  final String vehiclePlate;       // text
  final String serviceTypeId;      // uuid
  final DateTime nextDueDate;      // date (date-only)
  final DateTime? lastCompletedAt; // date (date-only)
  final ServiceReminderStatus status;
  final String? notes;
  final DateTime createdAt;        // timestamptz
  final DateTime updatedAt;        // timestamptz

  const ServiceReminder({
    required this.id,
    required this.userId,
    required this.vehiclePlate,
    required this.serviceTypeId,
    required this.nextDueDate,
    this.lastCompletedAt,
    this.status = ServiceReminderStatus.active,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceReminder.fromMap(Map<String, dynamic> m) {
    return ServiceReminder(
      id: (m['id'] ?? '').toString(),
      userId: (m['user_id'] ?? '').toString(),
      vehiclePlate: (m['vehicle_plate'] ?? '').toString(),
      serviceTypeId: (m['service_type_id'] ?? '').toString(),
      nextDueDate: _parseDateTime(m['next_due_date']) ?? DateTime.now(),
      lastCompletedAt: _parseDateTime(m['last_completed_at']),
      status: _statusFromString(m['status'] as String?),
      notes: m['notes'] as String?,
      createdAt: _parseDateTime(m['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(m['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'vehicle_plate': vehiclePlate,
    'service_type_id': serviceTypeId,
    'next_due_date': _dateOnlyIso(nextDueDate),      // date-only
    'last_completed_at': lastCompletedAt == null ? null : _dateOnlyIso(lastCompletedAt!),
    'status': _statusToString(status),
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Use when inserting a NEW row.
  Map<String, dynamic> toInsertMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'vehicle_plate': vehiclePlate,
      'service_type_id': serviceTypeId,
      'next_due_date': _dateOnlyIso(nextDueDate),                 // date-only
      'last_completed_at': lastCompletedAt == null ? null : _dateOnlyIso(lastCompletedAt!),
      'status': _statusToString(status),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (includeId) map['id'] = id;
    return map;
  }

  /// Use when updating an existing row.
  Map<String, dynamic> toUpdateMap() => {
    'user_id': userId,
    'vehicle_plate': vehiclePlate,
    'service_type_id': serviceTypeId,
    'next_due_date': _dateOnlyIso(nextDueDate),                 // date-only
    'last_completed_at': lastCompletedAt == null ? null : _dateOnlyIso(lastCompletedAt!),
    'status': _statusToString(status),
    'notes': notes,
    'updated_at': DateTime.now().toIso8601String(),
  };

  ServiceReminder copyWith({
    String? id,
    String? userId,
    String? vehiclePlate,
    String? serviceTypeId,
    DateTime? nextDueDate,
    DateTime? lastCompletedAt,
    ServiceReminderStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
