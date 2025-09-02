import 'package:flutter/material.dart';

import '../Screen/Progress.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});
  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  bool _animate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // replay the animation whenever this tab becomes active
    Future.microtask(() => setState(() => _animate = true));
  }

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // ===== Stats row =====
            Row(
              children: [
                // On Going
                Expanded(
                  child: Column(
                    children: [
                      Card(
                        color: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.pending, color: Colors.white, size: 28),
                              SizedBox(width: 10),
                              Text(
                                "23",
                                style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text("On Going", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Completed
                Expanded(
                  child: Column(
                    children: [
                      Card(
                        color: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.incomplete_circle_outlined, color: Colors.white, size: 28),
                              SizedBox(width: 10),
                              Text(
                                "15",
                                style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text("Completed", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Total
                Expanded(
                  child: Column(
                    children: [
                      Card(
                        color: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.car_repair, color: Colors.white, size: 28),
                              SizedBox(width: 10),
                              Text(
                                "42",
                                style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text("Total", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),

            // ===== Section header =====
            Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 20),
                  Text("On Going Repairs",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text("Track Your Car Progress",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white70)),
                ],
              ),
            ),

            // ===== Job card =====
            Card(
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
                              const Text("Honda Civic",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                              const SizedBox(height: 4),
                              const Text("License Plate No: WXY 1234",
                                  style: TextStyle(fontSize: 13, color: Colors.black54)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  _ChipTag(label: "Engine Repair", color: Color(0xFF9333EA)),
                                  _ChipTag(label: "Oil Change", color: Color(0xFF1F2937)),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // RIGHT image
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
                      children: const [
                        Icon(Icons.handyman, color: Colors.blueAccent, size: 25),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Help4U - Bandar Kota Damansara",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.location_on_outlined, color: Color(0xFF4B5563), size: 25),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Ground Floor, Bangunan Tan Sri Khaw Kai Boh (Block A), Jalan Genting Kelang, Setapak, 53300 Kuala Lumpur, Federal Territory of Kuala Lumpur",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress with animation that replays on tab re-entry
                    TweenAnimationBuilder<double>(
                      key: ValueKey(_animate), // forces rebuild when _animate changes
                      tween: Tween(begin: 0, end: 0.65),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, v, _) => LabeledProgress(label: 'Progress', value: v),
                    ),

                    SizedBox(height: 10,),
                    Row(
                      children: [
                        Expanded(child:Container(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Progress(
                                      processId: "PRC-1029", // e.g. "PRC-1029"
                                    ),
                                  ),
                                );
                              },
                              child: Text("View Details",style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),)
                          ),
                        )
                        ),
                       SizedBox(width: 10,),
                       Container(
                         padding: EdgeInsets.symmetric(vertical: 3),
                         decoration: BoxDecoration(
                           color: Colors.grey.withOpacity(0.2),
                           borderRadius: BorderRadius.circular(10),
                         ),
                         child:   IconButton(onPressed: (){}, icon:Icon(Icons.call),color: Colors.grey,),
                       )

                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
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
    this.barColor = const Color(0xFF9333EA),   // purple
    this.trackColor = const Color(0xFFE5E7EB), // light gray (same as before)

  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: 4,),
            Text(label, style: const TextStyle(fontSize: 14,color: Colors.purple,fontWeight:FontWeight.bold)),
            const Spacer(),
            Text('${(value * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 14,color: Colors.purple,fontWeight:FontWeight.bold)),
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
