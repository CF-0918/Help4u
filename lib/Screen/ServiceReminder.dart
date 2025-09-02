import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';

/// ---- Status logic (top-level) ----

enum ReminderStatus { overdue, today, upcoming, later, completed }

class _StatusMeta {
  final String label;
  final Color color;
  const _StatusMeta(this.label, this.color);
}

ReminderStatus calcStatus(DateTime dueDate, {bool completed = false}) {
  if (completed) return ReminderStatus.completed;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

  if (due.isBefore(today)) return ReminderStatus.overdue;
  if (due.isAtSameMomentAs(today)) return ReminderStatus.today;

  final days = due.difference(today).inDays;
  if (days <= 7) return ReminderStatus.upcoming;

  return ReminderStatus.later; // beyond 7 days
}

_StatusMeta statusMeta(ReminderStatus s) {
  switch (s) {
    case ReminderStatus.overdue:
      return const _StatusMeta('Overdue', Colors.red);
    case ReminderStatus.today:
      return const _StatusMeta('Due today', Colors.deepOrange);
    case ReminderStatus.upcoming:
      return const _StatusMeta('Upcoming', Colors.amber);
    case ReminderStatus.completed:
      return const _StatusMeta('Completed', Colors.green);
    case ReminderStatus.later:
      return _StatusMeta('Scheduled', Colors.blueGrey.shade600);
  }
}

/// Simple data model
class ReminderItem {
   String subjectTitle;
   String carName;
   String mileage; // keep string for display
   DateTime date;
  bool isCompleted;

  ReminderItem({
    required this.subjectTitle,
    required this.carName,
    required this.mileage,
    required this.date,
    this.isCompleted = false,
  });
}

/// ---- Page ----

class Servicereminder extends StatefulWidget {
  const Servicereminder({super.key});

  @override
  State<Servicereminder> createState() => _ServicereminderState();
}

class _ServicereminderState extends State<Servicereminder> {
  // Demo data — replace with your real data source
  final List<ReminderItem> _reminders = [
    ReminderItem(
      subjectTitle: "Service Reminder",
      carName: "Honda Civic",
      mileage: "12345",
      date: DateTime.now().subtract(const Duration(days: 1)), // overdue
    ),
    ReminderItem(
      subjectTitle: "Brake Check",
      carName: "Perodua Myvi",
      mileage: "50210",
      date: DateTime.now(), // today
    ),
    ReminderItem(
      subjectTitle: "Engine Oil",
      carName: "Toyota Vios",
      mileage: "68000",
      date: DateTime.now().add(const Duration(days: 3)), // upcoming
    ),
    ReminderItem(
      subjectTitle: "Tire Rotation",
      carName: "Proton X50",
      mileage: "30000",
      date: DateTime.now().add(const Duration(days: 20)), // later (>7)
    ),
    ReminderItem(
      subjectTitle: "Air Filter",
      carName: "Mazda 3",
      mileage: "41000",
      date: DateTime.now().subtract(const Duration(days: 10)),
      isCompleted: true, // completed
    ),
  ];

  int get _overdueCount => _reminders
      .where((r) => calcStatus(r.date, completed: r.isCompleted) == ReminderStatus.overdue)
      .length;

  int get _upcomingCount => _reminders
      .where((r) => calcStatus(r.date, completed: r.isCompleted) == ReminderStatus.upcoming)
      .length;

  int get _completedCount => _reminders
      .where((r) => calcStatus(r.date, completed: r.isCompleted) == ReminderStatus.completed)
      .length;

  List<ReminderItem> _filter(ReminderStatus? filter) {
    if (filter == null) return _reminders; // All
    return _reminders
        .where((r) => calcStatus(r.date, completed: r.isCompleted) == filter)
        .toList();
  }

