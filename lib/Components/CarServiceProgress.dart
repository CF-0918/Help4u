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
    {
      'title': 'In Inspection',
      'content': 'Your car is in the inspection process.',
    },
    {
      'title': 'Service Prep',
      'content': 'Preparing service parts and tools.',
    },
    {
      'title': 'Servicing',
      'content': 'Performing scheduled maintenance.',
    },
    {
      'title': 'Completed',
      'content': 'Service is completed. Ready for pickup.',
    },
  ];

  final List<Map<String, String>> _repairSteps = const [
    {
      'title': 'In Inspection',
      'content': 'Your car is in the inspection process.',
    },
    {
      'title': 'Job Preparation',
      'content': 'Preparing tools and replacement parts.',
    },
    {
      'title': 'Approval Customer',
      'content': 'Waiting for customer approval.',
    },
    {
      'title': 'Repairing',
      'content': 'Repair process ongoing.',
    },
    {
      'title': 'Completed',
      'content': 'Repair is done. Your car is ready.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final steps = isRepair ? _repairSteps : _serviceSteps;

    return Stepper(
      currentStep: currentStep,
      controlsBuilder: (context, details) => const SizedBox.shrink(),
      physics: const NeverScrollableScrollPhysics(),
      onStepTapped: (_) {},
      steps: List.generate(steps.length, (index) {
        // Color logic
        Color color;
        if (index < currentStep) {
          color = Colors.green;
        } else if (index == currentStep) {
          color = isPickupConfirmed ? Colors.green : Colors.orange;
        } else {
          color = Colors.grey;
        }

        // Step content logic
        String? contentText;
        if (index <= currentStep) {
          if (isRepair && index == 0) {
            contentText = '${steps[index]['content']}\n\nCustomer Comment: $userRepairComment';
          } else if (!isRepair && index == 0) {
            contentText = '${steps[index]['content']}\n\nService Info: $userServiceKM';
          } else if (index == steps.length - 1 && isPickupConfirmed) {
            contentText = 'Pickup confirmed by customer.';
          } else {
            contentText = steps[index]['content'];
          }
        } else {
          contentText = null; // Hide future steps
        }

        return Step(
          title: Text(
            steps[index]['title']!,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          content: contentText != null
              ? Text(contentText, style: TextStyle(color: color))
              : const SizedBox.shrink(),
          isActive: index <= currentStep,
          state: index < currentStep
              ? StepState.complete
              : (index == currentStep
              ? (isPickupConfirmed ? StepState.complete : StepState.editing)
              : StepState.indexed),
        );
      }),
    );
  }
}
