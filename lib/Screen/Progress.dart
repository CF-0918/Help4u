import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:workshop_assignment/Repository/serviceReminder_repo.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';
import 'package:uuid/uuid.dart';

import '../Components/Timeline_tile.dart';      // your MyStepTile
import '../Models/Case.dart';
import '../Repository/case_repo.dart';                    // CaseModel + CaseStatus

import '../Repository/serviceReminder_repo.dart';
import '../models/serviceReminder.dart';

class Progress extends StatefulWidget {
  final String bookingId;                        // pass the appointment's booking_id
  const Progress({super.key, required this.bookingId});

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress> {
  final _casesRepo = CasesRepo();

  bool isCaseCompleted = false;
  bool isPaymentNow = false;

  bool _loading = true;
  CaseModel? _case;

  AuthService authService=AuthService();

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
      final c = await _casesRepo.getOnGoingCaseByBookingId(widget.bookingId);
      isCaseCompleted = c != null && c.caseStatus == CaseStatus.done &&c.caseClosed;
      isPaymentNow = c != null && c.caseStatus == CaseStatus.payment;
      if (!mounted) return;
      setState(() => _case = c);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load progress: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openMap() async {
    final appt = _case?.appointment;
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

  Future<void> _updateCaseStatus(CaseStatus status) async {
    if (_case == null) return;

    try {
      await _casesRepo.updateCaseStatus(_case!.caseId, status);

      if (status == CaseStatus.done) {
        final now = DateTime.now();
        final months = _case!.appointment?.serviceType.interval_months ?? 6; // fallback 6
        final nextDue = DateTime(
          now.year,
          now.month + months,
          now.day,
          now.hour,
          now.minute,
          now.second,
        );

        final String? svcTypeId = _case!.appointment?.serviceType.id;
        if (svcTypeId == null || svcTypeId.isEmpty) {
          throw Exception('Missing serviceTypeId for new service reminder.');
        }

        final reminder = ServiceReminder(
          id:  const Uuid().v4(), // model requires non-null id
          userId: authService.currentUserId!,
          vehiclePlate: _case!.appointment!.vehicle.plateNo,
          serviceTypeId: svcTypeId,
          nextDueDate: nextDue,
          lastCompletedAt: now,
          status: ServiceReminderStatus.active,
          notes: 'System Generated Time for your next service!',
          createdAt: now,
          updatedAt: now,
        );

        await _insertNewServiceReminder(serviceReminder: reminder);
      }

      if (!mounted) return;

      final message = status == CaseStatus.done
          ? 'Case updated and service reminder has been added'
          : 'Case status updated successfully';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update case status: $e')),
      );
    }
  }

  Future<void> _insertNewServiceReminder({
    required ServiceReminder serviceReminder,
  }) async {
    if (_case == null) return;

    try {
      final repo = ServiceReminderRepository();
      await repo.create(serviceReminder, includeId: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New service reminder inserted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to insert service reminder: $e')),
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
            Icon(Icons.handyman, size: 22, color: Colors.white),
            SizedBox(width: 8),
            Text('Progress Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_case == null)
          ? const Center(
        child: Text('No case found for this booking.',
            style: TextStyle(color: Colors.white70)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Current Repair Card =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [purpleDark, purple],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: purple.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with status
                  Row(
                    children: [
                      const Text(
                        "Current Repair",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _statusPill(_case!.caseStatus),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _case!.appointment?.vehicle.model ?? '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "License No: ${_case!.appointment?.vehiclePlateNo ?? '-'}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Placeholder image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          "assets/images/profile.jpg",
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  // Meta labels
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MetaLabel(
                        icon: Icons.store_mall_directory_outlined,
                        text: "Workshop",
                      ),
                      _MetaLabel(
                        icon: Icons.schedule_outlined,
                        text: "Started",
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MetaValue(text: _case!.appointment?.outlet.outletName ?? '-'),
                      _MetaValue(text: _relative(_case!.createdAt)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ===== Timeline =====
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Case ID : ${_case!.caseId}",
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    overflow: TextOverflow.ellipsis, // 👈 truncates long text
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _case!.caseId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Case ID copied to clipboard")),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Repair Timeline",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                  ),
                  child: isCaseCompleted? TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/serviceFeedback');
                      // or: Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceFeedback()));
                    },
                    child: const Text(
                      "Leave A Feedback",
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ):
                  isPaymentNow? TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/payment', arguments: {
                        'caseId': _case!.caseId,
                        'bookingId': widget.bookingId,
                      });
                    },
                    child: const Text(
                      "Make Payment",
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ):
                  const Text(
                    "In Progress",
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                ),
                ),
              ],
            ),

            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              children: _buildTimelineTiles(_case!.caseStatus),
            ),

            // ===== Repair Details Card =====
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Repair Details",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)
                      ),
                      TextButton.icon(
                          onPressed: (){
                            final currentStatus = _case!.caseStatus;
                            final currentIndex = _ordered.indexOf(currentStatus);
                            if (currentIndex < _ordered.length - 1) {
                              final nextStatus = _ordered[currentIndex + 1];
                              _updateCaseStatus(nextStatus);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('This case is already at the final status.')),
                              );
                            }
                          }
                          ,
                          label: Text("Next Progress",style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),),
                          icon: const Icon(Icons.arrow_circle_right, size: 18, color: Color(0xFF10B981),
                      ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _DetailRow(
                    label: "Service Type",
                    value: _case!.appointment?.serviceType.name ?? '-',
                  ),
                  _DetailRow(
                    label: "Mileage",
                    value: (_case!.appointment?.mileage ?? 0).toString(),
                  ),
                  // You can add price if your ServiceType has it
                  // _DetailRow(label: "Cost Estimate", value: "RM ${_case!.appointment?.serviceType.price ?? '-'}",
                  //           valueColor: Color(0xFF10B981)),
                ],
              ),
            ),

            // ===== Workshop Info Card =====
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Workshop Info",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        onPressed: _openMap,
                        icon: const Icon(Icons.location_on, size: 16, color: Color(0xFF9333EA)),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_case!.appointment?.outlet.outletName ?? '-',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(_case!.appointment?.outlet.outletAddress ?? '-',
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
      CaseStatus.done => const Color(0xFF10B981),         // green
      CaseStatus.payment => const Color(0xFF60A5FA),      // blue
      CaseStatus.qc => const Color(0xFFF59E0B),           // amber
      CaseStatus.repair => const Color(0xFF9333EA),       // purple
      CaseStatus.prepareSparePart => const Color(0xFFA78BFA),
      CaseStatus.inspection => const Color(0xFF34D399),
      CaseStatus.checkIn => const Color(0xFF6EE7B7),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Text(
        _labels[status]!,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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

// ===== Helper Widgets from your original file =====
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(color: valueColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}
