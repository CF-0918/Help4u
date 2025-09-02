import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Components/Timeline_tile.dart';
import 'ServiceFeedback.dart';

class Progress extends StatelessWidget {
  final String processId;
  const Progress({super.key,required this.processId});

  Future<void> _openMap() async {
    final Uri uri = Uri.parse("geo:3.1622148,101.5869321?q=Workshop");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch Maps.";
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9333EA);
    const purpleDark = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220), // dark page bg
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0.5,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.handyman, size: 22),
            SizedBox(width: 8),
            Text(
              "$processId Progress",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: Colors.white),
            ),
          ],
        ),
        centerTitle: false,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
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
                    // Top row: title + status pill
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), // green
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            "In Progress",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
        
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==== Car Info (Column) ====
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Honda Civic",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "License No: ABC-12345",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
        
                        // ==== Image on the right ====
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // rounded corners
                          child: Image.asset(
                            "assets/images/profile.jpg",
                            width: 80,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
        
                    SizedBox(height: 13),
        
                    // Meta headings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
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
        
                    // Meta values
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _MetaValue(text: "AutoFix Pro Center"),
                        _MetaValue(text: "2 hours ago"),
                      ],
                    ),
                  ],
                ),
              ),
        
              //Timeline will  be at below
              SizedBox(height: 10),
        
              // ===== Timeline =====
              // ===== Timeline =====
              const SizedBox(height: 10),
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
                      border: Border.all(color: const Color(0xFF10B981), width: 1.5), // 👈 fixed
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ServiceFeedback()),
                        );
                      },
                      child: const Text(
                        "Leave A Feedback",
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )

                ],
              ),

        
              ListView(
                shrinkWrap: true,                       // <-- let it measure its own height
                physics: const NeverScrollableScrollPhysics(), // <-- avoid nested scroll
                padding: const EdgeInsets.only(top: 8),
                children: const [
                  MyStepTile(
                    isFirst: true, isLast: false, isPast: true,
                    title: 'Booked', subtitle: '2 Aug, 10:30 AM',
                  ),
                  MyStepTile(
                    isFirst: false, isLast: false, isPast: true,
                    title: 'Vehicle Received', subtitle: '2 Aug, 11:15 AM',
                  ),
                  MyStepTile(
                    isFirst: false, isLast: false, isPast: false,
                    title: 'Repair in Progress', subtitle: 'ETA 4 PM',
                  ),
                  MyStepTile(
                    isFirst: false, isLast: true, isPast: false,
                    title: 'Ready for Pickup',
                  ),
                ],
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
                  children: const [
                    Text("Repair Details",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 12),
        
                    // Service Type
                    _DetailRow(label: "Service Type", value: "Engine Repair"),
        
                    // Estimated Time
                    _DetailRow(label: "Estimated Time", value: "4-5 hours"),
        
                    // Mechanic
                    _DetailRow(label: "Mechanic", value: "John Martinez"),
        
                    // Cost
                    _DetailRow(
                      label: "Cost Estimate",
                      value: "\$350",
                      valueColor: Color(0xFF10B981), // green
                    ),
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
                          onPressed: () {
                            _openMap();
                          },
                          icon: const Icon(Icons.location_on, size: 16, color: Color(0xFF9333EA)),
                          label: const Text(
                            "View Map",
                            style: TextStyle(
                              color: Color(0xFF9333EA), // purple accent
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )

                      ],
                    ),
                    const SizedBox(height: 12),
        
                    // Workshop row
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
                            children: const [
                              Text("AutoFix Pro Center",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 2),
                              Text("Bandar Kota Damansara",
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 15, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text("4.8 (124 reviews)",
                                      style:
                                      TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
        
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF9333EA),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                            label: const Text("Call Workshop",
                                style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade600, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.message_outlined,
                                size: 18, color: Colors.white70),
                            label: const Text("Send Message",
                                style: TextStyle(color: Colors.white70,fontWeight: FontWeight.w600)),
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
      ),
    );
  }
}
// ===== Helper Widget =====
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
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
