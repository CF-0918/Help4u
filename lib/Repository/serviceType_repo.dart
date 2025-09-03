import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Models/ServiceType.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

class ServiceTypeRepository {
  AuthService authService=AuthService();
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ServiceType>> fetchServiceTypes() async {
    try {
      final response = await _client
          .from('service_type')
          .select()
          .order('name', ascending: true);

      if (response is List) {
        return response.map((item) => ServiceType.fromJson(item)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print("Error fetching service types: $e");
      return [];
    }
  }
}