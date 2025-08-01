import 'package:flutter/material.dart';

import 'AppointmentPage.dart';
import 'AuthSelectionPage.dart';
import 'MainHome.dart';
import 'ProfilePage.dart';
import 'ProgressPage.dart';
import 'login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;
  List <Widget> widgetList=[
    MainHome(),
    ProgressPage(),
    AppointmentPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true, // ✅ Important for center alignment
          title: Row(
            mainAxisSize: MainAxisSize.min, // ✅ This keeps it centered
            children: [
              Image.asset(
                'images/assets/LogoNoWord.png',
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 8),
              const Text(
                'Help4U',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // Action here
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: Colors.white, // Set background color here
          child: Container(
            padding: EdgeInsets.all(16), // Optional: Add some spacing
            child: Text(
              "Drawer here",
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),
        ),

        body: Center(
         child: widgetList[index],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        selectedIconTheme: IconThemeData(
          size: 30, // 🔹 Size for selected icon
        ),
        unselectedIconTheme: IconThemeData(
          size: 24, // 🔹 Size for unselected icon
        ),
        selectedLabelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 13,
        ),

        onTap: (value){
          setState(() {
            index=value;
          });
        },
      currentIndex: index,
        items: [
        BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home"
        ),
        BottomNavigationBarItem(icon: Icon(Icons.autorenew), label: "Progress"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Booking"),
        BottomNavigationBarItem(icon: Icon(Icons.person_off_rounded), label: "Profile"),
      ],

      )
    );
  }
}
