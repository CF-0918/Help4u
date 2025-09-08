import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

import '../Repository/serviceReminder_repo.dart';
import '../models/serviceReminder.dart';

/// Brand colors (kept your vibe)
const _brandPurple = Color(0xFF9333EA);
const _cardBg = Color(0xFF171A21); // subtle dark
const _chipBg = Color(0xFF2A2F3A);

/// Status → color/label
Color _statusColor(ServiceReminderStatus s) => switch (s) {
  ServiceReminderStatus.active => Colors.blue,
  ServiceReminderStatus.done => Colors.green,
  ServiceReminderStatus.snoozed => Colors.indigo,
  ServiceReminderStatus.cancelled => Colors.grey,
};
String _statusLabel(ServiceReminderStatus s) => switch (s) {
  ServiceReminderStatus.active => 'Active',
  ServiceReminderStatus.done => 'Done',
  ServiceReminderStatus.snoozed => 'Snoozed',
  ServiceReminderStatus.cancelled => 'Cancelled',
};

String _fmtDate(DateTime d) =>
    "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";

enum _TabFilter { all, active, done, snoozed, cancelled }

class ServiceReminderPage extends StatefulWidget {
   ServiceReminderPage({super.key});
  final String currentUserId=AuthService().currentUser!.id;

  @override
  State<ServiceReminderPage> createState() => _ServiceReminderPageState();
}

class _ServiceReminderPageState extends State<ServiceReminderPage> {
  final _repo = ServiceReminderRepository();
  final _uuid = const Uuid();

  bool _loading = true;
  String? _error;
  List<ServiceReminder> _items = [];
  _TabFilter _tab = _TabFilter.all;
  String _query = '';

