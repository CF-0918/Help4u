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

  // Future<String>getLastestAppointmentId(){
  //       Map<String, dynamic> lastestAppointmentId = _client
  //       .from('bookings')
  //       .select('booking_id')
  //       .order('created_at', ascending: false)
  //       .limit(1)
  //       .single()
  //       .then((value) => value as Map<String,dynamic>);
  //
  //       lastestAppointmentId['booking_id'];
  //       Extartc "Appt-001"
  //
  //       if no appointment return Appt-001
  //
  // }

  Future<List<Appointment>> fetchUpcomingAppointments() async {
    try {
      final String? userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User is not logged in.');
      }

      final response = await _client
          .from('bookings')
          .select('*, user_profiles(*), outlets(*), service_type(*),vehicle(*)')
          .eq('userid', userId)
          .eq("bookingstatus", "Confirmed")
      // Use gte for 'greater than or equal to' today's date
          .gte('bookingdate', DateTime.now().toIso8601String().split('T').first)
          .order('bookingdate', ascending: true)
          .order('bookingtime', ascending: true);

      if (response is List) {
        return response.map((item) => Appointment.fromJson(item)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print("Error fetching upcoming appointments: $e");
      return [];
    }
  }

  /// Fetches a list of completed appointments for the currently logged-in user.
  Future<List<Appointment>> fetchCompletedAppointments() async {
    try {
      final String? userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User is not logged in.');
      }

      final response = await _client
          .from('bookings')
          .select('*, user_profiles(*), outlets(*), service_type(*),vehicle(*)')
          .eq('userid', userId)
          .eq("bookingstatus", "Completed")
          .order('bookingdate', ascending: false); // Order by date descending for completed

      if (response is List) {
        return response.map((item) => Appointment.fromJson(item)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print("Error fetching completed appointments: $e");
      return [];
    }
  }

  /// Fetches a list of cancelled appointments for the currently logged-in user.
  Future<List<Appointment>> fetchCancelledAppointments() async {
    try {
      final String? userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User is not logged in.');
      }

      final response = await _client
          .from('bookings')
          .select('*, user_profiles(*), outlets(*), service_type(*),vehicle(*)')
          .eq('userid', userId)
          .eq("bookingstatus", "Cancelled")
          .order('bookingdate', ascending: false);

      if (response is List) {
        return response.map((item) => Appointment.fromJson(item)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print("Error fetching cancelled appointments: $e");
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

  Future<void> cancelAppointment(String bookingId) async {
    try {
      await _client
          .from('bookings')
          .update({'bookingstatus': 'Cancelled'})
          .eq('booking_id', bookingId);
      print("Appointment cancelled successfully!");
    } catch (e) {
      print("Error cancelling appointment: $e");
      rethrow;
    }
  }

  Future<Appointment>fetchUserAppointmentsById(String bookingId)async{
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
          .eq('booking_id', bookingId)
          .maybeSingle();

      // Supabase returns a List<Map<String, dynamic>>
      if (response is Map<String,dynamic>) {
        return Appointment.fromJson(response);
      } else {
        print("Response is not a map: $response");
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print("Error fetching user appointments: $e");
      rethrow;
    }
  }

  Future<void>updateStatus(String bookingId, String status)async{
    try {
      await _client
          .from('bookings')
          .update({'bookingstatus': status})
          .eq('booking_id', bookingId);
      print("Appointment Repo status updated successfully!");
    } catch (e) {
      print("Error updating appointment status: $e");
      rethrow;
    }
  }

}
