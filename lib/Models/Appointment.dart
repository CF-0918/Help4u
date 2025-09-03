import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:workshop_assignment/Models/Outlet.dart';
import 'package:workshop_assignment/Models/ServiceType.dart';
import 'package:workshop_assignment/Models/UserProfile.dart';
import 'package:workshop_assignment/Models/Vehicle.dart';

const uuid = Uuid();

// A data model representing a single appointment with full details.
class Appointment {
  // Unique identifier for the appointment.
  final String id;

  // The user who made the booking.
  final UserProfile user;
  // The workshop outlet.
  final Outlet outlet;
  final Vehicle vehicle;
  // The service type.
  final ServiceType serviceType;

  // The license plate number of the vehicle.
  final String vehiclePlateNo;
  // Car mileage at the time of booking.
  final int mileage;
  // Current status of the appointment (e.g., 'Pending', 'Confirmed').
  final String bookingStatus;
  // Date of the appointment.
  final DateTime bookingDate;
  // Time of the appointment.
  final String bookingTime;
  // Timestamp when the appointment was created.
  final DateTime createdAt;

  Appointment( {
    required this.id,
    required this.vehicle,
    required this.user,
    required this.outlet,
    required this.serviceType,
    required this.vehiclePlateNo,
    required this.mileage,
    required this.bookingStatus,
    required this.bookingDate,
    required this.bookingTime,
    required this.createdAt,
  });

  // Factory constructor to create an Appointment object from a JSON map (e.g., from Supabase).
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['booking_id'] as String,
      // Nested data from the joined tables. Supabase returns lowercase keys.
      user: UserProfile.fromMap(json['user_profiles']),
      outlet: Outlet.fromMap(json['outlets']),
      vehicle: Vehicle.fromJson(json['vehicle']) ,
      serviceType: ServiceType.fromJson(json['service_type']),
      // The `vehicle_plate_no` field is represented by `vehiclePlateNo` in your Dart model.
      vehiclePlateNo: json['vehicleplateno'] as String,
      mileage: json['mileage'] as int,
      bookingStatus: json['bookingstatus'] as String,
      bookingDate: DateTime.parse(json['bookingdate'] as String),
      bookingTime: json['bookingtime'] as String,
      createdAt: DateTime.parse(json['createdat'] as String),
    );
  }

  // Method to convert an Appointment object to a JSON map for database operations.
  Map<String, dynamic> toJson() {
    return {
      'booking_id': id,
      // We pass the foreign key IDs for insertion, not the full objects.
      'userid': Supabase.instance.client.auth.currentUser!.id,
      'outletid': outlet.outletID,
      'vehicleplateno': vehiclePlateNo,
      'servicetypeid': serviceType.id,
      'mileage': mileage,
      'bookingstatus': bookingStatus,
      'bookingdate': bookingDate.toIso8601String().split('T').first,
      'bookingtime': bookingTime,
    };
  }
}