  String get _userId => widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repo.fetchForCurrentUser(_userId);
      rows.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      setState(() => _items = rows);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Derived list (filter + search) ----------
  List<ServiceReminder> get _visible {
    Iterable<ServiceReminder> list = _items;
    switch (_tab) {
      case _TabFilter.active:
        list = list.where((r) => r.status == ServiceReminderStatus.active);
        break;
      case _TabFilter.done:
        list = list.where((r) => r.status == ServiceReminderStatus.done);
        break;
      case _TabFilter.snoozed:
        list = list.where((r) => r.status == ServiceReminderStatus.snoozed);
        break;
      case _TabFilter.cancelled:
        list = list.where((r) => r.status == ServiceReminderStatus.cancelled);
        break;
      case _TabFilter.all:
        break;
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        final inNotes = (r.notes ?? '').toLowerCase().contains(q);
        final inPlate = r.vehiclePlate.toLowerCase().contains(q);
        final inType = r.serviceTypeId.toLowerCase().contains(q);
        return inNotes || inPlate || inType;
      });
    }
    return list.toList();
  }

  // ---------- Actions ----------
  Future<void> _add() async {
    final res = await _editDialog();
    if (res == null) return;
    final now = DateTime.now();
    final newReminder = ServiceReminder(
      id: _uuid.v4(),
      userId: _userId,
      vehiclePlate: res.vehiclePlate,
      serviceTypeId: res.serviceTypeId,
      nextDueDate: res.due,
      status: ServiceReminderStatus.active,
      notes: res.notes?.isEmpty == true ? null : res.notes,
      lastCompletedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    try {
      final created = await _repo.create(newReminder, includeId: true);
      setState(() => _items = [..._items, created]..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder added')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
    }
  }

  Future<void> _edit(ServiceReminder r) async {
    final res = await _editDialog(
      initialNotes: r.notes ?? '',
      initialPlate: r.vehiclePlate,
      initialTypeId: r.serviceTypeId,
      initialDue: r.nextDueDate,
    );
    if (res == null) return;
    final updated = r.copyWith(
      vehiclePlate: res.vehiclePlate,
      serviceTypeId: res.serviceTypeId,
      nextDueDate: res.due,
      notes: res.notes?.isEmpty == true ? null : res.notes,
      updatedAt: DateTime.now(),
    );
    try {
      final saved = await _repo.update(updated);
      final i = _items.indexWhere((x) => x.id == saved.id);
      if (i != -1) setState(() => _items[i] = saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  Future<void> _delete(ServiceReminder r) async {
    final ok = await _confirmDelete();
    if (ok != true) return;
    try {
      await _repo.delete(r.id);
      setState(() => _items.removeWhere((x) => x.id == r.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  Future<void> _markDone(ServiceReminder r) async {
    try {
      final saved = await _repo.markDone(r.id);
      final i = _items.indexWhere((x) => x.id == saved.id);
      if (i != -1) setState(() => _items[i] = saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as done')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _snooze(ServiceReminder r, {int days = 14}) async {
    try {
      final saved = await _repo.snoozeTo(r.id, r.nextDueDate.add(Duration(days: days)));
      final i = _items.indexWhere((x) => x.id == saved.id);
      if (i != -1) setState(() => _items[i] = saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Snoozed $days days')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _cancel(ServiceReminder r) async {
    try {
      final saved = await _repo.cancel(r.id);
      final i = _items.indexWhere((x) => x.id == saved.id);
      if (i != -1) setState(() => _items[i] = saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelled')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1217),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1217),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Service Reminder',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brandPurple,
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brandPurple))
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : RefreshIndicator(
        onRefresh: _load,
        color: _brandPurple,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _topBar()),
            SliverList.builder(
              itemCount: _visible.length,
              itemBuilder: (_, i) => _reminderCard(_visible[i]),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // --- Top bar: search + segmented chips
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          // Search
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search plate, type, notes…',
                hintStyle: TextStyle(color: Colors.white54),
                icon: Icon(Icons.search, color: Colors.white60),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Segmented chips
          Wrap(
            spacing: 8,
            children: [
              _segChip('All', _TabFilter.all),
              _segChip('Active', _TabFilter.active),
              _segChip('Done', _TabFilter.done),
              _segChip('Snoozed', _TabFilter.snoozed),
              _segChip('Cancelled', _TabFilter.cancelled),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _segChip(String label, _TabFilter me) {
    final selected = _tab == me;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _tab = me),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: _brandPurple,
      backgroundColor: _chipBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // --- Card
  Widget _reminderCard(ServiceReminder r) {
    final statusColor = _statusColor(r.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // left accent
            Container(
              width: 5,
              height: 110,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // title + actions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.car_repair, size: 18, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.notes?.isNotEmpty == true
                                ? r.notes!
                                : 'System\nGenerated Time for your next service!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 1.1,
                            ),
                          ),
                        ),
                        _statusPill(_statusLabel(r.status), statusColor),
                        const SizedBox(width: 6),
                        _iconBtn(Icons.edit, onTap: () => _edit(r)),
                        const SizedBox(width: 4),
                        _iconBtn(Icons.delete, onTap: () => _delete(r)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // meta rows
                    _metaRow('Plate', r.vehiclePlate),
                    _metaRow('Service', r.serviceTypeId),
                    _metaRow('Due', _fmtDate(r.nextDueDate)),
                    if (r.lastCompletedAt != null)
                      _metaRow('Last completed', _fmtDate(r.lastCompletedAt!)),

                    const SizedBox(height: 12),

                    // quick actions
                    Row(
                      children: [
                        _textBtn('Mark Done', icon: Icons.check, color: Colors.green,
                            onTap: r.status == ServiceReminderStatus.done ? null : () => _markDone(r)),
                        const SizedBox(width: 12),
                        _textBtn('Snooze 14d', icon: Icons.snooze, color: Colors.indigo,
                            onTap: r.status == ServiceReminderStatus.active ? () => _snooze(r, days: 14) : null),
                        const SizedBox(width: 12),
                        _textBtn('Cancel', icon: Icons.cancel, color: Colors.grey,
                            onTap: (r.status == ServiceReminderStatus.active ||
                                r.status == ServiceReminderStatus.snoozed)
                                ? () => _cancel(r)
                                : null),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, size: 18, color: Colors.white70),
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _textBtn(String text,
      {required IconData icon, required Color color, VoidCallback? onTap}) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: disabled ? Colors.white10 : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (disabled ? Colors.white24 : color.withOpacity(0.5))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: disabled ? Colors.white54 : color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: disabled ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C222B),
        title: const Text('Delete reminder?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    return ok ?? false;
  }

  // ---------- Dialog (Create/Edit) ----------
  Future<_EditValues?> _editDialog({
    String? initialNotes,
    String? initialPlate,
    String? initialTypeId,
    DateTime? initialDue,
  }) async {
    final formKey = GlobalKey<FormState>();
    final notesCtl = TextEditingController(text: initialNotes ?? '');
    final plateCtl = TextEditingController(text: initialPlate ?? '');
    final typeCtl = TextEditingController(text: initialTypeId ?? '');
    DateTime due = initialDue ?? DateTime.now();
    final dueCtl = TextEditingController(text: _fmtDate(due));

    final res = await showDialog<_EditValues>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C222B),
        title: const Text('Service Reminder'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: notesCtl,
                decoration: const InputDecoration(labelText: 'Notes / Subject'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: plateCtl,
                decoration: const InputDecoration(labelText: 'Vehicle Plate'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: typeCtl,
                decoration: const InputDecoration(labelText: 'Service Type ID'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dueCtl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Next Due Date',
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
                    due = picked;
                    dueCtl.text = _fmtDate(due);
                  }
                },
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandPurple),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                ctx,
                _EditValues(
                  notes: notesCtl.text.trim(),
                  vehiclePlate: plateCtl.text.trim(),
                  serviceTypeId: typeCtl.text.trim(),
                  due: due,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return res;
  }
}

// DTO used by the editor dialog
class _EditValues {
  final String notes;
  final String vehiclePlate;
  final String serviceTypeId;
  final DateTime due;
  _EditValues({
    required this.notes,
    required this.vehiclePlate,
    required this.serviceTypeId,
    required this.due,
  });
}
