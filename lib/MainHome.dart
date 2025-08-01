import 'package:flutter/material.dart';
import 'package:help4u_assignment/AppointmentPage.dart';
import 'package:help4u_assignment/Components/CarServiceProgress.dart';
import 'package:help4u_assignment/FeedBackPage.dart';
import 'package:help4u_assignment/UserInvoicePage.dart';

import 'Components/AppointmentCard.dart';
import 'ContactUsPage.dart';
import 'Model/Appointment.dart';

class MainHome extends StatefulWidget {
  const MainHome({super.key});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  String userName = "Yong Cheng Fung";
  //String status = "Await-Payment"; // Replace this with your actual status variable
  String status = "Paid";
  List<Appointment> upcomingAppointments = [
    Appointment(
      vehicle: "Toyota Vios 1.5G",
      dateTime: "26/07/2025 10:30AM",
      location: "Smart Degree Workshop, PJ Branch",
      type: "Service",
      mileage: "45,000 KM",
    ),
    Appointment(
      vehicle: "Honda Civic 1.8",
      dateTime: "30/07/2025 02:00PM",
      location: "Smart Degree Workshop, KL Branch",
      type: "Repair",
      comment: "Air conditioning not working",
    ),
  ];

// Reusable widget with navigation
  Widget _buildMenuBox(BuildContext context, IconData icon, String title, Widget targetPage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 3),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 26),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: Colors.black, fontSize: 16,fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1B1919),
              Color(0xFF484646),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row (greeting + verification)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (userName != null && userName!.isNotEmpty)
                            ? "Hi, $userName"
                            : "User Name",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 20.0,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Verified",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu Grid
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMenuBox(
                            context,
                            Icons.calendar_month,
                            "Make Appointment",
                            AppointmentPage(),
                          ),
                        ),
                        Expanded(
                          child: _buildMenuBox(
                            context,
                            Icons.phone, // Fixed icon
                            "Contact Us",  // Fixed typo
                            ContactUsPage(),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMenuBox(
                            context,
                            Icons.star,
                            "Pending Rating",
                            FeedbackPage(),
                          ),
                        ),
                        Expanded(
                          child: _buildMenuBox(
                            context,
                            Icons.receipt,
                            "OutStanding Invoice",
                            UserInvoicePage(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),


                SizedBox(height: 20),

                // Upcoming Appointments Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10.0,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white),
                    Text(
                      "Upcoming Appointments (${upcomingAppointments.length})",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10),

                // Appointments List
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: upcomingAppointments.length,
                    itemBuilder: (context, index) {
                      return AppointmentCard(appointment: upcomingAppointments[index]);
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Display Latest Car Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.autorenew, color: Colors.white),
                    SizedBox(width: 10), // spacing between icon and text
                    Text(
                      "Current Car Service Progress",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 15),
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),

                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        "images/assets/google.png",
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 16), // Space between image and text
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Plate No: VHA 5309",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Car: Toyota Vios 1.8 G",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                              ),
                            ),

                            Container(
                              width: double.infinity,
                              child: CarServiceProgress(
                                currentStep: 3,
                                isRepair: false, // or true for repair
                                isPickupConfirmed: false,
                              )

                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        status == "Await-Payment"
                            ? Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              // Redirect to payment gateway
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AppointmentPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: Text(
                              "Pay Now",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                            : SizedBox.shrink(),

                      ],
                    ),
                  ),
                ),




              ],
            ),
          ),
        ),
      ),
    );
  }

}




