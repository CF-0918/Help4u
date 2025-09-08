import 'package:flutter/material.dart';
import 'package:workshop_assignment/Models/UserProfile.dart';
import 'package:workshop_assignment/Repository/user_repo.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();

  final _userRepo = UserRepository();
  final _auth = AuthService();

  // controllers
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _dobC = TextEditingController();

  // focus
  final _nameF = FocusNode();
  final _emailF = FocusNode();
  final _phoneF = FocusNode();
  final _dobF = FocusNode();

  // state
  String _userId = '';
  String _gender = ''; // "Male" | "Female" | "Other"
  int _points = 0;
  String _memberLevel = '-';
  DateTime? _dob; // optional

  bool _loading = true;
  bool _saving = false;

  UserProfile? _current;

  // Can these be edited right now?
  // They’re true only if the loaded profile had them empty.
  bool _emailEditable = false;
  bool _phoneEditable = false;
  bool _dobEditable = false;

  // ---- Progress meter: 5 fields (name, email, phone, gender, dob) ----
  int get _totalFields => 5;
  int get _filledCount {
    int c = 0;
    if (_nameC.text.trim().isNotEmpty) c++;
    if (_emailC.text.trim().isNotEmpty) c++;
    if (_phoneC.text.trim().isNotEmpty) c++;
    if (_gender.trim().isNotEmpty) c++;
    if (_dob != null) c++;
    return c;
  }
  double get _completionRatio => _filledCount / _totalFields;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameC, _emailC, _phoneC]) {
      c.addListener(() => setState(() {}));
    }
    _load();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _dobC.dispose();
    _nameF.dispose();
    _emailF.dispose();
    _phoneF.dispose();
    _dobF.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final uid = _auth.currentUserId;
      if (uid == null) throw Exception('No logged-in user');
      _userId = uid;

      final profile = await _userRepo.fetchUserDetails(uid);
      if (profile == null) throw Exception('Profile not found');

      _current = profile;

      // Fill
      _nameC.text = profile.name;
      _emailC.text = profile.email;
      _phoneC.text = profile.phone;
      _gender = profile.gender ?? '';
      _points = profile.points;
      _memberLevel = profile.memberLevel;

      _dob = profile.dob;
      _dobC.text = _dob == null ? '' : _fmtDate(_dob!);

      // Editability flags: only if originally empty/null
      _emailEditable = profile.email.trim().isEmpty;
      _phoneEditable = profile.phone.trim().isEmpty;
      _dobEditable = profile.dob == null;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _focusFirstInvalid() {
    final emailRx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (_nameC.text.trim().isEmpty) return _nameF.requestFocus();
    if (_emailEditable) {
      if (_emailC.text.trim().isEmpty || !emailRx.hasMatch(_emailC.text.trim())) {
        return _emailF.requestFocus();
      }
    }
    if (_phoneEditable) {
      if (_phoneC.text.trim().isEmpty || _phoneC.text.trim().length < 6) {
        return _phoneF.requestFocus();
      }
    }
    if (_gender.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gender')),
      );
    }
  }

  Future<void> _pickDob() async {
    if (!_dobEditable) return; // only if not set before
    final initial = DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobC.text = _fmtDate(picked);
      });
    }
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || _gender.trim().isEmpty) {
      _focusFirstInvalid();
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = UserProfile(
        uid: _current?.uid ?? _userId,
        name: _nameC.text.trim(),
        // email/phone: keep existing if they were non-editable,
        // otherwise use what user typed this session.
        email: _emailEditable ? _emailC.text.trim() : (_current?.email ?? ''),
        phone: _phoneEditable ? _phoneC.text.trim() : (_current?.phone ?? ''),
        isVerified: _current?.isVerified ?? false,
        status: _current?.status ?? 'active',
        gender: _gender.isEmpty ? null : _gender,
        updatedAt: DateTime.now(),
        // DOB: set only if editable; once saved, next load it will be locked
        dob: _dobEditable ? _dob : (_current?.dob),

        profilePicUrl: _current?.profilePicUrl,
        points: _current?.points ?? 0,
        memberLevel: _current?.memberLevel ?? 'Junior',
      );

      await _userRepo.updateUserProfile(user: updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ratio = _completionRatio.clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final left = _totalFields - _filledCount;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Personal Information',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  backgroundColor: Colors.blue.shade100,
                  valueColor: AlwaysStoppedAnimation(
                    Color.lerp(Colors.red, Colors.green, ratio) ?? Colors.purpleAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$percent% complete • $_filledCount/$_totalFields fields',
                    style: const TextStyle(color: Colors.white)),
                if (left > 0)
                  Text(
                    '$left more ${left == 1 ? 'field' : 'fields'} to reach 100%',
                    style: const TextStyle(color: Colors.white70),
                  ),

                const SizedBox(height: 24),

                _editableField(
                  label: 'Name',
                  controller: _nameC,
                  focusNode: _nameF,
                  type: TextInputType.name,
                ),
                const SizedBox(height: 16),

                // Email (editable only if empty previously)
                _lockableField(
                  label: 'Email',
                  controller: _emailC,
                  focusNode: _emailF,
                  enabled: _emailEditable,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (!_emailEditable) return null; // locked; don't validate
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final rx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    return rx.hasMatch(v.trim()) ? null : 'Invalid email';
                  },
                  helper: _emailEditable
                      ? 'You can set your email once. It will be locked after saving.'
                      : 'Email is locked. Contact support to change.',
                ),
                const SizedBox(height: 16),

                // Phone (editable only if empty previously)
                _lockableField(
                  label: 'Phone',
                  controller: _phoneC,
                  focusNode: _phoneF,
                  enabled: _phoneEditable,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (!_phoneEditable) return null; // locked
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 6) return 'Too short';
                    return null;
                  },
                  helper: _phoneEditable
                      ? 'You can set your phone once. It will be locked after saving.'
                      : 'Phone number is locked. Contact support to change.',
                ),
                const SizedBox(height: 16),

                // Gender dropdown (always editable)
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      borderSide: BorderSide(color: Colors.purpleAccent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _gender.isEmpty ? null : _gender,
                      hint: const Text('Select gender', style: TextStyle(color: Colors.white70)),
                      dropdownColor: const Color(0xFF1F2937),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? ''),
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.white70,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // DOB (editable only if not set)
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (optional)',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      borderSide: BorderSide(color: Colors.purpleAccent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AbsorbPointer(
                          absorbing: true,
                          child: TextFormField(
                            controller: _dobC,
                            focusNode: _dobF,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: _dobEditable
                                  ? 'Tap the calendar to set your DOB'
                                  : 'DOB is locked',
                              hintStyle: const TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _dobEditable ? 'Pick date' : 'DOB locked',
                        onPressed: _dobEditable ? _pickDob : null,
                        icon: Icon(
                          _dobEditable ? Icons.calendar_today : Icons.lock_outline,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_dobEditable) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'You can set your DOB once. It will be locked after saving.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 24),

                // read-only stats
                Row(
                  children: [
                    Expanded(
                      child: _statCard(title: 'Points', value: '$_points'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(title: 'Member Level', value: _memberLevel),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

// Generic editable text field
Widget _editableField({
  required String label,
  required TextEditingController controller,
  required FocusNode focusNode,
  required TextInputType type,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: type,
    validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        borderSide: BorderSide(color: Colors.purpleAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
  );
}

// Lockable (enabled when previously empty; otherwise disabled)
Widget _lockableField({
  required String label,
  required TextEditingController controller,
  required FocusNode focusNode,
  required bool enabled,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  String? helper,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: !enabled,
        keyboardType: keyboardType,
        validator: enabled
            ? (validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)
            : null,
        style: TextStyle(color: enabled ? Colors.white : Colors.white54),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            borderSide: BorderSide(color: Colors.purpleAccent),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: enabled
              ? null
              : const Icon(Icons.lock_outline, color: Colors.white54),
        ),
      ),
      if (helper != null) ...[
        const SizedBox(height: 6),
        Text(helper, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    ],
  );
}

Widget _statCard({required String title, required String value}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF1F2937),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}
