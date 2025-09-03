import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:workshop_assignment/Repository/appointment_repo.dart';

import '../Models/Appointment.dart';
import '../Screen/MakeAppointment.dart';
import '../Screen/Progress.dart';
import '../Screen/ServiceFeedback.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  // Use three separate lists for each tab's data
  List<Appointment> upcoming = [];
  List<Appointment> completed = [];
  List<Appointment> cancelled = [];

  bool isLoading = true; // State to manage loading

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  // A dedicated method to fetch and categorize appointments
  Future<void> _fetchAppointments() async {
    try {
      final List<Appointment> allAppointments = await AppointmentRepository().fetchUserAppointments();
      setState(() {
        // Filter appointments into their respective lists
        upcoming = allAppointments.where((appt) => appt.bookingStatus == 'Confirmed').toList();
        completed = allAppointments.where((appt) => appt.bookingStatus == 'Completed').toList();
        cancelled = allAppointments.where((appt) => appt.bookingStatus == 'Cancelled').toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to fetch appointments: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Appointments",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: ButtonsTabBar(
            backgroundColor: const Color(0xFF9333EA),
            unselectedBackgroundColor: const Color(0xFF1F2937),
            splashColor: Colors.purpleAccent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            labelSpacing: 8,
            radius: 24,
            labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(color: Colors.white70),
            tabs: const [
              Tab(icon: Icon(Icons.event_available), text: "Upcoming"),
              Tab(icon: Icon(Icons.done_all), text: "Completed"),
              Tab(icon: Icon(Icons.cancel_outlined), text: "Cancelled"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            // Pass the correct list to each TabBarView child
            _AppointmentsList(stateLabel: "Upcoming", items: upcoming),
            _AppointmentsList(stateLabel: "Completed", items: completed),
            _AppointmentsList(stateLabel: "Cancelled", items: cancelled),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MakeAppointment()));
          },
          backgroundColor: const Color(0xFF9333EA),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _AppointmentsList extends StatelessWidget {
  final String stateLabel;
  final List<Appointment> items;
  const _AppointmentsList({required this.stateLabel, required this.items});

  Color _statusColor(String label) {
    switch (label.toLowerCase()) {
      case 'upcoming':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _statusColor(stateLabel);

    if (items.isEmpty) {
      return const Center(
        child: Text(
          "No appointments",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final appt = items[i];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 👇 Card as the base
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusDot(color: dotColor),
                    const SizedBox(width: 8),
                    const Icon(Icons.car_repair, color: Color(0xFF9333EA)),
                  ],
                ),
                title: Text("${appt.outlet.outletName} • ${appt.bookingDate.toLocal().toString().split(' ')[0]}"),
                // Fixed string concatenation here
                subtitle: Text("${appt.vehicle.brand} - ${appt.vehicle.model} • ${appt.bookingTime}"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Progress(
                        processId: appt.id,
                      ),
                    ),
                  );
                },
              ),
            ),
            // 👇 Positioned Feedback button overlay
            // Corrected conditional logic to show the button for "Completed" appointments
            stateLabel == "Completed"
                ? Positioned(
              top: -11,
              right: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  backgroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ServiceFeedback()),
                  );
                },
                child: const Text(
                  "Feedback",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            )
                : const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}

// tiny colored dot
class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
