import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Components/Loading.dart';
import '../Service/localNotificationApi.dart';
import '../Service/otp_service.dart'; // ✅ USE RESEND DIRECTLY (no Edge Function)
import 'OtpVerification.dart';
import 'Login.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  // ----- Form + Field Keys -----
  final _formKey = GlobalKey<FormState>();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();
  final _passFieldKey = GlobalKey<FormFieldState<String>>();

  // ----- Controllers -----
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // user types AFTER +60
  final _passwordController = TextEditingController();

  // ----- Focus Nodes -----
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // ----- State -----
  bool _showPassword = true;
  bool _agree = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ---------- Validators ----------
  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your name';
    if (v.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  // User types ONLY the part after +60.
  // Accept:
  //  - 1[2-9] + 7 digits  (9 total)  => e.g. 12xxxxxxx
  //  - 11 + 8 digits     (10 total) => e.g. 11xxxxxxxx
  String? _validatePhone(String? value) {
    final v = value?.trim().replaceAll(RegExp(r'\D'), '') ?? '';
    if (v.isEmpty) return 'Please enter your phone number';
    final re = RegExp(r'^(?:1[2-9]\d{7}|11\d{8})$');
    if (!re.hasMatch(v)) return 'Enter a valid Malaysian phone number';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // 6-digit OTP (strong RNG)
  String _otp6() {
    final n = Random.secure().nextInt(1000000);
    return n.toString().padLeft(6, '0');
  }

  // ---------- Submit ----------
  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      // Focus first invalid field
      if (_nameFieldKey.currentState?.hasError ?? false) {
        _nameFocus.requestFocus();
      } else if (_emailFieldKey.currentState?.hasError ?? false) {
        _emailFocus.requestFocus();
      } else if (_phoneFieldKey.currentState?.hasError ?? false) {
        _phoneFocus.requestFocus();
      } else if (_passFieldKey.currentState?.hasError ?? false) {
        _passwordFocus.requestFocus();
      }
      return;
    }

    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions')),
      );
      return;
    }

    LoadingOverlay.show(context, message: 'Processing...');

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final fullPhone = '+60$phoneDigits';

    debugPrint('Name: $name, Email: $email, Phone: $fullPhone');

    final success = await startRegister(
      name: name,
      email: email,
      phone: fullPhone,
      password: password,
    );

    LoadingOverlay.hide(context);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration started! Please verify the OTP sent to your email.')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OtpVerification()));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    }
  }

  // ---------- Start Register (NO Edge Function, uses Resend directly) ----------
  Future<bool> startRegister({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final supa = Supabase.instance.client;

      // 1) Look up existing by email OR phone (✅ QUOTED values to avoid PostgREST parse errors)
      final existing = await supa
          .from('phone_to_email')
          .select()
          .or('email.eq."${email.trim()}",phone.eq."${phone.trim()}"')
          .maybeSingle();

      if (existing != null) {
        final bool isVerified = (existing['is_verified'] as bool?) ?? false;
        if (isVerified) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account already registered. Please sign in. If not, contact support.')),
            );
          }
          return false;
        }
        // Not verified yet → reuse row
      } else {
        // 2) No record → insert pending row
        await supa.from('phone_to_email').insert({
          'phone': phone.trim(),
          'email': email.trim(),
          'is_verified': false,
        });
      }

      // 3) Save pending info locally (avoid storing plaintext pw in prod)
      const secure = FlutterSecureStorage();
      await secure.write(key: 'pending_name', value: name.trim());
      await secure.write(key: 'pending_email', value: email.trim());
      await secure.write(key: 'pending_phone', value: phone.trim());
      await secure.write(key: 'pending_password', value: password);

      // 4) Generate OTP & upsert to user_otps (5-min expiry)
      final otp = _otp6();
      final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 5));
      await secure.write(key: 'pending_otp', value: otp);

      await supa.from('user_otps').upsert(
        {
          'email': email.trim(),
          'otp': otp,
          'expires_at': expiresAt.toIso8601String(),
        },
        onConflict: 'email',
      );

      // 5) Send OTP via Resend (✅ no JWT needed)
      final hh = expiresAt.toLocal().hour.toString().padLeft(2, '0');
      final mm = expiresAt.toLocal().minute.toString().padLeft(2, '0');
      // await OtpService.sendEmail(
      //   to: email.trim(),
      //   subject: 'Your OTP Code',
      //   text: 'Hello $name,\n\nUse this OTP: $otp\nIt expires at $hh:$mm.',
      // );

      // (optional) local notification for dev
      NotificationsApi.showNotification(
        title: 'Your OTP Code',
        body: 'Use $otp to verify your account. It expires in 5 minutes.',
      );

      return true;
    } catch (e) {
      debugPrint('startRegister error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            margin: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: Container(
                    width: 90,
                    height: 80,
                    color: Colors.white,
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "HELP 4U",
                  style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold,
                    color: Colors.white, fontFamily: 'Poppins', letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Always Ready To Help You",
                  style: TextStyle(
                    fontSize: 15, color: Colors.grey,
                    fontFamily: 'Poppins', letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: () async {
                    await NotificationsApi.showNotification(
                      title: 'Test',
                      body: 'If you see this, local notifications are OK.',
                    );
                  },
                  child: const Text('Test Notification'),
                ),

                // --- SIGNUP FORM ---
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Create Account",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Join Us To Make Your Car More Perfect",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        // NAME
                        const Text("Name", style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 5),
                        TextFormField(
                          key: _nameFieldKey,
                          controller: _nameController,
                          focusNode: _nameFocus,
                          decoration: _inputDecoration("John Doe", Icons.person),
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          validator: _validateName,
                          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                        ),
                        const SizedBox(height: 20),

                        // EMAIL
                        const Text("Email", style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 5),
                        TextFormField(
                          key: _emailFieldKey,
                          controller: _emailController,
                          focusNode: _emailFocus,
                          decoration: _inputDecoration("example@email.com", Icons.email),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                        ),
                        const SizedBox(height: 20),

                        // PHONE
                        const Text("Phone No", style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 5),
                        TextFormField(
                          key: _phoneFieldKey,
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          decoration: _inputDecoration("128082165", Icons.phone)
                              .copyWith(prefixText: "+60 ", prefixStyle: const TextStyle(color: Colors.white, fontSize: 16)),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10), // 011 case has 10
                          ],
                          textInputAction: TextInputAction.next,
                          validator: _validatePhone,
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 20),

                        // PASSWORD
                        const Text("Password", style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 5),
                        TextFormField(
                          key: _passFieldKey,
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _showPassword,
                          decoration: _inputDecoration("Enter Your Password", Icons.lock).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 15),

                        // Terms
                        Row(
                          children: [
                            Checkbox(
                              value: _agree,
                              onChanged: (v) => setState(() => _agree = v ?? false),
                              activeColor: const Color(0xFF9B5DE5),
                            ),
                            const Text("I agree to the "),
                            const Text(
                              "Terms & Conditions",
                              style: TextStyle(
                                color: Color(0xFF9B5DE5),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // SUBMIT BUTTON
                        Center(
                          child: Container(
                            width: 250,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?",
                      style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins', letterSpacing: 0.5),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Login())),
                      child: const Text("Sign In Now",
                        style: TextStyle(
                          color: Color(0xFF9B5DE5), fontSize: 14, fontFamily: 'Poppins',
                          letterSpacing: 0.5, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text("@2025 Workshop App. All rights reserved.", style: TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable input decoration
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      prefixIcon: Icon(icon, color: Colors.white),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey, fontFamily: 'Poppins', letterSpacing: 0.5, fontSize: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF9B5DE5), width: 2),
      ),
    );
  }
}
