import 'package:flutter/material.dart';

import '../Model/Appointment.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🚗 Vehicle: ${appointment.vehicle}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 6),
            Text("📅 Appointment Date: ${appointment.dateTime}",
                style: TextStyle(fontSize: 16)),
            Text("📍 Location: ${appointment.location}",
                style: TextStyle(fontSize: 16)),
            Text("🛠️ Type: ${appointment.type}", style: TextStyle(fontSize: 16)),
            if (appointment.type.toLowerCase() == 'service' && appointment.mileage != null)
              Text("📏 Mileage: ${appointment.mileage}", style: TextStyle(fontSize: 16)),
            if (appointment.type.toLowerCase() == 'repair' && appointment.comment != null)
              Text("💬 Comment: ${appointment.comment}", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}