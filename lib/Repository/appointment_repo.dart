import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Models/Appointment.dart';
import 'package:workshop_assignment/Models/Outlet.dart';
import 'package:workshop_assignment/Models/ServiceType.dart';
import 'package:workshop_assignment/Models/UserProfile.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

class AppointmentRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Fetches a list of appointments for the currently logged-in user.
  Future<List<Appointment>> fetchUserAppointments() async {
    try {
      final String? userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User is not logged in.');
      }

      // Use a nested select to get all the related data. Supabase table names are lowercase.
      final response = await _client
          .from('bookings')
          .select('*, user_profiles(*), outlets(*), service_type(*),vehicle(*)')
          .eq('userid', userId)
          .order('bookingdate', ascending: true)
          .order('bookingtime', ascending: true);

      // Supabase returns a List<Map<String, dynamic>>
      if (response is List) {
        return response.map((item) => Appointment.fromJson(item)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print("Error fetching user appointments: $e");
      return [];
    }
  }

  // Fetches all existing bookings for a specific date and outlet.
  Future<List<Map<String, dynamic>>> fetchBookingsForDateAndOutlet({
    required String outletID,
    required DateTime bookingDate,
  }) async {
    try {
      final response = await _client
          .from('bookings')
          .select('booking_id, bookingtime')
          .eq('outletid', outletID)
          .eq('bookingdate', bookingDate.toIso8601String().split('T').first);

      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching availability: $e");
      return [];
    }
  }




  // Creates a new appointment in the database.
  Future<void> createAppointment({
    required String outletID,
    required String vehiclePlateNo,
    required String serviceTypeID,
    required int mileage,
    required DateTime bookingDate,
    required String bookingTime,
  }) async {
    try {
      final String? userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User is not logged in.');
      }

      final Map<String, dynamic> newAppointmentData = {
        'booking_id': uuid.v4(),
        'userid': userId,
        'outletid': outletID,
        'vehicleplateno': vehiclePlateNo,
        'servicetypeid': serviceTypeID,
        'mileage': mileage,
        'bookingstatus': 'Confirmed', // Default status
        'bookingdate': bookingDate.toIso8601String().split('T').first,
        'bookingtime': bookingTime,
      };

      await _client.from('bookings').insert(newAppointmentData);
      print("Appointment created successfully!");
    } catch (e) {
      print("Error creating appointment: $e");
      rethrow;
    }
  }
}
