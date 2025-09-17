import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Models/Vehicle.dart';
import 'package:workshop_assignment/Repository/vehicle_repo.dart';

class MyVehicle extends StatefulWidget {
  const MyVehicle({super.key});

  @override
  State<MyVehicle> createState() => _MyVehicleState();
}

class _MyVehicleState extends State<MyVehicle> {
  final _repo = VehicleRepository();

  bool _loading = true;
  String? _error;
  List<Vehicle> _items = [];

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
      final rows = await _repo.fetchUserCars();
      setState(() => _items = rows);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final res = await _editDialog();
    if (res == null) return;

    final newVehicle = Vehicle(
      plateNo: res.plateNo,
      regNo: res.regNo,
      model: res.model,
      brand: res.brand,
      spec: res.spec,
      manYear: res.manYear,
      type: res.type,
      vehImage: res.vehImage,
      userID: Supabase.instance.client.auth.currentUser!.id,
    );

    try {
      final created = await _repo.create(newVehicle);
      setState(() => _items = [..._items, created]);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vehicle added')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _edit(Vehicle v) async {
    final res = await _editDialog(v: v);
    if (res == null) return;

    final updated = Vehicle(
      plateNo: res.plateNo,
      regNo: res.regNo,
      model: res.model,
      brand: res.brand,
      spec: res.spec,
      manYear: res.manYear,
      type: res.type,
      vehImage: res.vehImage,
      userID: v.userID, // keep same user
    );

    try {
      final saved = await _repo.update(updated);
      final i = _items.indexWhere((x) => x.plateNo == saved.plateNo);
      if (i != -1) setState(() => _items[i] = saved);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vehicle updated')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _delete(Vehicle v) async {
    final ok = await _confirmDelete();
    if (ok != true) return;
    try {
      await _repo.delete(v.plateNo);
      setState(() => _items.removeWhere((x) => x.plateNo == v.plateNo));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vehicle deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())), // will show our custom message hehehehe
      );
    }
  }


  Future<_EditVehicle?> _editDialog({Vehicle? v}) async {
    final formKey = GlobalKey<FormState>();
    final plateCtl = TextEditingController(text: v?.plateNo ?? '');
    final regnoCtl = TextEditingController(text: v?.regNo ?? '');
    final brandCtl = TextEditingController(text: v?.brand ?? '');
    final modelCtl = TextEditingController(text: v?.model ?? '');
    final specCtl = TextEditingController(text: v?.spec ?? '');
    final manyearCtl =
    TextEditingController(text: v?.manYear?.toString() ?? '');
    final typeCtl = TextEditingController(text: v?.type ?? '');
    final vehimageCtl = TextEditingController(text: v?.vehImage ?? '');

    final res = await showDialog<_EditVehicle>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(v == null ? 'Add Vehicle' : 'Edit Vehicle'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: plateCtl,
                  decoration: const InputDecoration(labelText: 'Plate No'),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: regnoCtl,
                  decoration:
                  const InputDecoration(labelText: 'Registration No'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: brandCtl,
                  decoration: const InputDecoration(labelText: 'Brand'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: modelCtl,
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: specCtl,
                  decoration: const InputDecoration(labelText: 'Spec'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: manyearCtl,
                  decoration:
                  const InputDecoration(labelText: 'Manufacture Year'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: typeCtl,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: vehimageCtl,
                  decoration:
                  const InputDecoration(labelText: 'Vehicle Image URL'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(
                ctx,
                _EditVehicle(
                  plateNo: plateCtl.text.trim(),
                  regNo: regnoCtl.text.trim().isEmpty
                      ? null
                      : regnoCtl.text.trim(),
                  brand: brandCtl.text.trim(),
                  model: modelCtl.text.trim(),
                  spec: specCtl.text.trim().isEmpty
                      ? null
                      : specCtl.text.trim(),
                  manYear: int.tryParse(manyearCtl.text.trim()),
                  type: typeCtl.text.trim().isEmpty
                      ? null
                      : typeCtl.text.trim(),
                  vehImage: vehimageCtl.text.trim().isEmpty
                      ? null
                      : vehimageCtl.text.trim(),
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

  Future<bool> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) => _vehicleCard(_items[i]),
      ),
    );
  }

  Widget _vehicleCard(Vehicle v) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: v.vehImage != null
            ? Image.network(v.vehImage!,
            width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.directions_car),
        title: Text('${v.brand} ${v.model} (${v.manYear ?? 'N/A'})'),
        subtitle: Text(
            '${v.spec ?? ''} • ${v.plateNo} • ${v.regNo ?? ''} • ${v.type ?? ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _edit(v),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _delete(v),
            ),
          ],
        ),
      ),
    );
  }
}

/// DTO for dialog
class _EditVehicle {
  final String plateNo;
  final String? regNo;
  final String brand;
  final String model;
  final String? spec;
  final int? manYear;
  final String? type;
  final String? vehImage;

  _EditVehicle({
    required this.plateNo,
    this.regNo,
    required this.brand,
    required this.model,
    this.spec,
    this.manYear,
    this.type,
    this.vehImage,
  });
}
