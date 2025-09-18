import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:workshop_assignment/Models/Outlet.dart';
import 'package:workshop_assignment/Models/ServiceType.dart';
import 'package:workshop_assignment/Models/Vehicle.dart';
import 'package:workshop_assignment/Provider/LocationProvider.dart';
import 'package:workshop_assignment/Repository/appointment_repo.dart';
import 'package:workshop_assignment/Repository/outlet_repo.dart';
import 'package:workshop_assignment/Repository/serviceType_repo.dart';
import 'package:workshop_assignment/Repository/vehicle_repo.dart';
import 'package:workshop_assignment/Screen/MyVehicle.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';
import 'package:flutter/services.dart';

import 'EditProfile.dart';


class MakeAppointment extends StatefulWidget {
  const MakeAppointment({super.key});

  @override
  State<MakeAppointment> createState() => _MakeAppointmentState();
}

class _MakeAppointmentState extends State<MakeAppointment> {
  // Data
  List<Outlet> outlets = [];
  List<Vehicle> cars = [];
  List<ServiceType> serviceTypes = [];

  // State
  String? carSelected;
  String? serviceTypeSelected;

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  String? selectedTime;
  bool _isLoading = true;
  bool _isBooking = false; // New state to handle booking
  final int maxSlots = 5; // Maximum appointments per slot
  Map<String, int> availableSlots = {}; // New state variable for available slots counts

  final List<String> timeSlots = const [
    '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM',
  ];

  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  final FocusNode milleageFocusNode = FocusNode();

