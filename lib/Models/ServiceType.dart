import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceType {
  final String id;
  final String name;
  final String? description;
  final double? price;
  final int interval_months; // New field for interval in months

  ServiceType({
    required this.id,
    required this.name,
    this.description,
    this.price,
    required this.interval_months,
  });

  /// Factory constructor to create a ServiceType instance from a JSON map.
  /// This is typically used when fetching data from Supabase.
  factory ServiceType.fromJson(Map<String, dynamic> json) {
    return ServiceType(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      // Supabase's 'numeric' type is often returned as a double or an int.
      // We safely cast it to a double.
      price: (json['price'] as num?)?.toDouble(),
      interval_months: json['interval_months'] as int,
    );
  }

  /// Converts the ServiceType object to a JSON map.
  /// This is used when inserting or updating data in Supabase.
  Map<String, dynamic> toInsert() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'interval_months': interval_months,
    };
  }
}
