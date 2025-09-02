import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';

import '../Screen/MakeAppointment.dart';
import '../Screen/Progress.dart';
import '../Screen/ServiceFeedback.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  // --- Sample data sets ---
  final List<Appointment> upcoming = [
    Appointment(processId: 'PRC-2001', carName: 'Honda Civic', subtitle: '24 Aug, 2:30 PM'),
    Appointment(processId: 'PRC-2002', carName: 'Toyota Vios', subtitle: '25 Aug, 10:00 AM'),
    Appointment(processId: 'PRC-2003', carName: 'Perodua Myvi', subtitle: '26 Aug, 4:15 PM'),
  ];

  final List<Appointment> completed = [
    Appointment(processId: 'PRC-1890', carName: 'Proton X70', subtitle: '20 Aug, 5:00 PM'),
    Appointment(processId: 'PRC-1889', carName: 'Honda City', subtitle: '19 Aug, 11:20 AM'),
  ];

  final List<Appointment> cancelled = [
    Appointment(processId: 'PRC-1777', carName: 'Mazda 3', subtitle: '18 Aug, 3:45 PM'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Appointments",style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),),
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
        body: Container(
          margin: EdgeInsets.only(top: 17),
          child: TabBarView(
            children: [
              _AppointmentsList(stateLabel: "Upcoming", items: upcoming),
              _AppointmentsList(stateLabel: "Completed", items: completed),
              _AppointmentsList(stateLabel: "Cancelled", items: cancelled),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(), // 👈 force circular explicitly
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

// Simple model
class Appointment {
  final String processId;
  final String carName;
  final String subtitle; // date/time text
  Appointment({
    required this.processId,
    required this.carName,
    required this.subtitle,
  });
}

class _AppointmentsList extends StatelessWidget {
  final String stateLabel;
  final List<Appointment> items;
  const _AppointmentsList({required this.stateLabel, required this.items});

  Color _statusColor(String label) {
    switch (label.toLowerCase()) {
      case 'upcoming':
        return const Color(0xFFF59E0B); // amber
      case 'completed':
        return const Color(0xFF10B981); // green
      case 'cancelled':
        return const Color(0xFFEF4444); // red
      default:
        return const Color(0xFF9CA3AF); // grey fallback
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
      padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 15),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final appt = items[i];
        return Stack(
          clipBehavior: Clip.none, // 👈 allow overflow
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
                title: Text("${appt.carName} • ${appt.processId}"),
                subtitle: Text(appt.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Progress(
                        processId: appt.processId,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 👇 Positioned Feedback button overlay
            stateLabel!="Completed"? SizedBox.shrink(): Positioned(
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
            ),
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
