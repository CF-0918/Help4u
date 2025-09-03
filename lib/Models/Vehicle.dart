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
  });

  // Method to convert the Vehicle object to a map for database insertion.
  // All keys are in lowercase to match Supabase's default behavior.
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
    };
  }

  // Method to convert the Vehicle object to a map for database updates.
  Map<String, dynamic> toUpdateMap() => toInsertMap();

  // Factory constructor to create a Vehicle object from a JSON map.
  // The keys used here are now all lowercase.
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
    );
  }
}
