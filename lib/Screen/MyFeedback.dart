import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyFeedback extends StatefulWidget {
  const MyFeedback({super.key});

  @override
  State<MyFeedback> createState() => _MyFeedbackState();
}

class _MyFeedbackState extends State<MyFeedback> {
  final Color surface = const Color(0xFF1F2937);
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> feedbackList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  Future<void> _fetchFeedback() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint("❌ No logged-in user, skipping fetch");
        setState(() {
          feedbackList = [];
          loading = false;
        });
        return;
      }

      debugPrint("🔑 Current user: ${user.id}");

      final response = await supabase
          .from('service_feedback')
          .select(
        '''
          feedback_id,
          comments,
          rating,
          images,
          created_at,
          booking:booking_id(
            booking_id,
            bookingdate,
            bookingtime,
            vehicleplateno,
            service_type(name)
          )
          ''',
      )
          .eq('userid', user.id)
          .order('created_at', ascending: false);

      debugPrint("📦 Raw service_feedback response: $response");

      setState(() {
        feedbackList = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e, st) {
      debugPrint("❌ Error fetching feedback: $e");
      debugPrintStack(stackTrace: st);
      setState(() {
        feedbackList = [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("My Feedback",
            style: TextStyle(fontSize: 20, color: Colors.white)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : feedbackList.isEmpty
          ? const Center(
        child: Text(
          "No feedback found.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: feedbackList.length,
        itemBuilder: (context, index) {
          final fb = feedbackList[index];
          final booking = fb['booking'] ?? {};
          final serviceType = booking['service_type'] ?? {};
          final List images = fb['images'] ?? [];

          bool expanded = false;

          return StatefulBuilder(
            builder: (context, setStateTile) {
              return Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceType['name'] ?? 'Unknown Service',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Plate: ${booking['vehicleplateno'] ?? 'N/A'}",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      "Completed: ${booking['bookingdate'] ?? ''} ${booking['bookingtime'] ?? ''}",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    // ⭐ Rating stars
                    Row(
                      children: List.generate(5, (i) {
                        final rating =
                            (fb['rating'] as num?)?.toDouble() ?? 0.0;
                        return Icon(
                          i < rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),

                    if (fb['comments'] != null &&
                        fb['comments'].toString().trim().isNotEmpty)
                      Text(
                        fb['comments'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),

                    const SizedBox(height: 8),

                    if (images.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setStateTile(() {
                            expanded = !expanded;
                          });
                        },
                        icon: Icon(
                          expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.white70,
                        ),
                        label: Text(
                          expanded
                              ? "Hide Images"
                              : "Show Images (${images.length})",
                          style:
                          const TextStyle(color: Colors.white70),
                        ),
                      ),

                    if (expanded && images.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width * 0.5, // ✅ 50% of screen width
                          child: Image.network(
                            images.first,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
