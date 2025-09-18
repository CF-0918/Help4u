import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Components/Timeline_tile.dart'; // your MyStepTile
import '../Models/Case.dart'; // CaseModel + CaseStatus
import '../Repository/case_repo.dart';
import '../Screen/ServiceFeedback.dart'; // CasesRepo

class CaseHistory extends StatefulWidget {
  const CaseHistory({super.key});

  @override
  State<CaseHistory> createState() => _CaseHistoryState();
}

class _CaseHistoryState extends State<CaseHistory> {
  final _casesRepo = CasesRepo();

  bool _loading = true;
  List<CaseModel> _cases = [];

  // ========= Timeline config =========
  static const List<CaseStatus> _ordered = [
    CaseStatus.checkIn,
    CaseStatus.inspection,
    CaseStatus.prepareSparePart,
    CaseStatus.repair,
    CaseStatus.qc,
    CaseStatus.payment,
    CaseStatus.done,
  ];

  static const Map<CaseStatus, String> _labels = {
    CaseStatus.checkIn: 'Checked In',
    CaseStatus.inspection: 'Inspection',
    CaseStatus.prepareSparePart: 'Prepare Spare Parts',
    CaseStatus.repair: 'Repair',
    CaseStatus.qc: 'Quality Check',
    CaseStatus.payment: 'Payment',
    CaseStatus.done: 'Done',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final allCases = await _casesRepo.getCompletedCasesForUser(userId);

      if (!mounted) return;
      setState(() => _cases = allCases);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load case history: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openMap(CaseModel c) async {
    final appt = c.appointment;
    if (appt == null) return;
    final outlet = appt.outlet;
    final hasCoords = outlet.latitude != null && outlet.longitude != null;
    final q = Uri.encodeComponent(outlet.outletName);
    final uri = hasCoords
        ? Uri.parse('geo:${outlet.latitude},${outlet.longitude}?q=$q')
        : Uri.parse('geo:0,0?q=$q');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9333EA);
    const purpleDark = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0.5,
        title: const Row(
          children: [
            Icon(Icons.history, size: 22, color: Colors.white),
            SizedBox(width: 8),
            Text('Case History',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
          ? const Center(
        child: Text('No completed case yet.',
            style: TextStyle(color: Colors.white70)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _cases.length,
        itemBuilder: (context, i) =>
            _buildCaseCard(_cases[i], purple, purpleDark),
      ),
    );
  }

  Widget _buildCaseCard(CaseModel c, Color purple, Color purpleDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white70,

          // ==== HEADER ====
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    c.appointment?.serviceType.name ?? '-',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _statusPill(c.caseStatus),
                ],
              ),
              const SizedBox(height: 10),

              // Car Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${c.appointment?.vehicle.brand ?? '-'} - "
                              "${c.appointment?.vehicle.model ?? '-'} - "
                              "${c.appointment?.vehicle.spec ?? '-'}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.appointment?.vehiclePlateNo ?? '-',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (c.appointment?.vehicle.vehImage != null &&
                        c.appointment!.vehicle.vehImage!.isNotEmpty)
                        ? Image.network(
                      c.appointment!.vehicle.vehImage!,
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      "assets/images/profile.jpg", // fallback if null/empty
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 12),

              // Workshop Name
              Row(
                children: [
                  const _MetaLabel(
                    icon: Icons.store_mall_directory_outlined,
                    text: "Workshop",
                  ),
                  const SizedBox(width: 8),
                  _MetaValue(text: c.appointment?.outlet.outletName ?? '-'),
                ],
              ),
              const SizedBox(height: 8),

              // Appointment Date
              Row(
                children: [
                  const _MetaLabel(
                    icon: Icons.date_range,
                    text: "Appointment Date",
                  ),
                  const SizedBox(width: 8),
                  _MetaValue(
                    text:
                    "${c.appointment?.bookingDate != null ? c.appointment!.bookingDate.toLocal().toString().split(' ')[0] : '-'}"
                        "  ${c.appointment?.bookingTime ?? '-'}",
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Feedback Button
              Align(
                alignment: Alignment.centerRight,
                child: FutureBuilder(
                  future: Supabase.instance.client
                      .from('service_feedback')
                      .select()
                      .eq('caseid', c.caseId)
                      .eq('booking_id', c.appointment?.id ?? '')
                      .eq('userid',
                      Supabase.instance.client.auth.currentUser!.id)
                      .maybeSingle(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final hasReview =
                        snapshot.hasData && snapshot.data != null;

                    return ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceFeedback(
                              caseId: c.caseId,
                              bookingId: c.appointment?.id ?? '',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.feedback,
                          color: Colors.white, size: 18),
                      label: Text(
                        hasReview ? "Edit Feedback" : "Leave Feedback",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),

          // ==== EXPANDED CONTENT ====
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Column(children: _buildTimelineTiles(c.caseStatus)),
                  const SizedBox(height: 16),

                  // Repair Details
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Repair Details",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: "Mileage",
                          value: "${c.appointment?.mileage ?? 0} KM",
                        ),

                        // Payment (Fetch from Supabase)
                        FutureBuilder(
                          future: Supabase.instance.client
                              .from('payments')
                              .select('amount')
                              .eq('case_id', c.caseId)
                              .maybeSingle(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const _DetailRow(
                                  label: "Total Amount", value: "Loading...");
                            }

                            if (snapshot.hasError) {
                              return const _DetailRow(
                                  label: "Total Amount", value: "Error");
                            }

                            final data = snapshot.data as Map<String, dynamic>?;
                            final total = data?['amount'] != null
                                ? "RM ${data!['amount']}"
                                : '-';

                            return _DetailRow(
                                label: "Total Amount", value: total);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Workshop Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Workshop Info",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            TextButton.icon(
                              onPressed: () => _openMap(c),
                              icon: const Icon(Icons.location_on,
                                  size: 16, color: Color(0xFF9333EA)),
                              label: const Text(
                                "View Map",
                                style: TextStyle(
                                  color: Color(0xFF9333EA),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2937),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.build_outlined,
                                  size: 22, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      c.appointment?.outlet.outletName ??
                                          '-',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                      c.appointment?.outlet.outletAddress ??
                                          '-',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ========= helpers =========
  static String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  Widget _statusPill(CaseStatus status) {
    final color = switch (status) {
      CaseStatus.done => const Color(0xFF10B981),
      CaseStatus.payment => const Color(0xFF60A5FA),
      CaseStatus.qc => const Color(0xFFF59E0B),
      CaseStatus.repair => const Color(0xFF9333EA),
      CaseStatus.prepareSparePart => const Color(0xFFA78BFA),
      CaseStatus.inspection => const Color(0xFF34D399),
      CaseStatus.checkIn => const Color(0xFF6EE7B7),
    };
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(24)),
      child: Text(
        _labels[status]!,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  List<Widget> _buildTimelineTiles(CaseStatus current) {
    final currentIndex = _ordered.indexOf(current);
    final lastIndex = _ordered.length - 1;

    return _ordered.asMap().entries.map((entry) {
      final i = entry.key;
      final status = entry.value;

      final isPast = i < currentIndex;
      final isFirst = i == 0;
      final isLast = i == lastIndex;

      final String subtitle = i == currentIndex
          ? 'In progress'
          : (isPast ? 'Completed' : 'Pending');

      return MyStepTile(
        isFirst: isFirst,
        isCurrent: i == currentIndex,
        isLast: isLast,
        isPast: isPast,
        title: _labels[status]!,
        subtitle: subtitle,
      );
    }).toList();
  }
}

// ===== Helper Widgets =====
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _MetaValue extends StatelessWidget {
  final String text;
  const _MetaValue({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700),
    );
  }
}
