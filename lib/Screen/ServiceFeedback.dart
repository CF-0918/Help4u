import 'dart:ui' as BorderType;

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ServiceFeedback extends StatefulWidget {
  const ServiceFeedback({super.key});

  @override
  State<ServiceFeedback> createState() => _ServiceFeedbackState();
}

class _ServiceFeedbackState extends State<ServiceFeedback> {
  final Color surface = const Color(0xFF1F2937);
  double ratingRate = 0;
  String getEmoji(double rating) {
    if (rating <= 1) {
      return "😡"; // very bad
    } else if (rating <= 2) {
      return "☹️"; // bad
    } else if (rating <= 3) {
      return "🙂"; // okay
    } else if (rating <= 4) {
      return "😃"; // good
    } else if (rating <= 5) {
      return "🤩"; // excellent
    } else {
      return "🤔"; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10.0,
                  children: [
                    Icon(Icons.oil_barrel, size: 35, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Oil Change",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Service ID: 123456789",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    size: 17,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "Completed Date : 12 Dec 2025",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_clock,
                                    size: 17,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "Completed Time : 9:00 AM",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "How Was Your Experience ? ${getEmoji(ratingRate)}",
                      style: TextStyle(
                        color: Colors.white,

                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Rating : $ratingRate/5 ",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),

                    SizedBox(height: 10),
                    RatingBar.builder(
                      updateOnDrag: true,
                      initialRating: 0,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder:
                          (context, _) => Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {
                        setState(() {
                          ratingRate = rating;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10,),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                    children: [
                      SizedBox(height: 5),
                      Text("Tell Us About Your Experience !",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
                      SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: DottedBorder(
                          options: RectDottedBorderOptions(
                            color: Colors.white,
                            strokeWidth: 2,
                            dashPattern: const <double>[6, 3], // line length, gap length
                          ),
                          child: TextField(
                            maxLines: 5,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: const InputDecoration(
                              hintText: "Type Here...",
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none, // remove default border
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ),
                    ]
                ),
              ),

              SizedBox(height: 15,),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const SizedBox(height: 5),
              const Text(
                "Add Photos (Optional)",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 15),

              // Dotted upload box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    // TODO: open image picker
                  },
                  child: DottedBorder(
                    options: RectDottedBorderOptions(
                      color: Colors.white,
                      strokeWidth: 2,
                      dashPattern: const <double>[6, 3],
                    ),
                    child: SizedBox(
                      height: 120, // 👈 give it size
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_photo_alternate, color: Colors.white70, size: 28),
                            SizedBox(height: 6),
                            Text("Tap to add images", style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 25,),
        SizedBox(
          width: 300,
          height: 60,             // big & fat height
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // purple gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, // important
                shadowColor: Colors.transparent,     // remove shadow so gradient shows
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // TODO: handle submit
              },
              child: const Text(
                "Submit",
                style: TextStyle(
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
      ),
    );
  }
}
