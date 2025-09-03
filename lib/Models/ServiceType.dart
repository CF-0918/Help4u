import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceType {
  final String id;
  final String name;
  final String? description;
  final double? price;

  ServiceType({
    required this.id,
    required this.name,
    this.description,
    this.price,
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
    };
  }
}
