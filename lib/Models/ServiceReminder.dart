// lib/models/serviceReminder.dart
import 'package:flutter/foundation.dart';
import 'package:workshop_assignment/Models/ServiceType.dart';
import 'package:workshop_assignment/Models/Vehicle.dart';

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
String _dateOnlyIso(DateTime d) =>
    DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

/// Safely read a nested map by any of the provided keys.
Map<String, dynamic>? _nestedMap(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is Map<String, dynamic>) return v;
  }
  return null;
}

@immutable
class ServiceReminder {
  final String id;
  final String userId;
  final String vehiclePlate;
  final String serviceTypeId;
  final DateTime nextDueDate;
  final DateTime? lastCompletedAt;
  final ServiceReminderStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// New field
  final DateTime? lastNotifiedAt;

  final ServiceType? serviceType;
  final Vehicle? vehicle;

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
    this.lastNotifiedAt, // new
    this.serviceType,
    this.vehicle,
  });

  factory ServiceReminder.fromMap(Map<String, dynamic> m) {
    final stMap = _nestedMap(m, ['service_type', 'service_types']);
    final vhMap = _nestedMap(m, ['vehicle', 'vehicles']);

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
      lastNotifiedAt: _parseDateTime(m['last_notified_at']), // new
      serviceType: stMap != null ? ServiceType.fromJson(stMap) : null,
      vehicle: vhMap != null ? Vehicle.fromJson(vhMap) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'vehicle_plate': vehiclePlate,
    'service_type_id': serviceTypeId,
    'next_due_date': _dateOnlyIso(nextDueDate),
    'last_completed_at':
    lastCompletedAt == null ? null : _dateOnlyIso(lastCompletedAt!),
    'status': _statusToString(status),
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'last_notified_at': lastNotifiedAt?.toIso8601String(), // new
  };

  Map<String, dynamic> toInsertMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'vehicle_plate': vehiclePlate,
      'service_type_id': serviceTypeId,
      'next_due_date': _dateOnlyIso(nextDueDate),
      'last_completed_at':
      lastCompletedAt == null ? null : _dateOnlyIso(lastCompletedAt!),
      'status': _statusToString(status),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_notified_at': lastNotifiedAt?.toIso8601String(), // new
    };
    if (includeId) map['id'] = id;
    return map;
  }

  Map<String, dynamic> toUpdateMap() => {
    'user_id': userId,
    'vehicle_plate': vehiclePlate,
    'service_type_id': serviceTypeId,
    'next_due_date': _dateOnlyIso(nextDueDate),
    'last_completed_at':
    lastCompletedAt == null ? null : _dateOnlyIso(lastCompletedAt!),
    'status': _statusToString(status),
    'notes': notes,
    'updated_at': DateTime.now().toIso8601String(),
    'last_notified_at': lastNotifiedAt?.toIso8601String(), // new
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
    DateTime? lastNotifiedAt, // new
    ServiceType? serviceType,
    Vehicle? vehicle,
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
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt, // new
      serviceType: serviceType ?? this.serviceType,
      vehicle: vehicle ?? this.vehicle,
    );
  }
}
