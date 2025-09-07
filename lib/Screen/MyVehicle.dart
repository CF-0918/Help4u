import 'package:flutter/material.dart';

class MyVehicle extends StatefulWidget {
  const MyVehicle({super.key});

  @override
  State<MyVehicle> createState() => _MyVehicleState();
}

class _MyVehicleState extends State<MyVehicle> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('My Vehicle Screen - To be implemented')),
    );
  }
}
