import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MakeAppointmentPage extends StatefulWidget {
  const MakeAppointmentPage({super.key});

  @override
  State<MakeAppointmentPage> createState() => _MakeAppointmentPageState();
}

class _MakeAppointmentPageState extends State<MakeAppointmentPage> {

  int _currentStep = 0;

  final _formKey = GlobalKey<FormState>();

  final _mileageController = TextEditingController();
  final _commentsController = TextEditingController();
  final _altContactPersonController = TextEditingController();
  final _altPhoneController = TextEditingController();

  String? selectedOutlet;
  String? selectedCarType;
  String selectedServiceType = "Service";

  late DateTime today;
  late DateTime firstDay;
  late DateTime lastDay;

  @override
  void initState() {
    super.initState();
    today = DateTime.now();
    firstDay = DateTime(today.year, today.month, today.day);
    lastDay = DateTime(today.year, today.month + 2, today.day);
  }
  void _onDaySelected(DateTime day, DateTime focusedDay){
    setState(() {
      print("Selected day: $day");
      today=day;
    });
  }

  final List<String> _titles = ["Profile", "Time", "Done"];

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        if (selectedServiceType == "Service") {
          final mileageText = _mileageController.text.trim();

          if (mileageText.isEmpty || int.tryParse(mileageText) == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Mileage must be a number.")),
            );
            return;
          }

          final mileage = int.parse(mileageText);
          if (mileage < 1000) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Mileage must be more than 1000 KM.")),
            );
            return;
          }
        }

        setState(() {
          _currentStep += 1;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please complete all required fields."),
          ),
        );
      }
    } else {
      if (_currentStep < 2) {
        setState(() {
          _currentStep += 1;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment Completed')),
        );
      }
    }
  }


  @override
  void dispose() {
    _mileageController.dispose();
    _commentsController.dispose();
    _altContactPersonController.dispose();
    _altPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text("Make Appointment"),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
        child: Column(
          children: [
            // Stepper Header
            Row(
              children: List.generate(_titles.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Container(height: 2, color: Colors.white24),
                    ),
                  );
                } else {
                  int stepIndex = index ~/ 2;
                  bool isActive = _currentStep == stepIndex;
                  bool isCompleted = _currentStep > stepIndex;

                  return Expanded(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isCompleted
                              ? Colors.green
                              : isActive
                              ? Colors.red
                              : Colors.white10,
                          child: Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isCompleted || isActive
                                  ? Colors.white
                                  : Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _titles[stepIndex],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }),
            ),

            const SizedBox(height: 30),

            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: _getStepContent(_currentStep),
              ),
            ),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentStep == 0
                      ? null
                      : () => setState(() => _currentStep -= 1),
                  child: const Text(
                    "Back",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    _currentStep < 2 ? "Continue" : "Finish",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _getStepContent(int step) {

    switch (step) {
      case 0:
        return SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter Your Personal Details",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 16),


                // Outlet
                DropdownButtonFormField<String>(
                  value: selectedOutlet,
                  decoration: const InputDecoration(
                    labelText: "Outlet",
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  items: ["Outlet A", "Outlet B", "Outlet C"]
                      .map((outlet) => DropdownMenuItem(
                    value: outlet,
                    child: Text(outlet),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedOutlet = value!);
                  },
                  validator: (value) =>
                  value == null ? 'Please select an outlet' : null,
                ),

                const SizedBox(height: 16),

                // Car Type
                DropdownButtonFormField<String>(
                  value: selectedCarType,
                  decoration: const InputDecoration(
                    labelText: "Car Type",
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  items: ["Sedan", "SUV", "Hatchback", "Other"]
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedCarType = value!);
                  },
                  validator: (value) =>
                  value == null ? 'Please select a car type' : null,
                ),

                const SizedBox(height: 16),

                // Service Type
                DropdownButtonFormField<String>(
                  value: selectedServiceType,
                  decoration: const InputDecoration(
                    labelText: "Service Type",
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  items: ["Service", "Repair"]
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedServiceType = value!);
                  },
                ),

                const SizedBox(height: 16),

                // Conditional field
                if (selectedServiceType == "Service")
                  TextFormField(
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Enter Mileage',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) => selectedServiceType == "Service" &&
                        value!.isEmpty
                        ? 'Please enter mileage'
                        : null,
                  )
                else
                  TextFormField(
                    controller: _commentsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Repair Comments',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) => selectedServiceType == "Repair" &&
                        value!.isEmpty
                        ? 'Please enter comments'
                        : null,
                  ),

                const SizedBox(height: 16),

                // Alternate Contact
                TextFormField(
                  controller: _altContactPersonController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Alternate Contact Person',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (value) => value!.isEmpty
                      ? 'Please enter alternate contact person'
                      : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _altPhoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Alternate Contact Phone',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (value) => value!.isEmpty
                      ? 'Please enter alternate phone number'
                      : null,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      case 1:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pick a suitable date and time.",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TableCalendar(
                firstDay: firstDay,
                lastDay: lastDay,
                focusedDay: today,
                selectedDayPredicate: (day) => isSameDay(day, today),
                onDaySelected: _onDaySelected,
                availableGestures: AvailableGestures.all,

                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.red, // or any highlight color
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: Colors.white),
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: const TextStyle(color: Colors.white),
                  outsideTextStyle: const TextStyle(color: Colors.white38),
                ),

                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                ),

                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.white),
                  weekendStyle: TextStyle(color: Colors.white),
                ),
              ),


            ],
          ),
        );

      case 2:
        return Column(
          children: [
            const Center(
              child: Text(
                "Your appointment has been verified.",
                style: TextStyle(fontSize: 18, color: Colors.white),
                
              ),
              
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}
