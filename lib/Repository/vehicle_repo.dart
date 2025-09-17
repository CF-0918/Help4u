import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/Vehicle.dart';
import '../authencation/auth_service.dart';

class VehicleRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();

  /// Fetch all vehicles for the current user
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
          .eq("userid", currentUserId);

      return (response as List)
          .map((item) => Vehicle.fromJson(item))
          .toList();
    } catch (e) {
      print("Error fetching vehicles: $e");
      return [];
    }
  }

  /// Insert a new vehicle
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

  /// Update a vehicle (match by plateno)
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

  /// Delete a vehicle (match by plateno)
  /// Delete a vehicle (only if not used in bookings)
  /// Delete a vehicle (only if not used in bookings)
  Future<void> delete(String plateNo) async {
    try {
      // Step 1: Check if this vehicle is referenced in bookings
      final bookings = await _client
          .from('bookings')
          .select('vehicleplateno') // correct column name
          .eq('vehicleplateno', plateNo);

      if (bookings != null && (bookings as List).isNotEmpty) {
        throw Exception(
          "This vehicle cannot be deleted because it has existing bookings.",
        );
      }

      // Step 2: Proceed to delete if no bookings
      await _client.from('vehicle').delete().eq('plateno', plateNo);
    } catch (e) {
      throw Exception("Error deleting vehicle: $e");
    }
  }
}