  // Scroll controllers for scrollbars
  final ScrollController _locationsCtl = ScrollController();
  final ScrollController _carsCtl = ScrollController();
  final _mileageController = TextEditingController();

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = selectedDay;
    });
    // Fetch new availability data when the date changes
    _fetchAvailability(context.read<LocationProvider>().locationId!, selectedDay);
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _initData();
  }

  Future<void> _initData() async {
    await _fetchOutlets();
    await _fetchUserCars();
    await _fetchServiceType();
    setState(() {
      _isLoading = false;
      if (cars.isNotEmpty) {
        carSelected = cars.first.plateNo;
      }
      if (serviceTypes.isNotEmpty) {
        serviceTypeSelected = serviceTypes.first.id;
      }
    });
    // Initial fetch for availability
    _fetchAvailability(context.read<LocationProvider>().locationId!, _selectedDay!);
  }

  Future<void> _fetchOutlets() async {
    try {
      final fetchedOutlets = await OutletRepo().fetchOutlets(status: "active");
      outlets = fetchedOutlets;
    } catch (e) {
      debugPrint("Failed to fetch outlets: $e");
    }
  }

  Future<void> _fetchUserCars() async {
    try {
      List<Vehicle> fetchedCars = await VehicleRepository().fetchUserCars();
      cars = fetchedCars;
    } catch (e) {
      debugPrint("Failed to fetch cars: $e");
    }
  }
  Future<void> _fetchServiceType() async {
    try {
      List<ServiceType> fetchedServiceTypes = await ServiceTypeRepository().fetchServiceTypes();
      serviceTypes = fetchedServiceTypes;
    } catch (e) {
      debugPrint("Failed to fetch service types: $e");
    }
  }

  // Fetches slot availability for a given date and location.
  Future<void> _fetchAvailability(String location, DateTime date) async {
    final AppointmentRepository repo = AppointmentRepository();
    //booking id , booking time "9 :00 AM"
    final List<Map<String, dynamic>> bookings = await repo.fetchBookingsForDateAndOutlet(
      outletID: location,
      bookingDate: date,
    );

    // Calculate the count of bookings for each time slot
    final Map<String, int> slotCounts = {};
    for (var slot in timeSlots) {
      slotCounts[slot] = 0;
    }
    for (var booking in bookings) {
      final time = booking['bookingtime'] as String;
      if (slotCounts.containsKey(time)) {
        slotCounts[time] = slotCounts[time]! + 1;
      }
    }

    setState(() {
      availableSlots = slotCounts;
    });
  }

  // Handles the booking submission
  Future<void> _submitAppointment() async {
    // The main form key validation is sufficient.
    if (_formKey.currentState?.validate() ?? false) {
      // Check if all fields are selected
      if (carSelected == null || serviceTypeSelected == null || selectedTime == null || _selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields.')),
        );
        return;
      }
      setState(() => _isBooking = true);

      try {
        final AppointmentRepository repo = AppointmentRepository();
        await repo.createAppointment(
          outletID: context.read<LocationProvider>().locationId!,
          vehiclePlateNo: carSelected!,
          serviceTypeID: serviceTypeSelected!,
          mileage: int.parse(_mileageController.text),
          bookingDate: _selectedDay!,
          bookingTime: selectedTime!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
        // Navigate back to the previous page (AppointmentsTab)
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to book appointment. Please try again.')),
        );
      } finally {
        setState(() => _isBooking = false);
      }
    } else {
      // If validation fails, request focus on the mileage field
      milleageFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _locationsCtl.dispose();
    _carsCtl.dispose();
    _mileageController.dispose();
    milleageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationId = context.watch<LocationProvider>().locationId;
    final locationDisplayName = outlets.firstWhere(
          (outlet) => outlet.outletID == locationId,
      orElse: () => Outlet(
        outletID: locationId!,
        outletName: 'Unknown Location',
        outletAddress: '',
        operationDay: '',
        latitude: 123,
        longitude: 123,
      ),
    ).outletName;

    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);
    final lastDay = DateTime(today.year, today.month + 2, today.day);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Make Appointment",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selected location: $locationDisplayName"),

                const SizedBox(height: 16),

                // ===== Section: Choose Workshop =====
                const _SectionTitle(title: "Choose Workshop"),
                const SizedBox(height: 8),

                SizedBox(
                  height: 300,
                  child: Scrollbar(
                    controller: _locationsCtl,
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: _locationsCtl,
                      primary: false,
                      itemCount: outlets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final outlet = outlets[index];
                        return _RadioTileCard(
                          icon: Icons.location_on,
                          iconColor: const Color(0xFF9333EA),
                          title: outlet.outletName,
                          subtitleTop: outlet.outletAddress??"Not available",
                          subtitleBottomIcon: Icons.access_time,
                          subtitleBottomText: outlet.operationDay??"Not available",
                          value: outlet.outletID,
                          groupValue: context.read<LocationProvider>().locationId,
                          onChanged: (val) {
                            if (val != null) {
                              context.read<LocationProvider>().updateLocation(val);
                              // Fetch new availability data when location changes
                              _fetchAvailability(val, _selectedDay!);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ===== Section: Choose Vehicle =====
                const _SectionTitle(title: "Choose Vehicle"),
                const SizedBox(height: 8),

                // Inside your HomeTab widget's build method or a relevant section
                cars.isEmpty
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "No vehicles found, please add one in the profile tab.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MyVehicle())).then(
                              (_) => _fetchUserCars().then((_) {
                            if (cars.isNotEmpty && carSelected == null) {
                              setState(() {
                                carSelected = cars.first.plateNo;
                              });
                            }
                          })
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Add Vehicle"),
                    ),
                  ],
                )
                    :
                SizedBox(
                  height: 200,
                  child: Scrollbar(
                    controller: _carsCtl,
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: _carsCtl,
                      primary: false,
                      itemCount: cars.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, i) {
                        final vehicle = cars[i];
                        final String carTitle = "${vehicle.brand} ${vehicle.model} (${vehicle.plateNo})";
                        return _RadioTileCard(
                          image:vehicle.vehImage,
                          icon: Icons.directions_car,
                          iconColor: const Color(0xFF9333EA),
                          title: carTitle,
                          subtitleTop: vehicle.type??"Not available",
                          subtitleBottomIcon: Icons.calendar_today,
                          subtitleBottomText: "Manufacturer Year: ${vehicle.manYear?.toString() ?? "N/A"}",
                          value: vehicle.plateNo,
                          groupValue: carSelected,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => carSelected = value);
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ===== Section: Enter Mileage =====
                const _SectionTitle(title: "Enter Car Mileage (KM)"),
                const SizedBox(height: 8),
                TextFormField(
                  focusNode: milleageFocusNode,
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Car Mileage',
                    hintText: 'e.g., 12000',
                    labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the mileage';
                    }
                    return null;
                  },
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 20),
                const _SectionTitle(title: "Select Service Type"),
                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: serviceTypeSelected,
                  decoration: InputDecoration(
                    labelText: 'Service Type',
                    labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: const Color(0xFF1C1C1E),
                  items: serviceTypes.map((service) {
                    return DropdownMenuItem<String>(
                      value: service.id,
                      child: Text(
                        '${service.name} - RM${service.price?.toStringAsFixed(2) ?? "N/A"}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      serviceTypeSelected = value;
                    });
                  },
                ),

                const SizedBox(height: 20),
                const _SectionTitle(title: "Pick A Date"),
                const SizedBox(height: 5),

                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: const [
                    _LegendItem(color: Color(0xFF9333EA), label: 'Selected date'),
                    _LegendItem(color: Colors.purpleAccent, label: 'Today'),
                  ],
                ),

                SizedBox(
                  width: double.infinity,
                  child: TableCalendar(
                    locale: "en_US",
                    rowHeight: 43,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    focusedDay: _focusedDay,
                    firstDay: firstDay,
                    lastDay: lastDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    onPageChanged: (fd) {
                      _focusedDay = fd;
                    },
                    calendarStyle: const CalendarStyle(
                      isTodayHighlighted: true,
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF9333EA),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      "Available time for",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        locationDisplayName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Date Picked: ${_selectedDay != null ? _selectedDay!.toLocal().toString().split(' ')[0] : '—'}",
                    )
                  ],
                ),

                const SizedBox(height: 20),

                Center(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: timeSlots.map((t) {
                      // Get current time and date-only for comparison
                      final DateTime now = DateTime.now();
                      final DateTime todayDateOnly = DateTime(now.year, now.month, now.day);
                      final List<String> timeParts = t.split(' ');
                      final List<String> hourMinute = timeParts[0].split(':');
                      int hour = int.parse(hourMinute[0]);
                      final int minute = int.parse(hourMinute[1]);
                      if (timeParts[1] == 'PM' && hour != 12) {
                        hour += 12;
                      }
                      if (timeParts[1] == 'AM' && hour == 12) {
                        hour = 0;
                      }

                      final DateTime slotDateTime = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, hour, minute);

                      // A slot is "time passed" if:
                      // 1. The selected day is a previous day.
                      // 2. OR, if the selected day is today, and the slot's hour is before the current hour.
                      final bool isTimePassed = _selectedDay!.isBefore(todayDateOnly) || (isSameDay(_selectedDay, todayDateOnly) && slotDateTime.hour < now.hour);

                      final int bookingsForSlot = availableSlots[t] ?? 0;
                      final int slotsLeft = maxSlots - bookingsForSlot;
                      final bool isSelected = selectedTime == t;
                      final bool isFullyBooked = slotsLeft <= 0;
                      final bool isChipDisabled = isFullyBooked || isTimePassed;

                      final Color labelColor = isSelected
                          ? Colors.white
                          : isChipDisabled
                          ? Colors.grey[600]! // Change color for disabled chips
                          : Colors.white70;

                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t),
                            const SizedBox(width: 8),
                            Text(
                              isFullyBooked ? 'Fully Booked' : isTimePassed ? 'Time Passed' : '(${slotsLeft}/$maxSlots)',
                              style: TextStyle(
                                fontSize: 10,
                                color: labelColor,
                              ),
                            ),
                          ],
                        ),
                        labelStyle: TextStyle(
                          color: labelColor,
                          fontWeight: FontWeight.w600,
                        ),
                        selected: isSelected,
                        showCheckmark: false,
                        backgroundColor: const Color(0xFF1C1C1E),
                        selectedColor: const Color(0xFF9333EA),
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF9333EA) : isChipDisabled ? Colors.grey[800]! : Colors.white24,
                            width: 1,
                          ),
                        ),
                        onSelected: isChipDisabled
                            ? null // Disable the chip if fully booked or time has passed
                            : (_) => setState(() => selectedTime = t),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _submitAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isBooking
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : const Text(
                      'Book Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable section title
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioTileCard extends StatelessWidget {
  final String? image; // vehicle image URL (optional)
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitleTop;
  final IconData subtitleBottomIcon;
  final String subtitleBottomText;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const _RadioTileCard({
    this.image,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitleTop,
    required this.subtitleBottomIcon,
    required this.subtitleBottomText,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: RadioListTile<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          controlAffinity: ListTileControlAffinity.trailing,

          // ✅ Secondary widget: vehicle image or fallback icon
          secondary: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (image != null && image!.isNotEmpty)
                ? Image.network(
              image!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _fallbackIcon();
              },
            )
                : _fallbackIcon(),
          ),

          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                subtitleTop,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(subtitleBottomIcon, size: 14, color: iconColor),
                  const SizedBox(width: 4),
                  Text(
                    subtitleBottomText,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Helper: fallback profile-style icon
  Widget _fallbackIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: iconColor),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
