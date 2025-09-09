import 'package:flutter/foundation.dart';

@immutable
class UserDevice {
  final String id;
  final String userId;
  final String token;       // <- matches table column name
  final String platform;    // "android" | "ios" | "web"
  final DateTime updatedAt;

  const UserDevice({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    required this.updatedAt,
  });

  factory UserDevice.fromMap(Map<String, dynamic> m) {
    return UserDevice(
      id: (m['id'] ?? '').toString(),
      userId: (m['user_id'] ?? '').toString(),
      token: (m['token'] ?? '').toString(),               // <- token
      platform: (m['platform'] ?? '').toString(),
      updatedAt: DateTime.tryParse('${m['updated_at'] ?? ''}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'token': token,                                      // <- token
    'platform': platform,
    'updated_at': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toInsertMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'token': token,                                    // <- token
      'platform': platform,
      'updated_at': updatedAt.toIso8601String(),
    };
    if (includeId) map['id'] = id;
    return map;
  }

  UserDevice copyWith({
    String? id,
    String? userId,
    String? token,
    String? platform,
    DateTime? updatedAt,
  }) {
    return UserDevice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      platform: platform ?? this.platform,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
