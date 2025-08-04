import 'package:flutter/material.dart';
import 'package:help4u_assignment/SendMessagePage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return  Container(
      child: SendMessagePage(),
    );
  }
}
