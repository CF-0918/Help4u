import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/Vehicle.dart';
import '../authencation/auth_service.dart';

class VehicleRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();

  /// Fetch all active vehicles for the current user
  Future<List<Vehicle>> fetchUserCars() async {
    final String? currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      print("User not authenticated.");
      return [];
    }

    try {
      final response = await _client
          .from('vehicle')
          .select("*")
          .eq("userid", currentUserId)
          .eq("status", "Active");

      return (response as List)
          .map((item) => Vehicle.fromJson(item))
          .toList();
    } catch (e) {
      print("Error fetching vehicles: $e");
      return [];
    }
  }

  /// Fetch vehicle by plate number (any status)
  Future<Vehicle?> fetchByPlateNo(String plateNo) async {
    try {
      final response = await _client
          .from('vehicle')
          .select()
          .eq('plateno', plateNo)
          .maybeSingle();

      return response != null ? Vehicle.fromJson(response) : null;
    } catch (e) {
      print("Error fetching vehicle by plateNo: $e");
      return null;
    }
  }

  /// Create a new vehicle entry
  Future<Vehicle> create(Vehicle v) async {
    try {
      final response = await _client
          .from('vehicle')
          .insert(v.toInsertMap())
          .select()
          .single();

      return Vehicle.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception("Error creating vehicle: $e");
    }
  }

  /// Update an existing vehicle (matched by plate number)
  Future<Vehicle> update(Vehicle v) async {
    try {
      final response = await _client
          .from('vehicle')
          .update(v.toUpdateMap())
          .eq('plateno', v.plateNo)
          .select()
          .single();

      return Vehicle.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception("Error updating vehicle: $e");
    }
  }

  /// Soft delete: set vehicle status to Inactive
  Future<void> deactivate(String plateNo) async {
    try {
      await _client
          .from('vehicle')
          .update({'status': 'Inactive'})
          .eq('plateno', plateNo);
    } catch (e) {
      throw Exception("Error deactivating vehicle: $e");
    }
  }

  /// Reactivate vehicle without overwriting its existing data
  Future<void> reactivate(String plateNo) async {
    try {
      await _client
          .from('vehicle')
          .update({'status': 'Active'})
          .eq('plateno', plateNo);
    } catch (e) {
      throw Exception("Error reactivating vehicle: $e");
    }
  }
}
