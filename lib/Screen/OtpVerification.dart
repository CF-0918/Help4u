import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workshop_assignment/Repository/user_repo.dart';
import 'package:workshop_assignment/authencation/auth_service.dart';

import '../Models/UserProfile.dart';
import '../Service/localNotificationApi.dart';
import 'Home.dart';

class OtpVerification extends StatefulWidget {
  const OtpVerification({super.key});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final _formKey = GlobalKey<FormState>();
  final _pinCtrl = TextEditingController();
  final _pinFocus = FocusNode();
  final _storage = const FlutterSecureStorage();
  final _supa = Supabase.instance.client;

  bool _verifying = false;
  bool _resending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  // pending data saved during startRegister()
  String? _name, _email, _phone, _password;
  DateTime? _expiresAt; // from DB (for UI)

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pinCtrl.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    final name = await _storage.read(key: 'pending_name');
    final email = await _storage.read(key: 'pending_email');
    final phone = await _storage.read(key: 'pending_phone');
    final password = await _storage.read(key: 'pending_password');

    setState(() {
      _name = name;
      _email = email;
      _phone = phone;
      _password = password;
    });

    if (_email != null) {
      // fetch current expiry to show user
      final row = await _supa
          .from('user_otps')
          .select()
          .eq('email', _email!)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() => _expiresAt = DateTime.parse(row['expires_at']).toUtc());
      }
    }
  }

  String _fmtExpiry(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _submit() async {
    if (_verifying) return;
    final code = _pinCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code')),
      );
      return;
    }
    if (_email == null || _password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing pending data. Please register again.')),
      );
      return;
    }

    setState(() => _verifying = true);
    try {
      // 1) Get OTP row
      final row = await _supa
          .from('user_otps')
          .select()
          .eq('email', _email!)
          .maybeSingle();

      if (row == null) {
        throw 'No OTP found for this email. Please resend.';
      }

      final dbOtp = row['otp'] as String;
      final expiresAt = DateTime.parse(row['expires_at']).toUtc();
      setState(() => _expiresAt = expiresAt);

      if (DateTime.now().toUtc().isAfter(expiresAt)) {
        throw 'Code expired. Please resend a new code.';
      }
      if (dbOtp != code) {
        throw 'Incorrect code. Please try again.';
      }

      // 2) Mark phone_to_email as verified
      await _supa
          .from('phone_to_email')
          .update({'is_verified': true})
          .or('email.eq.${_email!},phone.eq.${_phone ?? ''}');

      // 3) Create/sign-in Supabase Auth user
      try {
        await _supa.auth.signUp(email: _email!, password: _password!);
      } on AuthException catch (e) {
        if (e.code == 'user_already_exists') {
          await _supa.auth.signInWithPassword(email: _email!, password: _password!);
        } else {
          rethrow;
        }
      }

      final auth_user = _supa.auth.currentUser;
      if (auth_user == null) throw 'Auth not established. Please try again.';

      // 4) Upsert profile (id must match auth.uid())
      final repo = UserRepository();
      await repo.insertUser(
        user: UserProfile(
          uid: auth_user.id,
          name: _name ?? '',
          email: _email!,
          phone: _phone ?? '',
          isVerified: true,
          status: 'active',
        ),
      );


      // 5) Clean up OTP + local storage
      await _supa.from('user_otps').delete().eq('email', _email!);
      await _storage.delete(key: 'pending_name');
      await _storage.delete(key: 'pending_email');
      await _storage.delete(key: 'pending_phone');
      await _storage.delete(key: 'pending_password');
      await _storage.delete(key: 'pending_otp');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome, ${_name ?? 'User'}!')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Home()),
            (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resending || _resendCooldown > 0) return;
    if (_email == null) return;

    setState(() {
      _resending = true;
      _resendCooldown = 30;
    });

    // start cooldown timer
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });

    try {
      final otp = _otp6();
      final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 5));

      // overwrite OTP for this email
      await _supa.from('user_otps').upsert({
        'email': _email!.trim(),
        'otp': otp,
        'expires_at': expiresAt.toIso8601String(),
      }, onConflict: 'email');

      NotificationsApi.showNotification(
        title: 'Your OTP Code',
        body: 'Use $otp to verify your account. Expires at ${_fmtExpiry(expiresAt.toLocal())}',
      );
      // send via edge function
      final resp = await _supa.functions.invoke(
        'rapid-action',
        body: {'to': _email, 'subject': 'Your OTP Code', 'otp': otp},
      );
      if (resp.status >= 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resend failed: ${resp.status} ${resp.data}')),
        );
        throw 'Failed to send OTP (${resp.status}): ${resp.data}';
      }

      if (mounted) {
        final localExpiry = expiresAt.toLocal();  // convert from UTC to device's timezone
        setState(() => _expiresAt = localExpiry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New code sent. Expires at ${_fmtExpiry(localExpiry)}')),
        );
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resend failed: $e')),
      );
      // stop cooldown on failure
      _cooldownTimer?.cancel();
      setState(() {
        _resendCooldown = 0;
      });
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  // simple 6-digit generator (same as your startRegister)
  String _otp6() {
    final n = (DateTime.now().microsecondsSinceEpoch % 1000000).abs();
    return n.toString().padLeft(6, '0');
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700, width: 1.2),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF9B5DE5), width: 2),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.redAccent, width: 2),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Verification",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _email == null
                    ? 'Enter the 6-digit code'
                    : 'Enter the 6-digit code sent to $_email',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (_expiresAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Code expires at ${_fmtExpiry(_expiresAt!.toLocal())}',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Pinput(
                  controller: _pinCtrl,
                  focusNode: _pinFocus,
                  length: 6,
                  autofocus: true,
                  showCursor: true,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  errorPinTheme: errorPinTheme,
                  keyboardType: TextInputType.number,
                  onCompleted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 240,
                height: 52,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    disabledBackgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _verifying
                      ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Verify",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (_resending || _resendCooldown > 0) ? null : _resendCode,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_resending)
                    const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  if (_resending) const SizedBox(width: 8),
                  Text(
                    _resendCooldown > 0 ? "Resend in ${_resendCooldown}s" : "Resend code",
                    style: const TextStyle(color: Colors.white),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
