import 'package:flutter/material.dart';

class CarServiceProgress extends StatelessWidget {
  final int currentStep;
  final bool isPickupConfirmed;
  final bool isRepair;
  final String userServiceKM;
  final String userRepairComment;

  CarServiceProgress({
    super.key,
    this.currentStep = 0,
    this.isPickupConfirmed = false,
    this.isRepair = false,
    this.userServiceKM = "Next service due at 60,000 KM",
    this.userRepairComment = "Rear bumper replacement and repaint",
  });

  final List<Map<String, String>> _serviceSteps = const [
    {'title': 'In Inspection', 'content': 'Your car is in the inspection process.'},
    {'title': 'Service Prep', 'content': 'Preparing service parts and tools.'},
    {'title': 'Servicing', 'content': 'Performing scheduled maintenance.'},
    {'title': 'Quality Check', 'content': 'Post-service inspection in progress.'},
    {'title': 'Payment', 'content': 'Awaiting customer payment for services.'},
    {'title': 'Ready for Pickup', 'content': 'Service completed. Car ready for pickup.'},
  ];

  final List<Map<String, String>> _repairSteps = const [
    {'title': 'In Inspection', 'content': 'Your car is in the inspection process.'},
    {'title': 'Job Preparation', 'content': 'Preparing tools and replacement parts.'},
    {'title': 'Approval Customer', 'content': 'Waiting for customer approval.'},
    {'title': 'Repairing', 'content': 'Repair process ongoing.'},
    {'title': 'Quality Check', 'content': 'Final inspection before delivery.'},
    {'title': 'Payment', 'content': 'Awaiting customer payment for repairs.'},
    {'title': 'Ready for Pickup', 'content': 'Repair completed. Car ready for pickup.'},
  ];

  @override
  Widget build(BuildContext context) {
    final steps = isRepair ? _repairSteps : _serviceSteps;

    return ListView.builder(
      itemCount: steps.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        Color color;
        if (index < currentStep) {
          color = Colors.green;
        } else if (index == currentStep) {
          color = isPickupConfirmed ? Colors.green : Colors.orange;
        } else {
          color = Colors.grey;
        }

        String content = '';
        if (index == currentStep) {
          content = _buildStepContent(steps);
        } else if (index < currentStep) {
          content = steps[index]['content'] ?? '';
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: color,
                  child: Icon(
                    index < currentStep
                        ? Icons.check
                        : index == currentStep
                        ? Icons.directions_car
                        : Icons.radio_button_unchecked,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                if (index != steps.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: color,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index]['title']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );

  }

  String _buildStepContent(List<Map<String, String>> steps) {
    final baseContent = steps[currentStep]['content'] ?? '';

    if (isRepair && currentStep == 0) {
      return '$baseContent\n\nCustomer Comment: $userRepairComment';
    } else if (!isRepair && currentStep == 0) {
      return '$baseContent\n\nService Info: $userServiceKM';
    } else if (steps[currentStep]['title'] == 'Ready for Pickup' && isPickupConfirmed) {
      return 'Pickup confirmed by customer.';
    } else {
      return baseContent;
    }
  }
}
