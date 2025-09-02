import 'package:flutter/material.dart';
import 'package:workshop_assignment/TabScreen/AppointmentsTab.dart';
import 'package:workshop_assignment/TabScreen/ProfileTab.dart';

import '../Screen/Billing.dart';
import '../Screen/MakeAppointment.dart';

class HomeTab extends StatelessWidget {
  // Sample data (replace with your real source)
  final List<Appointment> appointments = [
    Appointment(
      location: 'Petronas Service Center, KLCC',
      carDetails: 'Toyota Vios • WXY1234',
      date: DateTime(2025, 8, 25), // runtime value (OK now)
      time: '2:30 PM',
    ),
    Appointment(
      location: 'Bukit Jalil Workshop',
      carDetails: 'Honda City • VBG9988',
      date: DateTime(2025, 8, 22),
      time: '11:00 AM',
    ),
  ];


  HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor; // or const Color(0xFF1C1C1E)

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [

          GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Billing()));
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade700, // deeper red
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade900, width: 2),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "3 Outstanding Payment! Please clear it",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(Icons.ads_click, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatCard(
                    background: cardBg,
                    leading: const Icon(
                      Icons.calendar_month_sharp,
                      color: Colors.purple,
                      size: 30,
                    ),
                    deltaText: "+12%",
                    value: "24",
                    subtitle: "Completed Appointments",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    background: cardBg,
                    leading: const Icon(Icons.star, color: Colors.amber, size: 30),
                    deltaText: "+5%",
                    value: "4.8",
                    subtitle: "Average Rating",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick Actions
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            alignment: Alignment.centerLeft,
            child: const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF9333EA),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MakeAppointment()),
                          );
                        },
                        icon: const Icon(Icons.book_online, size: 25),
                        label: const Text('Make Appoinments'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white, // text & icon color
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1F2937),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AppointmentsTab()),
                          );
                        },
                        icon: const Icon(Icons.history, size: 25),
                        label: const Text('View History'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white, // text & icon color
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Upcoming Appointments
          Container(
            margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Upcoming Appointments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "View All",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // List inside scroll view → make it non-scrollable + shrinkWrap
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appointments.length,
            itemBuilder: (context, i) {
              final a = appointments[i];
              return UpComingAppointmentsCard(
                location: a.location,
                carDetails: a.carDetails,
                date: a.date,
                time: a.time,
              );
            },
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final Color background;
  final Widget leading;
  final String deltaText;
  final String value;
  final String subtitle;

  const StatCard({
    super.key,
    required this.background,
    required this.leading,
    required this.deltaText,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leading,
              const Spacer(),
              Text(
                deltaText,
                style: const TextStyle(
                  letterSpacing: 1.1,
                  color: Color(0xFF35D07F),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: onBg,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: onBg.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple model to keep things typed
class Appointment {
  final String location;
  final String carDetails;
  final DateTime date;
  final String time;
  const Appointment({
    required this.location,
    required this.carDetails,
    required this.date,
    required this.time,
  });
}

class UpComingAppointmentsCard extends StatelessWidget {
  final String location;
  final String carDetails;
  final DateTime date; // appointment date
  final String time;   // e.g., "2:30 PM"

  const UpComingAppointmentsCard({
    super.key,
    required this.location,
    required this.carDetails,
    required this.date,
    required this.time,
  });

  String _friendlyWhen(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final onlyDate = DateTime(target.year, target.month, target.day);
    final diffDays = onlyDate.difference(today).inDays;

    if (diffDays < 0) return 'Past';
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    return 'In $diffDays days';
  }

  @override
  Widget build(BuildContext context) {
    final when = _friendlyWhen(date);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.event_available, size: 28, color: Colors.green),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // When label (Today/Tomorrow/In X days)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      when,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.place, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Car details
                  Row(
                    children: [
                      const Icon(Icons.directions_car, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          carDetails,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Date & time
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        '${date.day.toString().padLeft(2, '0')}-'
                            '${date.month.toString().padLeft(2, '0')}-'
                            '${date.year}  •  $time',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
