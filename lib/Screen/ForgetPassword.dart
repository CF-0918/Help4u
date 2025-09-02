import 'package:flutter/material.dart';
import '../authencation/auth_service.dart';
import '../Repository/user_repo.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();

  bool _submitting = false;
  final _authService = AuthService();
  final _userRepo = UserRepository();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Phone is required';
    // user types only digits after +60 → 9–10 digits starting with 1
    final ok = RegExp(r'^1\d{8,9}$').hasMatch(s);
    if (!ok) return 'Enter a valid Malaysian phone (e.g. 123456789)';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    try {
      // Always prepend +60 for DB lookup
      final phone = '+60${_phoneCtrl.text.trim()}';

      // 1) Find email by phone
      final email = await _userRepo.getEmailByPhone(phone);
      if (email == null || email.isEmpty) {
        throw Exception('No user found with this phone number.');
      }

      // 2) Send Supabase reset email (deep link MUST be whitelisted in Auth settings)
      await _authService.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset link sent to $email. Please check your inbox.')),
      );

      Navigator.of(context).pop(); // go back to login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF0E0E10);
    final card = const Color(0xFF1A1A1E);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back + Title
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
              const SizedBox(height: 20),

              // Icon + intro text
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 88, width: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Reset your password',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your phone number and we’ll send you a reset link via email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form card
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
                  child: TextFormField(
                    controller: _phoneCtrl,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(.75)),
                      hintText: '123456789',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(.4)),
                      prefixText: '+60 ',
                      prefixIcon: const Icon(Icons.phone, color: Colors.white70),
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
                    validator: _validatePhone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
              ),

              const Spacer(),

              // Gradient button
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
                        color: const Color(0xFF7C4DFF).withOpacity(.45),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: _submitting
                        ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Send Reset Link'),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  'We’ll send a reset link to the email linked to your phone number.',
                  style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
