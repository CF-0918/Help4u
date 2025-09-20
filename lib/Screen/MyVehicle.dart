import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Models/Vehicle.dart';
import 'package:workshop_assignment/Repository/vehicle_repo.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Car brands & models (Malaysia common)
const Map<String, List<String>> carBrandsModels = {
  "Perodua": [
    "Myvi","Axia","Bezza","Alza","Ativa",
    "Kancil","Viva","Kelisa","Kenari","Nautica",
  ],
  "Proton": [
    "Saga","Persona","Iriz","Exora","X50",
    "X70","Preve","Suprima S","Inspira","Perdana",
  ],
  "Toyota": [
    "Vios","Yaris","Corolla Altis","Camry","Hilux",
    "Fortuner","Avanza","Innova","Rush","Harrier",
  ],
  "Honda": [
    "City","Civic","Accord","CR-V","HR-V",
    "Jazz","BR-V","WR-V","Odyssey","Pilot",
  ],
  "Nissan": [
    "Almera","Teana","Sylphy","X-Trail","Navara",
    "Serena","Livina","Murano","Juke","Latio",
  ],
};

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

    try {
      // Step 1: check if this vehicle already exists
      final existing = await _repo.fetchByPlateNo(res.plateNo);

      if (existing != null && existing.status == "Inactive") {
        // Step 2: confirm with user
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Vehicle exists"),
            content: const Text(
                "This vehicle already exists in your records but is inactive.\n\n"
                    "Do you want to reactivate it? (The previous data will be restored, "
                    "not replaced by your new input.)"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Reactivate")),
            ],
          ),
        );

        if (confirm == true) {
          await _repo.reactivate(existing.plateNo);
          setState(() => _items = [..._items, existing.copyWith(status: "Active")]);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle reactivated')),
          );
        }
        return;
      }

      // Step 3: create new vehicle if not existing
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
        status: "Active",
      );

      final created = await _repo.create(newVehicle);
      setState(() => _items = [..._items, created]);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vehicle saved')));
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
      userID: v.userID,
      status: "Active",
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
      await _repo.deactivate(v.plateNo);
      setState(() => _items.removeWhere((x) => x.plateNo == v.plateNo));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vehicle removed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// Add/Edit dialog
  Future<_EditVehicle?> _editDialog({Vehicle? v}) async {
    final formKey = GlobalKey<FormState>();
    final plateCtl = TextEditingController(text: v?.plateNo ?? '');
    final regnoCtl = TextEditingController(text: v?.regNo ?? '');
    final specCtl = TextEditingController(text: v?.spec ?? '');
    final manyearCtl = TextEditingController(text: v?.manYear?.toString() ?? '');
    final typeCtl = TextEditingController(text: v?.type ?? '');

    String? selectedBrand = v?.brand;
    String? selectedModel = v?.model;

    String? uploadedUrl = v?.vehImage;

    final picker = ImagePicker();

    Future<void> _pickAndUploadImage() async {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final supabase = Supabase.instance.client;
      final fileBytes = await picked.readAsBytes();
      final userId = supabase.auth.currentUser?.id;

      final filePath =
          "car/${plateCtl.text}_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg";

      try {
        await supabase.storage
            .from("Help4uBucket")
            .uploadBinary(filePath, fileBytes,
            fileOptions: const FileOptions(upsert: true));

        uploadedUrl =
            supabase.storage.from("Help4uBucket").getPublicUrl(filePath);

        setState(() {}); // refresh preview
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    }

    final res = await showDialog<_EditVehicle>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
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

                  // Brand Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedBrand,
                    decoration: const InputDecoration(labelText: 'Brand'),
                    items: carBrandsModels.keys
                        .map<DropdownMenuItem<String>>(
                          (b) => DropdownMenuItem<String>(
                        value: b,
                        child: Text(b),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      setLocal(() {
                        selectedBrand = val;
                        selectedModel = null;
                      });
                    },
                    validator: (v) =>
                    v == null ? 'Please select a brand' : null,
                  ),
                  const SizedBox(height: 12),

                  // Model Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedModel,
                    decoration: const InputDecoration(labelText: 'Model'),
                    items: (selectedBrand != null
                        ? carBrandsModels[selectedBrand] ?? []
                        : [])
                        .map<DropdownMenuItem<String>>(
                          (m) => DropdownMenuItem<String>(
                        value: m,
                        child: Text(m),
                      ),
                    )
                        .toList(),
                    onChanged: (val) => setLocal(() => selectedModel = val),
                    validator: (v) =>
                    v == null ? 'Please select a model' : null,
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
                  const SizedBox(height: 20),

                  if (uploadedUrl != null)
                    Image.network(uploadedUrl!,
                        width: 100, height: 100, fit: BoxFit.cover),

                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: () async {
                      await _pickAndUploadImage();
                      setLocal(() {});
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Vehicle Image"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
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
                    brand: selectedBrand!,
                    model: selectedModel!,
                    spec: specCtl.text.trim().isEmpty
                        ? null
                        : specCtl.text.trim(),
                    manYear: int.tryParse(manyearCtl.text.trim()),
                    type: typeCtl.text.trim().isEmpty
                        ? null
                        : typeCtl.text.trim(),
                    vehImage: uploadedUrl,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    return res;
  }

  Future<bool> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content:
        const Text('This will remove the vehicle from your active list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
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
