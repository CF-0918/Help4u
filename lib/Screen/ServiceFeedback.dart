import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ServiceFeedback extends StatefulWidget {
  final String caseId;
  final String bookingId;

  const ServiceFeedback({
    Key? key,
    required this.caseId,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<ServiceFeedback> createState() => _ServiceFeedbackState();
}

class _ServiceFeedbackState extends State<ServiceFeedback> {
  final Color surface = const Color(0xFF1F2937);
  final ImagePicker _picker = ImagePicker();

  double ratingRate = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _loading = false;
  bool _hasReview = false;
  String? _feedbackId;
  String? _uploadedImage;


  String getEmoji(double rating) {
    if (rating <= 1) return "😡";
    if (rating <= 2) return "☹️";
    if (rating <= 3) return "🙂";
    if (rating <= 4) return "😃";
    if (rating <= 5) return "🤩";
    return "🤔";
  }

  @override
  void initState() {
    super.initState();
    _loadExistingReview();   // 👈 fetch review immediately
  }

  Future<void> _loadExistingReview() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response = await supabase
        .from('service_feedback')
        .select()
        .eq('caseid', widget.caseId.toString())
        .eq('booking_id', widget.bookingId.toString())
        .eq('userid', userId.toString())
        .maybeSingle();

    if (response != null) {
      setState(() {
        _hasReview = true;
        _feedbackId = response['feedback_id'] as String; // 👈 use feedback_id
        ratingRate = (response['rating'] ?? 0).toDouble();
        _commentController.text = response['comments'] ?? '';
      });
    }
  }

  Future<void> _submitFeedback() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);

    try {
      bool isUpdate = false;

      if (_hasReview && _feedbackId != null) {
        // update
        isUpdate = true;
        await supabase.from('service_feedback').update({
          'rating': ratingRate,
          'comments': _commentController.text.trim(),
          'images': _uploadedImage != null ? [_uploadedImage] : [],
        }).eq('feedback_id', _feedbackId.toString());
      } else {
        // insert
        final inserted = await supabase.from('service_feedback').insert({
          'caseid': widget.caseId,
          'booking_id': widget.bookingId,
          'userid': userId,
          'rating': ratingRate,
          'comments': _commentController.text.trim(),
          'images': _uploadedImage != null ? [_uploadedImage] : [],
        }).select().single();

        _feedbackId = inserted['feedback_id'];
        _hasReview = true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isUpdate ? "Feedback updated!" : "Feedback submitted!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error submitting feedback: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Service Feedback",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔹 Service Info Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.oil_barrel, size: 35, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Oil Change",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Service ID: 123456789",
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.calendar_month,
                                size: 17, color: Colors.white70),
                            SizedBox(width: 5),
                            Text(
                              "Completed Date : 12 Dec 2025",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.lock_clock,
                                size: 17, color: Colors.white70),
                            SizedBox(width: 5),
                            Text(
                              "Completed Time : 9:00 AM",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 🔹 Rating Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    "How Was Your Experience? ${getEmoji(ratingRate)}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Rating : $ratingRate/5 ",
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  RatingBar.builder(
                    updateOnDrag: true,
                    initialRating: 0,
                    minRating: 1,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() => ratingRate = rating);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 🔹 Comments Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    "Tell Us About Your Experience!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // 🔹 Feedback Input Box
                  DottedBorder(
                    options: RectDottedBorderOptions(
                      color: Colors.white,
                      strokeWidth: 2,
                      dashPattern: const [6, 3],
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 5,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Type Here...",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),
// 🔹 Image Upload Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    "Add Photo (Optional)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () async {
                      final picked = await _picker.pickImage(source: ImageSource.gallery);

                      if (picked != null) {
                        final supabase = Supabase.instance.client;
                        final fileBytes = await picked.readAsBytes();
                        final userId = supabase.auth.currentUser?.id;

                        // 👇 Store inside Help4uBucket/feedback/
                        final filePath = "feedback/${widget.caseId}_$userId.jpg";

                        await supabase.storage
                            .from("Help4uBucket") // bucket name
                            .uploadBinary(
                          filePath,
                          fileBytes,
                          fileOptions: const FileOptions(upsert: true), // overwrite if exists
                        );

                        // 👇 Get the public URL for DB storage
                        final publicUrl = supabase.storage
                            .from("Help4uBucket")
                            .getPublicUrl(filePath);

                        setState(() {
                          _uploadedImage = publicUrl; // save public URL in state
                        });
                      }
                    },


                    child: DottedBorder(
                      options: RectDottedBorderOptions(
                        color: Colors.white,
                        strokeWidth: 2,
                        dashPattern: const [6, 3],
                      ),
                      child: SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: Center(
                          child: _uploadedImage == null
                              ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add_photo_alternate,
                                  color: Colors.white70, size: 28),
                              SizedBox(height: 6),
                              Text("Tap to add image",
                                  style: TextStyle(color: Colors.white70)),
                            ],
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _uploadedImage!,
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
// 🔹 Submit / Edit Button
            SizedBox(
              width: 300,
              height: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _submitFeedback,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _hasReview ? "Edit Review" : "Submit",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
