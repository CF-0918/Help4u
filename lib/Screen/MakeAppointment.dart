import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:workshop_assignment/Provider/LocationProvider.dart';

class MakeAppointment extends StatefulWidget {
  const MakeAppointment({super.key});

  @override
  State<MakeAppointment> createState() => _MakeAppointmentState();
}

class _MakeAppointmentState extends State<MakeAppointment> {
  // Data
  final List<String> locations = [
    "Bukit Jalil Workshop",
    "Air Asia Workshop",
    "Abu Workshop",
    "Ah Meng Workshop",
    "Beli Workshop",
  ];

  final List<String> myCar = [
    "Honda Civic -123",
    "Honda City - 666",
    "Toyota Vios - 124",
    "RangeRover -123",
    "Perodua Myvi -111"
  ];

  // State
  late String carSelected;
// State (add these)
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  // State
  String? selectedTime;

  final List<String> timeSlots = const [
    '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM',
  ];



  // Scroll controllers for scrollbars
  final ScrollController _locationsCtl = ScrollController();
  final ScrollController _carsCtl = ScrollController();

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;   // highlight this day
      _focusedDay  = selectedDay;   // move calendar to it
    });
  }

  @override
  void initState() {
    super.initState();
    carSelected = myCar.first;
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay; // optional: preselect today
  }


  @override
  void dispose() {
    _locationsCtl.dispose();
    _carsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationName = context.watch<LocationProvider>().locationName;
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);
    final lastDay  = DateTime(today.year, today.month + 2, today.day);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
          title: const Text("Make Appointment",style:
          TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
          )
        ,)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current selection line
              Text("Selected location: $locationName"),

              const SizedBox(height: 16),

              // ===== Section: Choose Workshop =====
              const _SectionTitle(title: "Choose Workshop"),
              const SizedBox(height: 8),

              // Fixed-height scroll area for LOCATIONS
              SizedBox(
                height: 300,
                child: Scrollbar(
                  controller: _locationsCtl,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _locationsCtl,
                    primary: false,
                    itemCount: locations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final loc = locations[index];
                      return _RadioTileCard(
                        icon: Icons.location_on,
                        iconColor: const Color(0xFF9333EA),
                        title: loc,
                        subtitleTop: "123, Bangsar",
                        subtitleBottomIcon: Icons.access_time,
                        subtitleBottomText: "10:00 AM - 11:00 AM",
                        value: loc,
                        groupValue: locationName,
                        onChanged: (val) {
                          if (val != null) {
                            context.read<LocationProvider>().updateLocation(val);
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

              // Fixed-height scroll area for CARS
              SizedBox(
                height: 200, // adjust as needed
                child: Scrollbar(
                  controller: _carsCtl,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _carsCtl,
                    primary: false,
                    itemCount: myCar.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) {
                      final String car = myCar[i];
                      return _RadioTileCard(
                        icon: Icons.directions_car,                 // vehicle icon
                        iconColor: const Color(0xFF9333EA),
                        title: car,
                        subtitleTop: "Plate registered",
                        subtitleBottomIcon: Icons.directions,       // any small detail
                        subtitleBottomText: "Default driver",
                        value: car,
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

              SizedBox(height: 20,),
              _SectionTitle(title: "Pick A Date"),
              SizedBox(height: 5,),
              // Use this where you want the legend (Row or Wrap both fine)
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
                  // Tell the calendar which day is selected
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                  // Update selection + focus on tap
                  onDaySelected: _onDaySelected,

                  // Keep internal focus in sync when user swipes months
                  onPageChanged: (fd) {
                    _focusedDay = fd; // setState not required unless you show focused day elsewhere
                  },

                  // (Optional) nicer highlight styles
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

              SizedBox(height: 20,),
              // Legend/header
              Wrap(
                spacing: 8, // ✅ works on Wrap (not Row)
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
                      locationName, // ← from your provider
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: 10,),
                  // shows just YYYY-MM-DD, or "—" if null
                  Text(
                    "Date Picked: ${_selectedDay != null
                        ? _selectedDay!.toLocal().toString().split(' ')[0]
                        : '—'}",
                  )

                ],
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: timeSlots.map((t) {
                  final bool isSelected = selectedTime == t;
                  return ChoiceChip(
                    label: Text(
                      t,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    backgroundColor: const Color(0xFF1C1C1E),           // match your cards
                    selectedColor: const Color(0xFF9333EA),             // your purple
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF9333EA) : Colors.white24,
                        width: 1,
                      ),
                    ),
                    onSelected: (_) => setState(() => selectedTime = t),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),



            ],
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
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Reusable card-styled RadioListTile matching your location UI
class _RadioTileCard extends StatelessWidget {
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
          color: const Color(0xFF1C1C1E),               // same dark card
          borderRadius: BorderRadius.circular(12),
        ),
        child: RadioListTile<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          controlAffinity: ListTileControlAffinity.trailing,     // radio at right
          secondary: Container(                                // leading icon box
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
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

