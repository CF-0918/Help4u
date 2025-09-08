import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Screen/Login.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

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

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  bool _busy = false;

  // === same strength logic as reset screen ===
  double _strength = 0; // 0..1
  void _onPasswordChanged(String value) {
    final v = value.trim();
    int score = 0;
    if (v.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[a-z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) score++;
    setState(() => _strength = (score / 5).clamp(0, 1));
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

  Future<void> _submit() async {
    // unify validation with reset screen
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = AuthService();
    final email = auth.currentUserEmail;
    final currentPw = _currentCtrl.text.trim();
    final newPw = _newCtrl.text.trim();

    if (email == null || email.isEmpty) {
      _showSnack('Error: No user logged in.');
      return;
    }

    // new must be different from current (extra rule for change flow)
    if (currentPw == newPw) {
      _showSnack('New password must be different from your current password.');
      return;
    }

    // loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1) re-authenticate with current password
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: currentPw);

      // 2) update password
      final res = await auth.updatePassword(password: newPw);
      if (res.user == null) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnack('Failed to update password. Please try again.');
        return;
      }

      await auth.logOut();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack('Password updated. Please log in again.');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
            (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final msg = e.message.toLowerCase().contains('invalid login credentials')
          ? 'Current password is incorrect.'
          : e.message;
      _showSnack(msg);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnack('Unexpected error: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0E0E10);
    const card = Color(0xFF1A1A1E);
    const accent = Color(0xFF7C4DFF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Change Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.35),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // current password
                  _pwField(
                    label: 'Current Password',
                    controller: _currentCtrl,
                    focusNode: _currentFocus,
                    obscure: _hideCurrent,
                    onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_newFocus),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  // new password (same validators/strength as reset)
                  _pwField(
                    label: 'New Password',
                    controller: _newCtrl,
                    focusNode: _newFocus,
                    obscure: _hideNew,
                    onToggle: () => setState(() => _hideNew = !_hideNew),
                    onChanged: _onPasswordChanged,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_confirmFocus),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Minimum 8 characters';
                      if (t.length < 8) return 'Minimum 8 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),
                  // strength bar (identical look/logic)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _strength,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(.08),
                      color: _strength < .4
                          ? Colors.redAccent
                          : _strength < .7
                          ? Colors.amber
                          : Colors.lightGreenAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Password strength',
                          style: TextStyle(
                              color: Colors.white.withOpacity(.6), fontSize: 12)),
                      Text(
                        _strength < .4 ? 'Weak' : _strength < .7 ? 'Okay' : 'Strong',
                        style: TextStyle(
                          color: _strength < .4
                              ? Colors.redAccent
                              : _strength < .7
                              ? Colors.amber
                              : Colors.lightGreenAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // confirm new password (same as reset)
                  _pwField(
                    label: 'Confirm New Password',
                    controller: _confirmCtrl,
                    focusNode: _confirmFocus,
                    obscure: _hideConfirm,
                    onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                    onSubmitted: (_) => _submit(),
                    validator: (v) =>
                    v?.trim() != _newCtrl.text.trim() ? 'Passwords do not match' : null,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF9B6BFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(.45),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        child: _busy
                            ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Update Password'),
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

// --- shared styled field (same visual as reset) ---
Widget _pwField({
  required String label,
  required TextEditingController controller,
  required FocusNode focusNode,
  required bool obscure,
  required VoidCallback onToggle,
  String? Function(String?)? validator,
  ValueChanged<String>? onSubmitted,
  ValueChanged<String>? onChanged,
}) {
  return TextFormField(
    controller: controller,
    focusNode: focusNode,
    obscureText: obscure,
    onFieldSubmitted: onSubmitted,
    onChanged: onChanged,
    validator: validator,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(.75)),
      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          color: Colors.white70,
        ),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(.04),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.6),
      ),
    ),
  );
}
