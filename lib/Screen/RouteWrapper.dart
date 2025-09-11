import 'package:flutter/material.dart';
import 'package:workshop_assignment/Screen/AppointmentDetails.dart';
import 'package:workshop_assignment/Screen/ServiceReminder.dart';

class AppointmentsRouteWrapper extends StatelessWidget {
  const AppointmentsRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;
    final bookingId = (args['booking_id'] ?? '') as String;

    if (bookingId.isEmpty) {
      // defensive: show message and go back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing booking_id for Appointments')),
        );
        Navigator.of(context).maybePop();
      });
    }

    return AppointmentDetails(
      appointmentID: bookingId,
    );
  }
}

class ServiceReminderRouteWrapper extends StatelessWidget {
  const ServiceReminderRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;
    // final reminderId = (args['reminder_id'] ?? '') as String;
    // final dueDate    = args['due_date'] as String?;

    return ServiceReminderPage();
  }
}
