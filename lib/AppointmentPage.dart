import 'package:flutter/material.dart';

import 'PartialView/_buildCancelledTab.dart';
import 'PartialView/_buildPastTab.dart';
import 'PartialView/_buildUpcomingTab.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  int currentTab = 0;

  final List<String> tabTitles = ["Upcoming", "Past", "Cancelled"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(8),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(tabTitles.length, (index) {
                final isSelected = index == currentTab;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentTab = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : [],
                    ),
                    child: Text(
                      tabTitles[index],
                      style: TextStyle(
                        fontSize: 17,
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Tab Content
          Expanded(
            child: IndexedStack(
              index: currentTab,
              children: [
                BuildUpcomingTab(),
                buildPastTab(),
                buildCancelledTab(),
              ],
            ),
          )
        ],
      ),
    );
  }



}
