import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Models/Appointment.dart';
import '../Screen/Billing.dart';
import '../Screen/MakeAppointment.dart';
import '../Screen/Progress.dart';

class HomeTab extends StatelessWidget {

  // We now accept all data and callbacks as parameters.
  final Function(int) onTabSelected;
  final bool isLoading;
  final int completedPercentage;
  final double rating;
  final double ratingChange;
  final List<Appointment> appointments;
  final List<Appointment> completedAppointments;

  const HomeTab({
    super.key,
    required this.onTabSelected,
    required this.isLoading,
    required this.completedPercentage,
    required this.rating,
    required this.ratingChange,
    required this.appointments,
    required this.completedAppointments,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;
    final Color completedDeltaColor = completedPercentage > 0 ? Colors.green : Colors.white;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Billing()));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade900, width: 2),
              ),
              child: const Row(
                children: [
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
                    deltaText: "$completedPercentage %",
                    value: "${completedAppointments.length}",
                    subtitle: "Completed Appointments",
                    deltaColor: completedDeltaColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    background: cardBg,
                    leading: const Icon(Icons.star, color: Colors.amber, size: 30),
                    deltaText: "${ratingChange.toStringAsFixed(1)} %",
                    value: "${rating.toStringAsFixed(1)}",
                    subtitle: "Average Rating",
                    deltaColor: Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
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
                        label: const Text('Make Appointments'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
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
                          onTabSelected(1);
                        },
                        icon: const Icon(Icons.history, size: 25),
                        label: const Text('View History'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
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
                Text(
                  "Upcoming Appointments (${appointments.length})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    onTabSelected(0);
                  },
                  child: const Text(
                    "View All",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appointments.length,
            itemBuilder: (context, i) {
              final a = appointments[i];
              return UpComingAppointmentsCard(
                appointment: a,
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
  final Color deltaColor;

  const StatCard({
    super.key,
    required this.background,
    required this.leading,
    required this.deltaText,
    required this.value,
    required this.subtitle,
    required this.deltaColor,
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
                style: TextStyle(
                  letterSpacing: 1.1,
                  color: deltaColor,
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

class UpComingAppointmentsCard extends StatelessWidget {
  final Appointment appointment;

  const UpComingAppointmentsCard({
    super.key,
    required this.appointment,
  });

  Color _statusColor(String label) {
    switch (label.toLowerCase()) {
      case 'upcoming':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(appointment.bookingDate.year, appointment.bookingDate.month, appointment.bookingDate.day);
    final difference = bookingDay.difference(today).inDays;
    final dotColor = _statusColor(appointment.bookingStatus);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Progress(
              bookingId: appointment.id,
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
                  child: Text(
                    difference == 0 ? "Today" : '$difference days',
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
}

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
