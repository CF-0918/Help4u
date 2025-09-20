import 'package:supabase_flutter/supabase_flutter.dart';

class Vehicle {
  final String plateNo;
  final String? regNo;
  final String model;
  final String brand;
  final String? spec;
  final int? manYear;
  final String? type;
  final String? vehImage;
  final String userID;
  final String status; // ✅ new field

  Vehicle({
    required this.plateNo,
    this.regNo,
    required this.model,
    required this.brand,
    this.spec,
    this.manYear,
    this.type,
    this.vehImage,
    required this.userID,
    this.status = "Active", // ✅ default value
  });

  /// Convert to map for database insertion
  Map<String, dynamic> toInsertMap() {
    return {
      'plateno': plateNo,
      'regno': regNo,
      'model': model,
      'brand': brand,
      'spec': spec,
      'manyear': manYear,
      'type': type,
      'vehimage': vehImage,
      'userid': userID,
      'status': status,
    };
  }

  /// Convert to map for database update
  Map<String, dynamic> toUpdateMap() {
    return {
      'regno': regNo,
      'model': model,
      'brand': brand,
      'spec': spec,
      'manyear': manYear,
      'type': type,
      'vehimage': vehImage,
      'status': status,
    };
  }

  /// Create Vehicle object from JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      plateNo: json['plateno'] as String,
      regNo: json['regno'] as String?,
      model: json['model'] as String,
      brand: json['brand'] as String,
      spec: json['spec'] as String?,
      manYear: json['manyear'] as int?,
      type: json['type'] as String?,
      vehImage: json['vehimage'] as String?,
      userID: json['userid'] as String,
      status: json['status'] as String? ?? "Active",
    );
  }

  /// ✅ copyWith for easier modification
  Vehicle copyWith({
    String? plateNo,
    String? regNo,
    String? model,
    String? brand,
    String? spec,
    int? manYear,
    String? type,
    String? vehImage,
    String? userID,
    String? status,
  }) {
    return Vehicle(
      plateNo: plateNo ?? this.plateNo,
      regNo: regNo ?? this.regNo,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      spec: spec ?? this.spec,
      manYear: manYear ?? this.manYear,
      type: type ?? this.type,
      vehImage: vehImage ?? this.vehImage,
      userID: userID ?? this.userID,
      status: status ?? this.status,
    );
  }
}
