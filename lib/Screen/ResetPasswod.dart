import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

class ResetPasswordPageFromLink extends StatefulWidget {
  const ResetPasswordPageFromLink({super.key});

  @override
  State<ResetPasswordPageFromLink> createState() => _ResetPasswordPageFromLinkState();
}

class _ResetPasswordPageFromLinkState extends State<ResetPasswordPageFromLink> {
  bool _hide1 = true;
  bool _hide2 = true;
  double _strength = 0; // 0..1

  void _onPasswordChanged(String value) {
    // tiny strength heuristic (customize as you like)
    final v = value.trim();
    int score = 0;
    if (v.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[a-z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) score++;
    _strength = (score / 5).clamp(0, 1);
    setState(() {});
  }


  final _formKey = GlobalKey<FormState>();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  bool _busy = false;

  @override
  void dispose() { _pwd.dispose(); _pwd2.dispose(); super.dispose(); }

  Future<void> _update() async {
    AuthService _authService = AuthService();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final resp = await _authService.updatePassword(password:_pwd.text.trim());

      if (resp.user == null) throw Exception('Failed to update password');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF0E0E10);
    final card = const Color(0xFF1A1A1E);
    final accent = const Color(0xFF7C4DFF);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // top app-bar style row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                    splashRadius: 22,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Forgot Password',
                    style: TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // center avatar + copy
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 88, width: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Set New Password',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create a strong password for your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // card
              Container(
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
                      // new password
                      TextFormField(
                        controller: _pwd,
                        obscureText: _hide1,
                        onChanged: _onPasswordChanged,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'New password',
                          labelStyle: TextStyle(color: Colors.white.withOpacity(.75)),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hide1 = !_hide1),
                            icon: Icon(_hide1 ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.white70),
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
                        validator: (v) => (v?.trim().length ?? 0) < 8 ? 'Minimum 8 characters' : null,
                      ),

                      const SizedBox(height: 12),

                      // strength bar
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
                              style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12)),
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

                      // confirm password
                      TextFormField(
                        controller: _pwd2,
                        obscureText: _hide2,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          labelStyle: TextStyle(color: Colors.white.withOpacity(.75)),
                          prefixIcon: const Icon(Icons.lock_reset_rounded, color: Colors.white70),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hide2 = !_hide2),
                            icon: Icon(_hide2 ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.white70),
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
                        validator: (v) =>
                        v?.trim() != _pwd.text.trim() ? 'Passwords do not match' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // gradient CTA
              SizedBox(
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
                    onPressed: _busy ? null : _update,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: _busy
                        ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Update Password'),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Use at least 8 characters including numbers & symbols.',
                  style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
