import 'package:flutter/material.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();

  // Stored values (prefill these from your user model if you have one)
  String firstName = '';
  String lastName = '';
  String email = '';
  String phoneNumber = '';
  DateTime dateOfBirth = DateTime.now();
  String address = '';

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Focus nodes
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _dobFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();

  // Progress helpers
  int get _totalFields => 6;
  int get _filledCount => [
    _firstNameController.text,
    _lastNameController.text,
    _emailController.text,
    _phoneNumberController.text,
    _dateOfBirthController.text,
    _addressController.text,
  ].where((s) => s.trim().isNotEmpty).length;
  double get _completionRatio => _filledCount / _totalFields;

  void _wireProgressListeners() {
    for (final c in [
      _firstNameController,
      _lastNameController,
      _emailController,
      _phoneNumberController,
      _dateOfBirthController,
      _addressController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void initState() {
    super.initState();
    _wireProgressListeners();

    // Prefill from current state (or your user model)
    _firstNameController.text = firstName;
    _lastNameController.text = lastName;
    _emailController.text = email;
    _phoneNumberController.text = phoneNumber;
    _dateOfBirthController.text = _fmtDate(dateOfBirth);
    _addressController.text = address;
  }

  @override
  void dispose() {
    // Controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _dateOfBirthController.dispose();
    _addressController.dispose();
    // Focus nodes
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _dobFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dateOfBirth = picked;
        _dateOfBirthController.text = _fmtDate(picked);
      });
    }
  }

  void _focusFirstInvalid() {
    final emailRx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (_firstNameController.text.trim().isEmpty) {
      _firstNameFocus.requestFocus();
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _lastNameFocus.requestFocus();
      return;
    }
    if (_emailController.text.trim().isEmpty ||
        !emailRx.hasMatch(_emailController.text.trim())) {
      _emailFocus.requestFocus();
      return;
    }
    if (_phoneNumberController.text.trim().isEmpty ||
        _phoneNumberController.text.trim().length < 6) {
      _phoneFocus.requestFocus();
      return;
    }
    if (_dateOfBirthController.text.trim().isEmpty) {
      _dobFocus.requestFocus();
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _addressFocus.requestFocus();
      return;
    }
  }

  void _onSubmit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      _focusFirstInvalid();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors')),
      );
      return;
    }

    // Save from controllers (controller-driven pattern)
    setState(() {
      firstName = _firstNameController.text.trim();
      lastName = _lastNameController.text.trim();
      email = _emailController.text.trim();
      phoneNumber = _phoneNumberController.text.trim();
      address = _addressController.text.trim();
      // dateOfBirth is already stored as DateTime when picked
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _completionRatio.clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final leftFields = _totalFields - _filledCount;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Progress block (placed under the title to avoid overflow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: Colors.blue.shade100,
                        valueColor: AlwaysStoppedAnimation(
                          Color.lerp(Colors.red, Colors.green, ratio) ??
                              Colors.purpleAccent,
                        ),
                        semanticsLabel: "Profile completion",
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$percent% complete • $_filledCount/$_totalFields fields",
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (leftFields > 0)
                        Text(
                          "$leftFields more ${leftFields == 1 ? 'field' : 'fields'} to reach 100% and unlock the voucher",
                          style: const TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Fields
                  _textFormField(
                    label: "First Name",
                    controller: _firstNameController,
                    focusNode: _firstNameFocus,
                    keyBoardType: TextInputType.name,
                  ),
                  const SizedBox(height: 16),

                  _textFormField(
                    label: "Last Name",
                    controller: _lastNameController,
                    focusNode: _lastNameFocus,
                    keyBoardType: TextInputType.name,
                  ),
                  const SizedBox(height: 16),

                  _textFormField(
                    label: "Email",
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyBoardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final rx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      return rx.hasMatch(v.trim()) ? null : 'Invalid email';
                    },
                  ),
                  const SizedBox(height: 16),

                  _textFormField(
                    label: "Phone Number",
                    controller: _phoneNumberController,
                    focusNode: _phoneFocus,
                    keyBoardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 6) return 'Too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // DOB (read-only field that opens date picker)
                  GestureDetector(
                    onTap: _pickDob,
                    child: AbsorbPointer(
                      child: _textFormField(
                        label: "Date of Birth",
                        controller: _dateOfBirthController,
                        focusNode: _dobFocus,
                        keyBoardType: TextInputType.datetime,
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _textFormField(
                    label: "Address",
                    controller: _addressController,
                    focusNode: _addressFocus,
                    keyBoardType: TextInputType.multiline,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _onSubmit,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9333EA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }
}

/// Reusable TextFormField
Widget _textFormField({
  required String label,
  required TextEditingController controller,
  required FocusNode focusNode,
  required TextInputType keyBoardType,
  String? Function(String?)? validator,
  int maxLines = 1,
  Widget? suffixIcon,
}) {
  return TextFormField(
    focusNode: focusNode,
    controller: controller,
    validator:
    validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    keyboardType: keyBoardType,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        borderSide: BorderSide(color: Colors.purpleAccent),
      ),
      suffixIcon: suffixIcon,
      contentPadding:
      const EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
      labelStyle: const TextStyle(color: Colors.white),
    ),
  );
}
