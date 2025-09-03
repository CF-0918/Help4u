import 'package:supabase_flutter/supabase_flutter.dart';

import '../Models/Vehicle.dart';
import '../authencation/auth_service.dart';

class VehicleRepository {
  // Singleton pattern
  final SupabaseClient _client = Supabase.instance.client;
  AuthService _authService = AuthService();


  // Example method to fetch vehicles
  Future<List<Vehicle>> fetchUserCars() async {
    // Get the current user ID
    final String? currentUserId = _client.auth.currentUser?.id;

    // Handle the case where there is no logged-in user
    if (currentUserId == null) {
      print("User not authenticated.");
      return [];
    }

    print("Fetching vehicles for user ID: $currentUserId");
    // Corrected Supabase query
    try {
      final response = await _client
          .from('vehicle') // Corrected table name
          .select("*")
          .eq("userid", currentUserId); // Corrected column name

      // Map the fetched data to a list of Vehicle objects
      final List<Vehicle> vehicles = (response as List).map((item) {
        return Vehicle.fromJson(item);
      }).toList();

      print("Fetched ${vehicles.length} vehicles.");

      return vehicles;
    } catch (e) {
      print("Error fetching vehicles: $e");
      return [];
    }
  }

}