  Future<Map<String, dynamic>?> _editDialog(ReminderItem item) async {
    final formKey = GlobalKey<FormState>();

    // Start with current values
    String subject = item.subjectTitle;
    String car     = item.carName;
    String mileage = item.mileage;
    DateTime due   = item.date;

    final mileageCtrl = TextEditingController(text: mileage);
    final dueCtrl     = TextEditingController(text: _fmtDate(due));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Edit Reminder'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: subject,
                      decoration: const InputDecoration(
                        labelText: 'Subject Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      onSaved: (v) => subject = v!.trim(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: car,
                      decoration: const InputDecoration(
                        labelText: 'Car',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Honda Civic', child: Text('Honda Civic')),
                        DropdownMenuItem(value: 'Perodua Myvi', child: Text('Perodua Myvi')),
                        DropdownMenuItem(value: 'Toyota Vios', child: Text('Toyota Vios')),
                      ],
                      onChanged: (v) => setLocal(() => car = v ?? car),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dueCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: due,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setLocal(() {
                            due = picked;
                            dueCtrl.text = _fmtDate(due);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: mileageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mileage',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      onSaved: (v) => mileage = v!.trim(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();

                    // ✅ Return the edited values to the caller
                    Navigator.of(ctx).pop({
                      'subject': subject,
                      'car': car,
                      'mileage': mileageCtrl.text.trim(),
                      'date': due,
                    });
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    mileageCtrl.dispose();
    dueCtrl.dispose();
    return result;
  }

  List<String> serviceTypes=["Engine Oil","Brake Check","Tire Rotation","Air Filter"];

  Future<Map<String, dynamic>?> _addServiceReminder(BuildContext context) async {
    final formKey = GlobalKey<FormState>();

    // initial values
    String subject = '';
    String car = 'Honda Civic';
    String type = 'Engine Oil';
    String mileage = '';
    DateTime due = DateTime.now();

    // sample options
    const serviceTypes = ['Engine Oil', 'Tyre Service', 'Air Filter', 'General'];
    const cars = ['Honda Civic', 'Perodua Myvi', 'Toyota Vios'];

    final mileageCtrl = TextEditingController(text: mileage);
    final dueCtrl = TextEditingController(text: _fmtDate(due)); // assumes you have _fmtDate

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Add Service Reminder'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subject
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Subject Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                      onSaved: (v) => subject = v!.trim(),
                    ),
                    const SizedBox(height: 12),

                    // Car
                    DropdownButtonFormField<String>(
                      value: car,
                      decoration: const InputDecoration(
                        labelText: 'Car',
                        border: OutlineInputBorder(),
                      ),
                      items: cars
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setLocal(() => car = v ?? car),
                    ),
                    const SizedBox(height: 12),

                    // Service type
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Service Type',
                        border: OutlineInputBorder(),
                      ),
                      items: serviceTypes
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setLocal(() => type = v ?? type),
                    ),
                    const SizedBox(height: 12),

                    // Due date (tap to pick)
                    TextFormField(
                      controller: dueCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDate: due,
                        );
                        if (picked != null) {
                          setLocal(() {
                            due = picked;
                            dueCtrl.text = _fmtDate(due);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Mileage
                    TextFormField(
                      controller: mileageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mileage',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                      onSaved: (v) => mileage = v!.trim(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    Navigator.of(ctx).pop({
                      'subject': subject,
                      'car': car,
                      'type': type,
                      'date': due,
                      'mileage': mileageCtrl.text.trim(),
                    });
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    mileageCtrl.dispose();
    dueCtrl.dispose();
    return result;
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // All, Overdue, Upcoming, Completed
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Service Reminder",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: FloatingActionButton(
            tooltip: "Add Service Reminder",
            shape: const CircleBorder(
              side: BorderSide(
                color: Color(0xFF9333EA), // purple outline
                width: 3,
              ),
            ),
            onPressed: () async {
              final res = await _addServiceReminder(context);
              if (res != null) {
                // handle result (e.g., setState to add new reminder)
              }
            },

            child: const Icon(Icons.add),
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _statusCard(
                      title: "Overdue",
                      count: _overdueCount,
                      icon: Icons.warning_amber_outlined,
                      bgColor: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statusCard(
                      title: "Upcoming",
                      count: _upcomingCount,
                      icon: Icons.upcoming,
                      bgColor: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statusCard(
                      title: "Completed",
                      count: _completedCount,
                      icon: Icons.check_circle,
                      bgColor: Colors.green.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tabs (not in AppBar)
              ButtonsTabBar(
                buttonMargin: const EdgeInsets.symmetric(horizontal: 5),
                splashColor: Colors.deepPurple,
                backgroundColor: const Color(0xFF9333EA),
                unselectedBackgroundColor: const Color(0xFF1F2937),
                unselectedLabelStyle: const TextStyle(color: Colors.white70),
                labelStyle:
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                labelSpacing: 20,
                radius: 24,
                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "Overdue"),
                  Tab(text: "Upcoming"),
                  Tab(text: "Completed"),
                ],
              ),

              const SizedBox(height: 8),

              // Views
              Expanded(
                child: TabBarView(
                  children: [
                    _reminderList(_filter(null)), // All
                    _reminderList(_filter(ReminderStatus.overdue)),
                    _reminderList(_filter(ReminderStatus.upcoming)),
                    _reminderList(_filter(ReminderStatus.completed)),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  /// ---- Lists & cards ----

  Widget _reminderList(List<ReminderItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text("No reminders"));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final r = items[i];
        return _serviceReminderCard(
          subjectTitle: r.subjectTitle,
          carName: r.carName,
          mileage: r.mileage,
          date: r.date,
          isCompleted: r.isCompleted,
          onMarkDone: r.isCompleted
              ? null
              : () {
            setState(() {
              r.isCompleted = true;
            });
          },
          onEdit: r.isCompleted
              ? null
              : () async {
            final res = await _editDialog(r); // pass current item

            if (res == null) return;
            setState(() {
              r.subjectTitle = res['subject'] as String;
              r.carName      = res['car'] as String;
              r.mileage      = res['mileage'] as String;
              r.date         = res['date'] as DateTime;
              // r.isCompleted stays the same (or set from res if you include it)
            });

          },
          onDelete: r.isCompleted
              ? null
              : () async {
            final confirm = await _deleteReminder();
            if (confirm) {
              setState(() {
                _reminders.remove(r); // safer than removeAt(i) if list is filtered
              });
              // Optional: feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder deleted')),
              );
            }
          },



        );
      },
    );
  }

  Future<bool> _deleteReminder() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // force user to choose
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok ?? false; // handle back button / null
  }


  Widget _serviceReminderCard({
    required String subjectTitle,
    required String carName,
    required String mileage,
    required DateTime date,
    bool isCompleted = false,
    VoidCallback? onMarkDone,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final text = Theme.of(context).textTheme;

    final status = calcStatus(date, completed: isCompleted);
    final meta = statusMeta(status);
    final accentColor = meta.color;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: accentColor, width: 3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.car_repair, color: accentColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectTitle,
                        style: text.titleMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        carName,
                        style: text.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _statusChip(meta.label, background: accentColor.withOpacity(0.12)),
                    const SizedBox(width: 12),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        tooltip: 'Delete',
                      ),
                  ],
                )


              ],
            ),

            const SizedBox(height: 12),

            // Meta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Text("Due: ${_fmtDate(date)}", style: text.bodySmall),
                ]),
                Row(children: [
                  const Icon(Icons.speed, size: 16),
                  const SizedBox(width: 6),
                  Text("Mileage: $mileage", style: text.bodySmall),
                ]),
              ],
            ),

            const SizedBox(height: 14),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMarkDone,
                    icon: const Icon(Icons.check),
                    label: Text(isCompleted ? "Completed" : "Mark as completed"),
                  ),
                ),
                const SizedBox(width: 10),
                (onEdit != null)
                    ? OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                )
                    : const SizedBox.shrink(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ---- Small helpers ----

  Widget _statusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color bgColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              "$count",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, {Color? background}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: background ?? Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }
}
