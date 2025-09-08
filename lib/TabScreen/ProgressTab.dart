import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Screen/Progress.dart';
import '../Models/Case.dart';
import '../Repository/case_repo.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});
  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  final _casesRepo = CasesRepo();
  bool _loading = true;
  bool _animate = false;

  List<CaseModel> _active = [];
  List<CaseModel> _completed = [];

  // status order for progress %
  static const List<CaseStatus> _ordered = [
    CaseStatus.checkIn,
    CaseStatus.inspection,
    CaseStatus.prepareSparePart,
    CaseStatus.repair,
    CaseStatus.qc,
    CaseStatus.payment,
    CaseStatus.done,
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() => setState(() => _animate = true));
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final active = await _casesRepo.getActiveCasesForUser(uid);
      final completed = await _casesRepo.getCompletedCasesForUser(uid);
      if (!mounted) return;
      setState(() {
        _active = active;
        _completed = completed;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load progress: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _progressFor(CaseStatus s) {
    final idx = _ordered.indexOf(s);
    if (idx < 0) return 0.0;
    return (idx + 1) / _ordered.length; // 1..7 → 0.14..1.0
  }

  Future<void> _callWorkshop(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool isPaymentStage(CaseStatus s) {
    return s == CaseStatus.payment || s == CaseStatus.done;
  }

  @override
  Widget build(BuildContext context) {
    final total = _active.length + _completed.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(Icons.car_repair, size: 25),
            SizedBox(width: 5),
            Text(
              "Repair Progress",
              style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetch,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // ===== Stats row =====
              Row(
                children: [
                  _StatCard(
                    color: Colors.amber.shade700,
                    icon: Icons.pending,
                    label: 'On Going',
                    value: _active.length,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    color: Colors.green.shade600,
                    icon: Icons.check_circle_outline,
                    label: 'Completed',
                    value: _completed.length,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    color: Colors.blue.shade600,
                    icon: Icons.all_inclusive,
                    label: 'Total',
                    value: total,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("On Going Repairs",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text("Track Your Car Progress",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (_active.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text('No running repairs right now.',
                      style: TextStyle(color: Colors.white70)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _active.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = _active[i];
                    final appt = c.appointment; // joined data
                    final outlet = appt?.outlet;
                    final vehicle = appt?.vehicle;

                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LEFT
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                  "${vehicle?.brand ?? '-'} ${vehicle?.model ?? '-'}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'License Plate No: ${appt?.vehiclePlateNo ?? '-'}',
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _ChipTag(
                                            label: appt?.serviceType.name ?? '-',
                                            color: const Color(0xFF9333EA),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // RIGHT image (placeholder)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/images/profile.jpg',
                                    width: 90,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              height: 20,
                              thickness: 1,
                              color: Colors.grey.withOpacity(0.2),
                              indent: 10,
                              endIndent: 10,
                            ),
                            Row(
                              children: [
                                const Icon(Icons.handyman, color: Colors.blueAccent, size: 25),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    outlet?.outletName ?? '-',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Color(0xFF4B5563), size: 25),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    outlet?.outletAddress ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // progress bar
                            TweenAnimationBuilder<double>(
                              key: ValueKey('p-${c.caseId}-${_animate ? 1 : 0}'),
                              tween: Tween(begin: 0, end: _progressFor(c.caseStatus)),
                              duration: const Duration(milliseconds: 600),
                              builder: (context, v, _) =>
                                  LabeledProgress(label: 'Progress', value: v),
                            ),

                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        final bid = c.bookingId;
                                        if (bid == null) return;

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => Progress(bookingId: bid),
                                          ),
                                        ).then((_) {
                                          setState(() {
                                            _animate = false;
                                            _fetch();        // refresh your data
                                            _loading = true;
                                          });
                                        });
                                      },
                                      child: const Text(
                                        "View Details",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    onPressed: () => _callWorkshop(outlet?.outletPhoneNo),
                                    icon: const Icon(Icons.call),
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            isPaymentStage(c.caseStatus)
                                ? Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Please prepare for payment at the counter. or ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 5,),
                              TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.payment),
                                label: const Text('Pay Now'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white, // applies to text + icon
                                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                ),
                              ),

                              ],
                              ),
                            )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== small reusable bits =====
class _StatCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final int value;
  const _StatCard({required this.color, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Card(
            color: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  final String label;
  final Color color;
  const _ChipTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class LabeledProgress extends StatelessWidget {
  final String label;
  final double value; // 0.0 - 1.0
  final Color barColor;
  final Color trackColor;
  const LabeledProgress({
    super.key,
    required this.label,
    required this.value,
    this.barColor = const Color(0xFF9333EA),
    this.trackColor = const Color(0xFFE5E7EB),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.purple, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${(value * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14, color: Colors.purple, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            color: barColor,
            backgroundColor: trackColor,
          ),
        ),
      ],
    );
  }
}
