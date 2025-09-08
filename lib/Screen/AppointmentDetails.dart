import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../Models/Appointment.dart';
import '../Models/Case.dart';
import '../Repository/appointment_repo.dart';
import '../Repository/case_repo.dart';
import 'Progress.dart';

class AppointmentDetails extends StatefulWidget {
  final String appointmentID;
  const AppointmentDetails({super.key, required this.appointmentID});

  @override
  State<AppointmentDetails> createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends State<AppointmentDetails> {
  final _casesRepo = CasesRepo();
  final _apptRepo = AppointmentRepository();

  bool _loading = true;
  bool _alreadyCheckedIn = false;
  bool _submitting = false;
  bool ableCancel=true;

  bool get isCheckInAllowed {
    if (_appt == null) return false;

    // normalize to avoid case/whitespace mismatches
    final status = _appt!.bookingStatus.trim().toUpperCase();
    if (status != 'CONFIRMED') return false;

    final now = DateTime.now();
    final bookingDate = _appt!.bookingDate;

    final allowed = DateUtils.isSameDay(now, bookingDate);

    debugPrint('isCheckInAllowed: $allowed | status: ${_appt!.bookingStatus}');
    debugPrint('now: $now | bookingDate: $bookingDate');
    return allowed;
  }


  Appointment? _appt; // loaded appointment

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // 1) Fetch the appointment by ID
      final appt = await _apptRepo.fetchUserAppointmentsById(widget.appointmentID);

      // 2) Check if a case already exists for this booking
      final hasCase = await _casesRepo.hasCaseForBooking(widget.appointmentID);

      if (!mounted) return;
      setState(() {
        _appt = appt;
        ableCancel = (DateTime.now().isBefore(_appt!.bookingDate))&&(_appt!.bookingStatus=='Confirmed');
        _alreadyCheckedIn = hasCase;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMap() async {
    if (_appt == null) return;
    final outlet = _appt!.outlet;
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

  Future<void> _cancelAppointment(String bookingId) async {
    // 1) Confirm
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Cancel Appointment'),
            ],
          ),
          content: const Text(
            'Are you sure you want to cancel this appointment? '
                'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), // red
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes, cancel',style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

// 2) Show loading dialog (don’t await here)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(message: 'Cancelling…'),
    );

// 3) Do the work
    try {
      await _apptRepo.updateStatus(bookingId, 'Cancelled');

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // ✅ close loading dialog

      setState(() {
        ableCancel = false;
      });
      await _load();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // ✅ close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel appointment: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

  }


  Future<void> _checkIn() async {
    if (_appt == null || _alreadyCheckedIn || _submitting) return;

    setState(() => _submitting = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final now = DateTime.now();

      final uuidCase= const Uuid().v4();
      // Build a minimal CaseModel; DB will accept it.
      final newCase = CaseModel(
        caseId: uuidCase,       // client-generated ID (ok), or omit in repo insert
        bookingId: _appt!.id,
        userId: uid,
        appointment: null,               // filled only on read (JOIN)
        caseStatus: CaseStatus.checkIn,  // default CHECK_IN
        caseClosed: false,
        workerComments: null,
        createdAt: now,
        updatedAt: now,
      );

      await _apptRepo.updateStatus(_appt!.id, 'Completed');

      await _casesRepo.createCase(newCase);

      if (!mounted) return;
      setState(() => _alreadyCheckedIn = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked in successfully')),
      );

      // If you want to push to Progress page after check-in:
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => Progress(bookingId: _appt!.id),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B1220);
    const card = Color(0xFF111827);
    const purple = Color(0xFF9333EA);
    const accent = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0.5,
        title: const Text('Appointment Details', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_appt == null)
          ? const Center(
        child: Text('Appointment not found', style: TextStyle(color: Colors.white70)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Summary card (distinct from Progress gradient) =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // outlet + status pill
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _appt!.outlet.outletName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      _StatusPill(
                        text: _alreadyCheckedIn ? 'Checked-in' : _appt!.bookingStatus,
                        color: _alreadyCheckedIn
                            ? const Color(0xFF10B981)               // green when checked-in
                            : (_appt!.bookingStatus.trim().toUpperCase() == 'CANCELLED'
                            ? const Color(0xFFEF4444)           // red when cancelled
                            : Colors.blueGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Vehicle + plate
                  Row(
                    children: [
                      const Icon(Icons.directions_car, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _appt!.vehicle.model,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _appt!.vehiclePlateNo,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Service + mileage
                  Row(
                    children: [
                      const Icon(Icons.build_outlined, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _appt!.serviceType.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${_appt!.mileage} KM',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Date + time
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _appt!.bookingDate.toIso8601String().split('T').first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.schedule, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _appt!.bookingTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Actions =====
            Row(
              children: [
                Expanded(
                  child: isCheckInAllowed? ElevatedButton.icon(
                    onPressed: (_alreadyCheckedIn || _submitting) ? null : _checkIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      _alreadyCheckedIn ? Colors.grey.shade700 : purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.touch_app, color: Colors.white),
                    label: Text(
                      _alreadyCheckedIn ? 'Already Checked In' : 'Check In Now',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ):
                  !_alreadyCheckedIn? Text(
                    'Check-in is available only on the appointment date.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ):
                    Center(
                      child:   Text("You have already checked in.", style: TextStyle(color: Colors.green, fontSize: 13,fontWeight: FontWeight.w700),),
                    )
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openMap,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade600, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.location_on, color: Colors.white70),
                    label: const Text(
                      'View Map',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Launch dialer if you store phone in Outlet
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade600, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.phone, color: Colors.white70),
                    label: const Text(
                      'Call Workshop',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            ableCancel?
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                     _cancelAppointment(_appt!.id);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.red,
                      side: BorderSide(color: Colors.grey.shade600, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text(
                      'Cancelled Appointment',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ):
            const SizedBox(),
            const SizedBox(height: 16,),

            // ===== Address block =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workshop Address',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _appt!.outlet.outletAddress ?? '-',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (_appt!.outlet.latitude != null &&
                      _appt!.outlet.longitude != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '(${_appt!.outlet.latitude}, ${_appt!.outlet.longitude})',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// A tiny reusable loading dialog
class _LoadingDialog extends StatelessWidget {
  final String message;
  const _LoadingDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.75),
      insetPadding: const EdgeInsets.symmetric(horizontal: 100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
