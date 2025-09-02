import 'package:flutter/material.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  bool get _lenOk => _newCtrl.text.trim().length >= 8;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(() => setState(() {})); // refresh “rules” live
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    // TODO: call your API here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Colors from your palette / screenshot
    const bgField = Color(0xFF111827); // deep slate
    const blue = Color(0xFF60A5FA);    // #60A5FA
    const panel = Colors.black;        // black panel background
    const border = Color(0xFF374151);  // slate border
    const label = Colors.white;
    const hint = Color(0xFF9CA3AF);    // gray-400
    const success = Color(0xFF22C55E); // green-500
    const avatarBg = Color(0xFF1F2937); // #1F2937

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Change Password",
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Lock avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: avatarBg,
                    child: const Icon(Icons.lock, color: blue, size: 40),
                  ),
                  const SizedBox(height: 16),

                  // Intro text
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Your new password must be different from your current password and contain at least 8 characters.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Current password
                  _passwordField(
                    label: "Current Password",
                    controller: _currentCtrl,
                    focusNode: _currentFocus,
                    bgField: bgField,
                    border: border,
                    labelColor: label,
                    hintColor: hint,
                    obscure: !_showCurrent,
                    toggle: () => setState(() => _showCurrent = !_showCurrent),
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_newFocus),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  // New password
                  _passwordField(
                    label: "New Password",
                    controller: _newCtrl,
                    focusNode: _newFocus,
                    bgField: bgField,
                    border: border,
                    labelColor: label,
                    hintColor: hint,
                    obscure: !_showNew,
                    toggle: () => setState(() => _showNew = !_showNew),
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_confirmFocus),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Required';
                      if (t.length < 8) return 'Must be at least 8 characters';
                      if (t == _currentCtrl.text.trim()) {
                        return 'New password must be different from current';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Confirm password
                  _passwordField(
                    label: "Confirm New Password",
                    controller: _confirmCtrl,
                    focusNode: _confirmFocus,
                    bgField: bgField,
                    border: border,
                    labelColor: label,
                    hintColor: hint,
                    obscure: !_showConfirm,
                    toggle: () =>
                        setState(() => _showConfirm = !_showConfirm),
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Required';
                      if (t != _newCtrl.text.trim()) return 'Passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Rules block
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "New password must contain:",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              _lenOk ? Icons.check_circle : Icons.circle_outlined,
                              size: 18,
                              color: _lenOk ? success : Colors.white38,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "At least 8 characters",
                              style: TextStyle(
                                  color: _lenOk ? Colors.white : Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Update Password",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
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
}

// Reusable password field styled like your screenshot
Widget _passwordField({
  required String label,
  required TextEditingController controller,
  required FocusNode focusNode,
  required Color bgField,
  required Color border,
  required Color labelColor,
  required Color hintColor,
  required bool obscure,
  required VoidCallback toggle,
  String? Function(String?)? validator,
  ValueChanged<String>? onSubmitted,
}) {
  return TextFormField(
    controller: controller,
    focusNode: focusNode,
    obscureText: obscure,
    onFieldSubmitted: onSubmitted,
    validator: validator,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: bgField,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.purple),
      ),
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(
          obscure ? Icons.visibility : Icons.visibility_off,
          color: hintColor,
        ),
        tooltip: obscure ? 'Show' : 'Hide',
      ),
    ),
  );
}
