import 'package:flutter/material.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool isLoading = true;
  List<String> progressData = [];

  @override
  void initState() {
    super.initState();
    fetchProgress();
  }

  Future<void> fetchProgress() async {
    // Simulate fetching from DB
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      progressData = ['Week 1: Complete', 'Week 2: In progress'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: progressData.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(progressData[index]),
        onTap: () {
          // Maybe navigate to detail page
        },
      ),
    );
  }
}

