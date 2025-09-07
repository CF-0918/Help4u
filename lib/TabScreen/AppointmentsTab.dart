import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workshop_assignment/Repository/appointment_repo.dart';
import 'package:workshop_assignment/Screen/AppointmentDetails.dart';

import '../Models/Appointment.dart';
import '../Screen/MakeAppointment.dart';
import '../Screen/Progress.dart';
import '../Screen/ServiceFeedback.dart';

class AppointmentsTab extends StatefulWidget  {
  final int initialIndex;

  const AppointmentsTab({super.key, this.initialIndex = 0});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> with TickerProviderStateMixin {
  // Use three separate lists for each tab's data
  List<Appointment> upcoming = [];
  List<Appointment> completed = [];
  List<Appointment> cancelled = [];

  bool isLoading = true; // State to manage loading

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex, // Use the initialIndex here
    );
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return Scaffold(
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
          controller: _tabController,
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
        controller: _tabController,
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
          // Push the new screen and wait for it to pop
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MakeAppointment())).then((_) {
            // Once the screen is popped, refresh the appointments data
            _fetchAppointments();
          });
        },
        backgroundColor: const Color(0xFF9333EA),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AppointmentsList extends StatelessWidget {
  final String stateLabel;
  final List<Appointment> items;
  const _AppointmentsList({required this.stateLabel, required this.items});

  @override
  Widget build(BuildContext context) {
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
        return _AppointmentCard(
          appointment: appt,
          stateLabel: stateLabel,
        );
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final String stateLabel;
  const _AppointmentCard({required this.appointment, required this.stateLabel});

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(appointment.bookingDate.year, appointment.bookingDate.month, appointment.bookingDate.day);
    final difference = bookingDay.difference(today).inDays;

    String timeLabel;
    if (difference > 0) {
      timeLabel = '$difference days';
    } else if (difference == 0) {
      timeLabel = 'Today';
    } else {
      timeLabel = '${-difference} days ago';
    }

    final dotColor = _statusColor(stateLabel);
    final isCompleted = stateLabel == 'Completed';

    return GestureDetector(
      onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentDetails(
                appointmentID: appointment.id,
              ),
            ),
          );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _StatusDot(color: dotColor),
                    const SizedBox(width: 8),
                    Text(
                      appointment.outlet.outletName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:Text(
                    timeLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

              ],
            ),
            const SizedBox(height: 12),

            // Car and Service Info
            _buildInfoRow(
              icon: Icons.directions_car_filled,
              label: '${appointment.vehicle.brand} ${appointment.vehicle.model}',
              value: appointment.vehicle.plateNo,
            ),
            _buildInfoRow(
              icon: Icons.build,
              label: 'Service Type',
              value: appointment.serviceType.name,
            ),
            _buildInfoRow(
              icon: Icons.speed,
              label: 'Mileage',
              value: '${appointment.mileage} KM',
            ),
            const SizedBox(height: 12),

            // Date and Time Info
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd().format(appointment.bookingDate),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  appointment.bookingTime,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
