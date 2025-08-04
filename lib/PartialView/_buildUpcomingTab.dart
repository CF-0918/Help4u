import 'package:flutter/material.dart';
import '../MakeAppointmentPage.dart';

class BuildUpcomingTab extends StatefulWidget {
  const BuildUpcomingTab({super.key});

  @override
  State<BuildUpcomingTab> createState() => _BuildUpcomingTabState();
}

class _BuildUpcomingTabState extends State<BuildUpcomingTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Placeholder(),

      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.white,
        backgroundColor: Colors.red,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MakeAppointmentPage()),
          );
        },
        child: const Icon(Icons.add,size: 30,),
      ),
    );
  }
}
